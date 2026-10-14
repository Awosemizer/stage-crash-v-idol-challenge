extends Node2D
## Caída periódica (v0.61): carámbanos glitch (Glitch Ice) o escombro del subwoofer
## (Bassquake). Una sombra en el suelo avisa ~0.6 s antes; el proyectil cae recto
## desde `top_y` hasta `floor_y` y se rompe. Daña al tocar.

@export var period := 2.4
@export var phase_offset := 0.0
@export var top_y := 24.0
@export var floor_y := 176.0
@export var damage := 2
@export var texture_path := "res://assets/sprites/fx/ice_glitch.png"
@export var tint := Color.WHITE
const WARN := 0.6
const FALL_SPEED := 260.0

var _t := 0.0
var _shadow: ColorRect
var _drop: Area2D = null
var _dropped := false


func _ready() -> void:
	_t = phase_offset
	_shadow = ColorRect.new()
	_shadow.size = Vector2(14, 3)
	_shadow.position = Vector2(-7, floor_y - position.y - 3)
	_shadow.color = Color(0, 0, 0, 0)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shadow)


func _physics_process(delta: float) -> void:
	_t += delta
	var c := fmod(_t, period)
	var warn := c > period - WARN
	_shadow.color = Color(tint.r * 0.6, tint.g * 0.6, tint.b * 0.6, 0.55 * (c - (period - WARN)) / WARN) if warn else Color(0, 0, 0, 0)
	if c < delta * 1.5 and _drop == null:
		_spawn()
	if _drop:
		_drop.position.y += FALL_SPEED * delta
		if _drop.position.y >= floor_y - position.y - 6:
			_drop.queue_free()
			_drop = null


func _spawn() -> void:
	_drop = Area2D.new()
	_drop.collision_layer = 4
	_drop.collision_mask = 2
	_drop.add_to_group("hazards")
	var shp := RectangleShape2D.new()
	shp.size = Vector2(10, 12)
	var col := CollisionShape2D.new()
	col.shape = shp
	_drop.add_child(col)
	var s := Sprite2D.new()
	s.texture = load(texture_path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# v0.63: icicle/debris tienen color propio (sin rotar, apenas teñidos)
	s.modulate = Color.WHITE.lerp(tint, 0.2)
	_drop.add_child(s)
	_drop.position = Vector2(0, top_y - position.y)
	_drop.body_entered.connect(_on_hit)
	add_child(_drop)


func _on_hit(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
