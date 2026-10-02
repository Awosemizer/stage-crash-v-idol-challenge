extends AnimatableBody2D
## Plataforma enredadera — oscila A↔B (invernadero Chorus Bloom).
## Growing stub: pulso de escala visual suave.

@export var move_period := 2.4
@export var phase_offset := 0.0
@export var size := Vector2(48, 12)

var pos_a := Vector2.ZERO
var pos_b := Vector2.ZERO
var _t := 0.0
var _col: CollisionShape2D = null
var _visual: ColorRect = null
var _edge: ColorRect = null
var _leaf: ColorRect = null

const COL_VINE := Color(0.25, 0.72, 0.38, 0.95)
const COL_LEAF := Color(0.55, 0.9, 0.45, 0.85)


func _ready() -> void:
	add_to_group("vine_platforms")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	pos_a = position
	if pos_b == Vector2.ZERO:
		pos_b = pos_a + Vector2(64, 0)
	_t = phase_offset
	_ensure_visuals()
	_refresh_look()


func configure(a: Vector2, b: Vector2, platform_size: Vector2 = Vector2(48, 12), period: float = 2.4, phase: float = 0.0) -> void:
	pos_a = a
	pos_b = b
	size = platform_size
	move_period = period
	phase_offset = phase
	_t = phase
	position = a
	_ensure_visuals()
	_refresh_look()


func _ensure_visuals() -> void:
	_col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _col == null:
		_col = CollisionShape2D.new()
		_col.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = size
		_col.shape = shape
		add_child(_col)
	elif _col.shape is RectangleShape2D:
		(_col.shape as RectangleShape2D).size = size

	_visual = get_node_or_null("Visual") as ColorRect
	if _visual == null:
		_visual = ColorRect.new()
		_visual.name = "Visual"
		add_child(_visual)
	_visual.size = size
	_visual.position = -size * 0.5
	_visual.color = COL_VINE

	_edge = get_node_or_null("Edge") as ColorRect
	if _edge == null:
		_edge = ColorRect.new()
		_edge.name = "Edge"
		add_child(_edge)
	_edge.size = Vector2(size.x, 2)
	_edge.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	_edge.color = COL_VINE.lightened(0.35)

	_leaf = get_node_or_null("Leaf") as ColorRect
	if _leaf == null:
		_leaf = ColorRect.new()
		_leaf.name = "Leaf"
		add_child(_leaf)
	_leaf.size = Vector2(8, 6)
	_leaf.position = Vector2(-4, -size.y * 0.5 - 6)
	_leaf.color = COL_LEAF


func _physics_process(delta: float) -> void:
	_t += delta
	var period := maxf(move_period, 0.2)
	# Smooth sine A↔B (grow/retract feel)
	var u := (sin((_t / period) * TAU - PI * 0.5) + 1.0) * 0.5
	position = pos_a.lerp(pos_b, u)
	_refresh_look()


func _refresh_look() -> void:
	if _visual == null:
		return
	var pulse := 0.92 + 0.08 * absf(sin(_t * 3.0))
	_visual.color = Color(COL_VINE.r * pulse, COL_VINE.g, COL_VINE.b * pulse, 0.95)
	if _leaf:
		_leaf.position.y = -size.y * 0.5 - 6.0 + sin(_t * 4.0) * 1.5
		_leaf.color.a = 0.7 + 0.25 * absf(sin(_t * 5.0))
