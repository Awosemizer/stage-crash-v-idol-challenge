extends Area2D
## Speaker Drone (v0.61) — bocina voladora que flota en seno y patrulla un tramo corto.
## HP 1. Solo daña por contacto. Arte provisional: Met-Beat cerrado teñido (falta hoja propia).

const HP_MAX := 1
const CONTACT_DAMAGE := 2
const AMP := 10.0
const PATROL := 40.0
const SPEED := 0.9

var hp := HP_MAX
var tint := Color(0.55, 0.95, 1.0)
var _t := 0.0
var _home := Vector2.ZERO
var _flash := 0.0
var _alive := true
var _vis: Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = true
	_home = position
	_t = fmod(position.x * 0.013, TAU)
	var shp := RectangleShape2D.new()
	shp.size = Vector2(14, 10)
	var col := CollisionShape2D.new()
	col.shape = shp
	add_child(col)
	_vis = Sprite2D.new()
	_vis.texture = load("res://assets/sprites/enemies/met_closed.png")
	_vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vis.scale = Vector2(0.8, 0.6)
	_vis.flip_v = true  # cúpula hacia abajo: lee como bocina colgante
	add_child(_vis)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_t += delta * SPEED
	position = _home + Vector2(sin(_t * 0.5) * PATROL, sin(_t * 2.0) * AMP)
	_flash = maxf(_flash - delta, 0.0)
	_vis.modulate = Color(2, 2, 2) if _flash > 0.0 else tint
	_vis.flip_h = cos(_t * 0.5) < 0.0


func take_damage(amount: int) -> bool:
	if not _alive:
		return false
	hp -= amount
	_flash = 0.12
	if AudioManager:
		AudioManager.play_sfx("hit")
	if hp <= 0:
		_alive = false
		queue_free()
	return true


func _on_body_entered(body: Node) -> void:
	if not _alive or body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)
