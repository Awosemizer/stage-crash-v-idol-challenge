extends Area2D
## Proyectil glitch/hielo del jefe Glitch Ice. Daño 2; parpadeo de frame.

const SPEED := 120.0
const DAMAGE := 2
const SIZE := Vector2(10, 8)
const COLOR := Color(0.55, 0.9, 1.0, 1.0)
const LIFETIME := 2.8
const GLITCH_AMP := 18.0

var damage := DAMAGE
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0
var _base_y := 0.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, spd: float = SPEED) -> void:
	var d := dir.normalized()
	if d.length_squared() < 0.01:
		d = Vector2.LEFT
	velocity = d * spd
	if is_node_ready():
		_base_y = global_position.y
		_apply_look()
	else:
		ready.connect(func () -> void:
			_base_y = global_position.y
			_apply_look()
		, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("enemy_shots")
	body_entered.connect(_on_body_entered)
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
	position += velocity * delta
	# Frame-skip stutter: occasional vertical snaps
	if int(_t * 12.0) % 5 == 0:
		global_position.y = _base_y + (1.0 if int(_t * 20.0) % 2 == 0 else -1.0) * GLITCH_AMP
	else:
		global_position.y = move_toward(global_position.y, _base_y, 80.0 * delta)
	if visual:
		visual.color = COLOR if int(Time.get_ticks_msec() / 50) % 2 == 0 else Color(0.95, 0.55, 1.0, 0.85)
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player"):
		if body.has_method("is_invulnerable") and body.is_invulnerable():
			queue_free()
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	if body is StaticBody2D:
		queue_free()
