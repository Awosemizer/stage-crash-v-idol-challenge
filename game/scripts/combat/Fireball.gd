extends Area2D
## Bola de fuego del jefe Beatfire Man.

const SPEED := 140.0
const DAMAGE := 2
const SIZE := Vector2(8, 8)
const COLOR := Color(1.0, 0.35, 0.08, 1.0)
const LIFETIME := 2.2

var damage := DAMAGE
var velocity := Vector2.ZERO
var _life := LIFETIME
var _arm := 0.08  # don't hit the frame they spawn inside the boss/player

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, spd: float = SPEED) -> void:
	var d := dir.normalized()
	if d.length_squared() < 0.01:
		d = Vector2.LEFT
	velocity = d * spd
	if is_node_ready():
		_apply_look()
	else:
		ready.connect(_apply_look, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("enemy_shots")
	body_entered.connect(_on_body_entered)
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
	_arm = maxf(_arm - delta, 0.0)
	position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player"):
		if _arm > 0.0:
			return
		if body.has_method("try_block_projectile") and body.try_block_projectile(self):
			queue_free()
			return
		if body.has_method("is_invulnerable") and body.is_invulnerable():
			queue_free()
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	if body is StaticBody2D:
		queue_free()
