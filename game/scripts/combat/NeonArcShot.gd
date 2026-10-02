extends Area2D
## Neon Arc — arco eléctrico amarillo (daño 2). Arma de Neon Volt.
## Stub: ligera curva / salto vertical corto.

const SPEED := 210.0
const DAMAGE := 2
const SIZE := Vector2(10, 6)
const COLOR := Color(0.95, 0.9, 0.2, 1.0)
const LIFETIME := 1.8
const ARC_AMP := 28.0

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0
var _base_y := 0.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
	velocity = Vector2(float(direction) * SPEED, 0.0)
	if is_node_ready():
		_base_y = global_position.y
		_apply_look()
	else:
		ready.connect(func () -> void:
			_base_y = global_position.y
			_apply_look()
		, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("player_shots")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_base_y = global_position.y
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
	position.x += velocity.x * delta
	# Mild arc (half-sine)
	global_position.y = _base_y - sin(clampf(_t * 3.2, 0.0, PI)) * ARC_AMP
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
			# Debilidad Glitch Ice (weak_to_neon_arc): ×3
			if target.is_in_group("weak_to_neon_arc"):
				dmg = damage * 3
			var result = target.take_damage(dmg)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false)
			if result == false:
				queue_free()
				return
		queue_free()
