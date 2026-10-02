extends Area2D
## Proyectil eléctrico en zigzag del jefe Neon Volt.

const SPEED := 130.0
const DAMAGE := 2
const SIZE := Vector2(9, 7)
const COLOR := Color(0.95, 0.95, 0.35, 1.0)
const LIFETIME := 2.6
const ZIG_AMP := 42.0
const ZIG_FREQ := 10.0

var damage := DAMAGE
var velocity := Vector2.ZERO
var _life := LIFETIME
var _arm := 0.22
var _base_y := 0.0
var _t := 0.0
var _dir_sign := -1.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: Vector2, spd: float = SPEED) -> void:
	var d := dir.normalized()
	if d.length_squared() < 0.01:
		d = Vector2.LEFT
	_dir_sign = 1.0 if d.x >= 0.0 else -1.0
	velocity = Vector2(d.x, 0.0).normalized() * spd
	if velocity.length_squared() < 0.01:
		velocity = Vector2(_dir_sign * spd, 0.0)
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
	ArtKit.skin_projectile(visual, "res://assets/sprites/fx/electric_zigzag.png")
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	var arm_was := _arm > 0.0
	_arm = maxf(_arm - delta, 0.0)
	_t += delta
	position.x += velocity.x * delta
	# Straight during the windup, then a smaller zigzag (not a full-body hitbox).
	var ramp := 0.0 if _arm > 0.0 else clampf((_t - 0.22) / 0.2, 0.0, 1.0)
	var zig := sin(_t * ZIG_FREQ) * 26.0 * ramp
	global_position.y = _base_y + zig
	if visual:
		if _arm > 0.0:
			visual.color = Color(1.0, 0.82, 0.3, 0.7)
			visual.scale = Vector2(0.65, 0.65)
		else:
			visual.scale = Vector2.ONE
			visual.color = COLOR
			visual.color.a = 0.7 + 0.3 * absf(sin(_t * 14.0))
	_life -= delta
	if arm_was and _arm <= 0.0:
		for b in get_overlapping_bodies():
			_on_body_entered(b)
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _arm > 0.0 or body == null:
		return
	if body.is_in_group("player"):
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
