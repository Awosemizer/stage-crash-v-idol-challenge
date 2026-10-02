extends Area2D
## Quake Drop — proyectil ámbar/tierra (daño 3, coste 2, ammo 14). Arma de Bassquake.
## Debilidad: weak_to_quake_drop ×3.

const SPEED := 165.0
const GRAVITY_ARC := 280.0
const DAMAGE := 3
const SIZE := Vector2(12, 8)
const COLOR := Color(0.85, 0.55, 0.2, 1.0)
const LIFETIME := 2.0

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
	velocity = Vector2(float(direction) * SPEED, -40.0)
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
	velocity.y += GRAVITY_ARC * delta
	position += velocity * delta
	if visual:
		visual.color.a = 0.7 + 0.3 * absf(sin(_t * 14.0))
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
	if (target is StaticBody2D or target is AnimatableBody2D) and not target.is_in_group("enemies"):
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			var dmg := damage
			if target.is_in_group("weak_to_quake_drop"):
				dmg = damage * 3
			var result = target.take_damage(dmg)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false, dmg > damage)
			if result == false:
				queue_free()
				return
		queue_free()
