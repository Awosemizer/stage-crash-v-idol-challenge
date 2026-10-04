extends Area2D
## Pétalo peligroso — hazard de invernadero (daño 3). Flota / cae suave.

@export var damage := 2  ## proyectil común
@export var drift_amp := 10.0
@export var fall_speed := 18.0

var _base := Vector2.ZERO
var _t := 0.0
var _active := true
var _arm := 0.25
var _prev_fall := 0.0

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
	_arm = maxf(_arm - delta, 0.0)
	position.x = _base.x + sin(_t * 2.2) * drift_amp
	var fall := fmod(_t * fall_speed, 40.0)
	if fall + 0.5 < _prev_fall:
		_arm = maxf(_arm, 0.22)
	_prev_fall = fall
	position.y = _base.y + fall
	if visual:
		visual.rotation = sin(_t * 3.0) * 0.4
		if _arm > 0.0:
			visual.color = Color(1.0, 0.85, 0.3, 0.85)
			visual.scale = Vector2(0.75, 0.75)
		else:
			visual.color = Color(0.95, 0.45, 0.75, 0.7 + 0.25 * absf(sin(_t * 5.0)))
			visual.scale = Vector2.ONE
		ArtKit.dress_hazard(visual, "res://assets/sprites/tiles/hazard_petal.png")


func _on_body_entered(body: Node) -> void:
	if _arm > 0.0 or body == null:
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
