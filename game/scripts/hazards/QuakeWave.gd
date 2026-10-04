extends Area2D
## Onda sísmica — se desplaza por el suelo y daña al jugador.
## Usada por Bassquake (stomp) y por temblores de etapa.

@export var damage := 3
@export var speed := 110.0
@export var lifetime := 1.6
@export var direction := 1

var velocity := Vector2.ZERO
var _life := 1.6
var _hurt_cd := 0.0
var _arm := 0.22  ## no hiere al aparecer

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int, spd: float = -1.0, dmg: int = -1) -> void:
	direction = 1 if dir >= 0 else -1
	if spd > 0.0:
		speed = spd
	if dmg > 0:
		damage = dmg
	velocity = Vector2(float(direction) * speed, 0.0)
	_life = lifetime
	if is_node_ready():
		_apply_look()
	else:
		ready.connect(_apply_look, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("quake_waves")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_apply_look()


func _apply_look() -> void:
	if visual:
		visual.size = Vector2(28, 10)
		visual.position = Vector2(-14, -10)
		visual.color = Color(0.75, 0.45, 0.15, 0.7)
	if collision:
		var shape := collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision.shape = shape
		shape.size = Vector2(28, 12)
		collision.position = Vector2(0, -6)
	if visual:
		ArtKit.dress_hazard(visual, "res://assets/sprites/tiles/hazard_quake.png")


func _physics_process(delta: float) -> void:
	_arm = maxf(_arm - delta, 0.0)
	_hurt_cd = maxf(_hurt_cd - delta, 0.0)
	position += velocity * delta
	_life -= delta
	if visual:
		if _arm > 0.0:
			visual.color = Color(1.0, 0.82, 0.28, 0.55)
			visual.scale = Vector2(0.7, 0.7)
		else:
			visual.scale = Vector2.ONE
			visual.color = Color(0.75, 0.45, 0.15, 0.45 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.025)))
		visual.size.x = 24.0 + 8.0 * absf(sin(Time.get_ticks_msec() * 0.02))
		visual.position.x = -visual.size.x * 0.5
		ArtKit.dress_hazard(visual, "res://assets/sprites/tiles/hazard_quake.png")
	if _life <= 0.0:
		queue_free()
		return
	if _hurt_cd <= 0.0:
		_hurt_overlaps()


func _on_body_entered(body: Node) -> void:
	_hurt(body)


func _hurt_overlaps() -> void:
	for b in get_overlapping_bodies():
		_hurt(b)


func _hurt(body: Node) -> void:
	if _arm > 0.0:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hurt_cd = 0.25
