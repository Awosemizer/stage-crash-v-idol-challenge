extends Area2D
## Corriente de viento — empuja al jugador horizontalmente (torres / Echo Wind).

@export var push_force := Vector2(70.0, 0.0)
@export var visual_tint := Color(0.45, 0.95, 0.85, 0.28)

var _bodies: Dictionary = {}  # instance_id -> Node

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	add_to_group("wind_currents")
	collision_layer = 0
	collision_mask = 2  # player
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if visual:
		visual.color = visual_tint
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _physics_process(_delta: float) -> void:
	# Pulse visual
	if visual:
		visual.color.a = 0.18 + 0.14 * absf(sin(Time.get_ticks_msec() * 0.006))
	for id in _bodies.keys():
		var body: Node = _bodies[id]
		if body == null or not is_instance_valid(body):
			_bodies.erase(id)
			continue
		if body.has_method("apply_wind"):
			body.apply_wind(push_force)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_bodies[body.get_instance_id()] = body


func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	_bodies.erase(body.get_instance_id())
