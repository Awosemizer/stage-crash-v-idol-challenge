extends Area2D
## Energy Tank — aumenta tanques recuperables en el HUD (máx 4). No es pieza de armadura.

signal collected(new_count: int)

@export var display_name_es := "Energy Tank"
@export var bob_amp := 3.0
@export var bob_speed := 3.5
@export var toast_hint_es := "Tanque de energía +1 (HUD)"

var _base_y := 0.0
var _collected := false
var _t := 0.0

@onready var visual: ColorRect = $Visual
@onready var glow: ColorRect = $Glow
@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("pickups")
	add_to_group("energy_tank_pickups")
	_base_y = position.y
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if label:
		label.text = display_name_es
	if visual:
		visual.color = Color(0.3, 0.85, 0.95, 0.95)
	if glow:
		glow.color = Color(0.4, 0.95, 1.0, 0.35)
	# Hide if already at max tanks
	var gs := _game_state()
	if gs != null and gs.has_method("get_energy_tanks"):
		if int(gs.get_energy_tanks()) >= 4:
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


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body == null or not body.is_in_group("player"):
		return
	_collect(body)


func _collect(_player: Node) -> void:
	_collected = true
	monitoring = false
	var new_count := 0
	var gs := _game_state()
	if gs != null and gs.has_method("grant_energy_tank"):
		new_count = int(gs.grant_energy_tank())
	collected.emit(new_count)
	_show_toast(new_count)
	print("EnergyTankPickup: tanques=%d" % new_count)
	queue_free()


func _show_toast(count: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 85
	layer.name = "EnergyTankToast"
	var scene := tree.current_scene
	if scene == null:
		return
	scene.add_child(layer)
	var lbl := Label.new()
	lbl.text = "¡%s obtenido!" % display_name_es
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.4, 0.95, 1.0, 1.0)
	lbl.position = Vector2(28, 40)
	lbl.size = Vector2(200, 16)
	layer.add_child(lbl)
	var sub := Label.new()
	sub.text = "%s · %d/4" % [toast_hint_es, count]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.75, 0.95, 1.0, 0.9)
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
