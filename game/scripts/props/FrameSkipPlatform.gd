extends StaticBody2D
## Plataforma "frame skip" — salta entre posiciones A/B a tempo (estudio glitch / hielo).
## Al teletransportar: flicker visual + colisión breve off (el jugador cae si estaba encima).

@export var skip_period := 1.35
@export var phase_offset := 0.0
@export var glitch_off_time := 0.08
@export var size := Vector2(48, 12)

var pos_a := Vector2.ZERO
var pos_b := Vector2.ZERO
var _t := 0.0
var _at_b := false
var _glitch_t := 0.0
var _warn := false
const SKIP_WARN := 0.28
var _col: CollisionShape2D = null
var _visual: ColorRect = null
var _glitch_lbl: Label = null
var _edge: ColorRect = null

const COL_ICE := Color(0.55, 0.85, 1.0, 0.92)
const COL_GLITCH := Color(1.0, 0.45, 0.95, 0.95)


func _ready() -> void:
	add_to_group("frame_skip_platforms")
	collision_layer = 1
	collision_mask = 0
	pos_a = position
	if pos_b == Vector2.ZERO:
		pos_b = pos_a + Vector2(64, 0)
	_t = phase_offset
	_ensure_visuals()
	_refresh_look(false)


func configure(a: Vector2, b: Vector2, platform_size: Vector2 = Vector2(48, 12), period: float = 1.35, phase: float = 0.0) -> void:
	pos_a = a
	pos_b = b
	size = platform_size
	skip_period = period
	phase_offset = phase
	_t = phase
	position = a
	_at_b = false
	_ensure_visuals()
	_refresh_look(false)


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
	_visual.color = COL_ICE

	_edge = get_node_or_null("Edge") as ColorRect
	if _edge == null:
		_edge = ColorRect.new()
		_edge.name = "Edge"
		add_child(_edge)
	_edge.size = Vector2(size.x, 2)
	_edge.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	_edge.color = COL_ICE.lightened(0.35)

	_glitch_lbl = get_node_or_null("GlitchMark") as Label
	if _glitch_lbl == null:
		_glitch_lbl = Label.new()
		_glitch_lbl.name = "GlitchMark"
		_glitch_lbl.add_theme_font_size_override("font_size", 5)
		_glitch_lbl.text = "スキップ"
		_glitch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_glitch_lbl)
	_glitch_lbl.position = Vector2(-size.x * 0.5, -size.y * 0.5 - 10)
	_glitch_lbl.size = Vector2(size.x, 10)
	_glitch_lbl.modulate = Color(0.7, 0.9, 1.0, 0.45)
	_glitch_lbl.visible = false


func _physics_process(delta: float) -> void:
	if _glitch_t > 0.0:
		_glitch_t -= delta
		_refresh_look(true)
		if _glitch_t <= 0.0 and _col:
			_col.disabled = false
		return

	_t += delta
	var lead := minf(SKIP_WARN, maxf(skip_period * 0.4, 0.12))
	var warn := _t >= skip_period - lead
	if warn != _warn:
		_warn = warn
		_refresh_look(false)
	if _t >= skip_period:
		_t = 0.0
		_warn = false
		_do_skip()


func _do_skip() -> void:
	_at_b = not _at_b
	position = pos_b if _at_b else pos_a
	_glitch_t = glitch_off_time
	if _col:
		_col.disabled = true
	_refresh_look(true)


func _refresh_look(glitching: bool) -> void:
	if _visual == null:
		return
	if glitching:
		_visual.color = COL_GLITCH if int(Time.get_ticks_msec() / 40) % 2 == 0 else Color(0.2, 1.0, 1.0, 0.4)
		if _glitch_lbl:
			_glitch_lbl.visible = true
			_glitch_lbl.modulate = Color(1.0, 0.5, 1.0, 0.9)
	elif _warn:
		var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
		_visual.color = Color(1.0, 0.78, 0.22, pulse)
		if _edge:
			_edge.color = Color(1.0, 0.9, 0.4, 1.0)
		if _glitch_lbl:
			_glitch_lbl.visible = true
			_glitch_lbl.text = "!"
			_glitch_lbl.modulate = Color(1.0, 0.85, 0.3, 0.95)
	else:
		_visual.color = COL_ICE
		if _edge:
			_edge.color = COL_ICE.lightened(0.3)
		if _glitch_lbl:
			_glitch_lbl.visible = false
			_glitch_lbl.text = "スキップ"
