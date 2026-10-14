extends Area2D
## Respiradero de fuego (Beatfire, v0.61). Late a tempo: rejilla quieta → chispas ámbar
## (aviso) → columna de fuego de `height` px. Solo daña con la columna encendida.

@export var damage := 3
@export var period := 1.8
@export var on_ratio := 0.38
@export var phase_offset := 0.0
@export var height := 40.0
const WARN := 0.35

var _t := 0.0
var _col: CollisionShape2D
var _grate: Sprite2D
var _flames: Array = []


func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_t = phase_offset
	# v0.63: arte propio — rejilla 16×6 siempre visible, columna 12×40 ×3 cuadros.
	var col_s := Sprite2D.new()
	col_s.texture = load("res://assets/sprites/hazards/fire_column.png")
	col_s.hframes = 3
	col_s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	col_s.centered = false
	col_s.offset = Vector2(-6, -40)
	col_s.scale = Vector2(1.0, height / 40.0)
	col_s.visible = false
	add_child(col_s)
	_flames.append(col_s)
	_grate = Sprite2D.new()
	_grate.texture = load("res://assets/sprites/hazards/fire_vent.png")
	_grate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_grate.position = Vector2(0, -3)
	add_child(_grate)
	var shp := RectangleShape2D.new()
	shp.size = Vector2(10, height)
	_col = CollisionShape2D.new()
	_col.shape = shp
	_col.position = Vector2(0, -height * 0.5)
	_col.disabled = true
	add_child(_col)


func _state() -> int:
	var c := fmod(_t, period)
	var on := period * on_ratio
	if c < on:
		return 2
	if c > period - WARN:
		return 1
	return 0


func _physics_process(delta: float) -> void:
	_t += delta
	var st := _state()
	_col.set_deferred("disabled", st != 2)
	var tk := Time.get_ticks_msec()
	var s: Sprite2D = _flames[0]
	if st == 2:
		s.visible = true
		s.frame = int(tk / 90) % 3
		s.scale = Vector2(1.0, height / 40.0)
		s.modulate = Color.WHITE
	elif st == 1:
		# aviso ámbar: llama baja y parpadeante
		s.visible = true
		s.frame = int(tk / 90) % 3
		s.scale = Vector2(0.6, 0.25)
		s.modulate = Color(1.2, 0.8, 0.3, 0.5 + 0.4 * absf(sin(tk * 0.04)))
	else:
		s.visible = false
	_grate.modulate = Color(1.5, 1.1, 0.7) if st >= 1 else Color.WHITE
	if st == 2:
		for b in get_overlapping_bodies():
			_hurt(b)


func _hurt(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
