extends Area2D
## Echo Gale — proyectil verde (daño 2). Stub: rebote 1 vez o delay corto.
## Munición gestionada por el Player.

const SPEED := 200.0
const DAMAGE := 2
const SIZE := Vector2(9, 7)
const COLOR := Color(0.4, 0.95, 0.7, 1.0)
const LIFETIME := 2.0
const BOUNCE_DELAY := 0.18

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _bounced := false
var _delay := BOUNCE_DELAY
var _moving := false

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
	velocity = Vector2(float(direction) * SPEED, 0.0)
	_delay = BOUNCE_DELAY
	_moving = false
	if is_node_ready():
		_apply_look()
	else:
		ready.connect(_apply_look, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("player_shots")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_apply_look()


func _apply_look() -> void:
	if visual == null or collision == null:
		return
	visual.size = SIZE
	visual.position = -SIZE * 0.5
	visual.color = COLOR if _moving else Color(COLOR.r, COLOR.g, COLOR.b, 0.55)
	ArtKit.skin_projectile(visual, "res://assets/sprites/fx/echo_gale.png")
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	# Brief delay before launching (delayed-shot stub)
	if not _moving:
		_delay -= delta
		if visual:
			visual.color.a = 0.4 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.02))
		if _delay <= 0.0:
			_moving = true
			if visual:
				visual.color = COLOR
		return
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Node) -> void:
	_try_hit(area)


func _try_hit(target: Node) -> void:
	if target == null or not _moving:
		return
	if target.is_in_group("player") or target.is_in_group("player_shots"):
		return
	if target is StaticBody2D and not target.is_in_group("enemies"):
		# Bounce once off walls
		if not _bounced:
			_bounced = true
			velocity.x = -velocity.x
			direction = -direction
			_life = maxf(_life, 0.6)
			return
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			var dmg := damage
			# Debilidad Bassquake (weak_to_echo_gale): ×3
			if target.is_in_group("weak_to_echo_gale"):
				dmg = damage * 3
			var result = target.take_damage(dmg)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false, dmg > damage)
			if result == false:
				queue_free()
				return
		queue_free()
