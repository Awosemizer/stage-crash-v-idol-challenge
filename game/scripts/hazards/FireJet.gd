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
var _grate: ColorRect
var _flames: Array = []


func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_t = phase_offset
	_grate = ColorRect.new()
	_grate.size = Vector2(16, 4)
	_grate.position = Vector2(-8, -4)
	_grate.color = Color(0.35, 0.12, 0.08)
	_grate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grate)
	var tex: Texture2D = load("res://assets/sprites/fx/fireball.png")
	var n := int(ceil(height / 12.0))
	for i in n:
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(0, -8 - i * 12)
		s.visible = false
		add_child(s)
		_flames.append(s)
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
	for i in _flames.size():
		var s: Sprite2D = _flames[i]
		if st == 2:
			s.visible = true
			s.scale = Vector2(1.0 - 0.08 * i + 0.1 * sin(tk * 0.03 + i), 1.0)
			s.modulate = Color(1, 1, 1, 1)
		elif st == 1:
			s.visible = i == 0
			s.scale = Vector2(0.5, 0.5)
			s.modulate = Color(1.2, 0.8, 0.3, 0.5 + 0.4 * absf(sin(tk * 0.04)))
		else:
			s.visible = false
	_grate.color = Color(0.95, 0.55, 0.15) if st >= 1 else Color(0.35, 0.12, 0.08)
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
