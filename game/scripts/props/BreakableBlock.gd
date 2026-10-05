extends StaticBody2D
## Soft wall / ceiling tile — se rompe con disparos del jugador (Buster / Beat Blaze / sable).
## group: breakable
## v0.50: misma baldosa que la pared. Sin grietas, sin ¿?, sin pulso.
## El blip del casco Flight es una marca de 3px, solo con la pieza equipada.

signal broken

@export var max_hp := 1
@export var block_color := Color(0.35, 0.15, 0.18, 1.0)
## v0.57: false dentro de una pared (sin línea clara que delate el sello).
@export var show_top_edge := true
## v0.57: misma variante y tinte que add_tiled_platform_visuals (columna dentro de la pared).
@export var tile_variant := 0

var hp := 1
var _alive := true
var _hint_blip: ColorRect = null

@onready var visual: ColorRect = $Visual
@onready var crack: ColorRect = $Crack
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hint: Label = get_node_or_null("Hint") as Label


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemies")  # so saber / shots that check enemies can hit
	hp = max_hp
	_build_wall_visual()
	_refresh_flight_blip()
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_signal("armor_changed"):
		if not gs.armor_changed.is_connected(_on_armor_changed):
			gs.armor_changed.connect(_on_armor_changed)


func _build_wall_visual() -> void:
	## Indistinguible de la pared: un tile de ArtKit del mismo color.
	if visual:
		visual.visible = false
	if crack:
		crack.visible = false
	if hint:
		hint.visible = false
		hint.text = ""
	var holder := Node2D.new()
	holder.name = "TileVisuals"
	holder.z_index = 0
	add_child(holder)
	move_child(holder, 0)
	var spr := ArtKit.make_tile_sprite(ArtKit.theme_from_color(block_color), tile_variant)
	spr.modulate = Color.WHITE.lerp(block_color, ArtKit.TILE_TINT)
	spr.position = Vector2.ZERO
	holder.add_child(spr)
	var edge := ColorRect.new()
	edge.name = "TopEdge"
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.size = Vector2(16, 2)
	edge.position = Vector2(-8, -8)
	edge.color = block_color.lightened(0.35)
	edge.visible = show_top_edge
	holder.add_child(edge)
	# Marca diminuta. Solo visible con el casco Flight equipado.
	_hint_blip = ColorRect.new()
	_hint_blip.name = "SecretBlip"
	_hint_blip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_blip.color = Color(0.45, 0.62, 0.68, 0.40)
	_hint_blip.position = Vector2(-1.5, -11.0)
	_hint_blip.size = Vector2(3, 3)
	_hint_blip.z_index = 2
	_hint_blip.visible = false
	add_child(_hint_blip)


func _on_armor_changed(_set_id: String = "") -> void:
	_refresh_flight_blip()


func _refresh_flight_blip() -> void:
	## Casco Stage Flight equipado → marca de 3px. Sin casco, parece pared.
	if _hint_blip == null:
		return
	var show := false
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("has_flight_head_equipped"):
		show = bool(gs.has_flight_head_equipped())
	_hint_blip.visible = show and _alive


func take_damage(amount: int) -> bool:
	if not _alive:
		return false
	hp = maxi(hp - maxi(amount, 1), 0)
	if AudioManager and hp > 0:
		AudioManager.play_sfx("hit", 0.9, -3.0)
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
	if _hint_blip:
		_hint_blip.visible = false
	queue_free()
