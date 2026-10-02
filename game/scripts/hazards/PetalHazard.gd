extends Area2D
## Pétalo peligroso — hazard de invernadero (daño 3). Flota / cae suave.

@export var damage := 3
@export var drift_amp := 10.0
@export var fall_speed := 18.0

var _base := Vector2.ZERO
var _t := 0.0
var _active := true

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("petal_hazards")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_base = position
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if visual:
		visual.color = Color(0.95, 0.45, 0.75, 0.9)


func configure(pos: Vector2) -> void:
	position = pos
	_base = pos


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	position.x = _base.x + sin(_t * 2.2) * drift_amp
	position.y = _base.y + fmod(_t * fall_speed, 40.0)
	if visual:
		visual.rotation = sin(_t * 3.0) * 0.4
		visual.color.a = 0.7 + 0.25 * absf(sin(_t * 5.0))


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
