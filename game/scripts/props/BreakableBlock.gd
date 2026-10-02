extends StaticBody2D
## Soft wall / ceiling tile — se rompe con disparos del jugador (Buster / Beat Blaze / sable).
## group: breakable
## v0.28: look más claro (grietas + pulso) y blip de mapa si tienes casco Flight.

signal broken

@export var max_hp := 1
@export var block_color := Color(0.72, 0.38, 0.22, 1.0)

var hp := 1
var _alive := true
var _pulse_t := 0.0
var _hint_blip: ColorRect = null
var _crack_a: ColorRect = null
var _crack_b: ColorRect = null
var _outline: ColorRect = null

@onready var visual: ColorRect = $Visual
@onready var crack: ColorRect = $Crack
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hint: Label = get_node_or_null("Hint") as Label


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemies")  # so saber / shots that check enemies can hit
	hp = max_hp
	_build_clear_visual()
	_refresh_flight_blip()
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_signal("armor_changed"):
		if not gs.armor_changed.is_connected(_on_armor_changed):
			gs.armor_changed.connect(_on_armor_changed)


func _process(delta: float) -> void:
	if not _alive:
		return
	_pulse_t += delta
	var pulse := 0.55 + 0.45 * absf(sin(_pulse_t * 3.2))
	if _outline:
		_outline.color.a = 0.35 + 0.45 * pulse
	if hint:
		hint.modulate.a = 0.45 + 0.4 * pulse
	if _hint_blip and _hint_blip.visible:
		_hint_blip.modulate.a = 0.5 + 0.5 * pulse
		_hint_blip.scale = Vector2.ONE * (0.85 + 0.2 * pulse)


func _build_clear_visual() -> void:
	## Distinct from solid tiles: warmer fill, outline, X-cracks, ? tip.
	if visual:
		visual.visible = true
		visual.color = block_color
		visual.z_index = 0
	# Hide generic tile sprite look — keep flat readable soft-block
	for c in get_children():
		if c is Sprite2D and str(c.name).begins_with("SpriteArt"):
			c.queue_free()
	# Outline (slightly larger, behind Visual)
	_outline = ColorRect.new()
	_outline.name = "Outline"
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.color = Color(1.0, 0.85, 0.35, 0.7)
	_outline.position = Vector2(-9, -9)
	_outline.size = Vector2(18, 18)
	_outline.z_index = -1
	add_child(_outline)
	move_child(_outline, 0)
	# Permanent crack marks (X)
	_crack_a = ColorRect.new()
	_crack_a.name = "CrackA"
	_crack_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crack_a.color = Color(1.0, 0.92, 0.55, 0.85)
	_crack_a.position = Vector2(-6, -1)
	_crack_a.size = Vector2(12, 2)
	_crack_a.rotation = 0.7
	_crack_a.z_index = 2
	add_child(_crack_a)
	_crack_b = ColorRect.new()
	_crack_b.name = "CrackB"
	_crack_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crack_b.color = Color(1.0, 0.92, 0.55, 0.85)
	_crack_b.position = Vector2(-6, -1)
	_crack_b.size = Vector2(12, 2)
	_crack_b.rotation = -0.7
	_crack_b.z_index = 2
	add_child(_crack_b)
	if crack:
		crack.visible = false
	if hint:
		hint.text = "¿?"
		hint.modulate = Color(1.0, 0.8, 0.4, 0.85)
		hint.z_index = 3
	# Map-style blip above block (shown when Flight helmet owned)
	_hint_blip = ColorRect.new()
	_hint_blip.name = "SecretBlip"
	_hint_blip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_blip.color = Color(0.35, 0.9, 1.0, 0.9)
	_hint_blip.position = Vector2(-3, -22)
	_hint_blip.size = Vector2(6, 6)
	_hint_blip.z_index = 4
	_hint_blip.visible = false
	add_child(_hint_blip)


func _on_armor_changed(_set_id: String = "") -> void:
	_refresh_flight_blip()


func _refresh_flight_blip() -> void:
	## Casco Stage Flight → blip cian sobre bloques rompibles (secreto en mapa in-level).
	if _hint_blip == null:
		return
	var show := false
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null:
		if gs.has_method("has_flight_head_equipped"):
			show = bool(gs.has_flight_head_equipped())
		elif gs.has_method("has_armor_piece"):
			show = bool(gs.has_armor_piece("flight", "head"))
	_hint_blip.visible = show and _alive


func take_damage(amount: int) -> bool:
	if not _alive:
		return false
	hp = maxi(hp - maxi(amount, 1), 0)
	if AudioManager and hp > 0:
		AudioManager.play_sfx("hit", 0.9, -3.0)
	if crack:
		crack.visible = true
		crack.color = Color(1.0, 0.95, 0.6, 0.75)
	if _outline:
		_outline.color = Color(1.0, 1.0, 0.6, 1.0)
	if hp <= 0:
		_break()
		return true
	return true


func _break() -> void:
	if not _alive:
		return
	_alive = false
	broken.emit()
	if AudioManager:
		AudioManager.play_sfx("explosion", 1.15, -6.0)
	print("BreakableBlock: roto en ", global_position)
	if collision:
		collision.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	if visual:
		visual.color = Color(block_color.r, block_color.g, block_color.b, 0.25)
	if _hint_blip:
		_hint_blip.visible = false
	queue_free()
