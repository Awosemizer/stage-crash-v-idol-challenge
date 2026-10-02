extends Area2D
## Freeze Sample — proyectil cian (daño 2). Arma de Glitch Ice.
## Debilidad: weak_to_freeze_sample ×3 (Beatfire opcional).

const SPEED := 195.0
const DAMAGE := 2
const SIZE := Vector2(11, 6)
const COLOR := Color(0.55, 0.92, 1.0, 1.0)
const LIFETIME := 1.9

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
	velocity = Vector2(float(direction) * SPEED, 0.0)
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
	visual.color = COLOR
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	_t += delta
	position += velocity * delta
	# Soft "sample freeze" shimmer
	if visual:
		visual.color.a = 0.75 + 0.25 * absf(sin(_t * 18.0))
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Node) -> void:
	_try_hit(area)


func _try_hit(target: Node) -> void:
	if target == null:
		return
	if target.is_in_group("player") or target.is_in_group("player_shots"):
		return
	if target is StaticBody2D and not target.is_in_group("enemies"):
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			var dmg := damage
			if target.is_in_group("weak_to_freeze_sample"):
				dmg = damage * 3
			var result = target.take_damage(dmg)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false, dmg > damage)
			if result == false:
				queue_free()
				return
		queue_free()
