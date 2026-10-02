extends Area2D
## Pickup de pieza de armadura. Texto en español. Auto-equip en proto vía GameState.

signal collected(set_id: String, piece_id: String)

@export var armor_set := "flight"
@export var armor_piece := "torso"
@export var display_name_es := "Torso Stage Flight"
@export var bob_amp := 3.0
@export var bob_speed := 3.5
@export var toast_hint_es := "Mantén Saltar en el aire → hover"

var _base_y := 0.0
var _collected := false
var _t := 0.0

@onready var visual: ColorRect = $Visual
@onready var glow: ColorRect = $Glow
@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("pickups")
	add_to_group("armor_pickups")
	_base_y = position.y
	collision_layer = 0
	collision_mask = 2  # player
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_refresh_label()
	# Hide if already owned (replay / validate re-entry)
	var gs := _game_state()
	if gs != null and gs.has_method("has_armor_piece"):
		if gs.has_armor_piece(armor_set, armor_piece):
			visible = false
			monitoring = false
			_collected = true


func _physics_process(delta: float) -> void:
	if _collected:
		return
	_t += delta
	position.y = _base_y + sin(_t * bob_speed) * bob_amp
	if glow:
		glow.color.a = 0.25 + 0.2 * absf(sin(_t * 5.0))


func _refresh_label() -> void:
	if label:
		label.text = display_name_es


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body == null or not body.is_in_group("player"):
		return
	_collect(body)


func _collect(player: Node) -> void:
	_collected = true
	monitoring = false
	var gs := _game_state()
	if gs != null and gs.has_method("grant_armor_piece"):
		gs.grant_armor_piece(armor_set, armor_piece, true)
	# Notify player for immediate hover enable + banner
	if player.has_method("on_armor_pickup"):
		player.on_armor_pickup(armor_set, armor_piece, display_name_es)
	collected.emit(armor_set, armor_piece)
	_show_toast()
	print("ArmorPickup: %s (%s/%s)" % [display_name_es, armor_set, armor_piece])
	queue_free()


func _show_toast() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 85
	layer.name = "ArmorToast"
	var scene := tree.current_scene
	if scene == null:
		return
	scene.add_child(layer)
	var lbl := Label.new()
	lbl.text = "¡%s obtenido!" % display_name_es
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.45, 0.95, 1.0, 1.0)
	lbl.position = Vector2(28, 40)
	lbl.size = Vector2(200, 16)
	layer.add_child(lbl)
	var sub := Label.new()
	sub.text = toast_hint_es
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.75, 0.9, 1.0, 0.9)
	sub.position = Vector2(28, 56)
	sub.size = Vector2(200, 14)
	layer.add_child(sub)
	tree.create_timer(2.8).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _game_state() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")
