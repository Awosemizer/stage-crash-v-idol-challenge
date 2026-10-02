extends Node2D
## Beatfire-style vertical slice — teaches run, jump, wall-jump, slide, buster.
## Placeholder geometry (ColorRects). Stadium-on-fire palette.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")

const COL_FLOOR := Color(0.55, 0.25, 0.22, 1.0)
const COL_WALL := Color(0.35, 0.15, 0.18, 1.0)
const COL_ACCENT := Color(0.9, 0.45, 0.15, 1.0)
const COL_BG := Color(0.12, 0.06, 0.1, 1.0)

@onready var geometry: Node2D = $Geometry
@onready var hazards: Node2D = $Hazards
@onready var entities: Node2D = $Entities
@onready var bg: ColorRect = $ParallaxBG/BG


func _ready() -> void:
	bg.color = COL_BG
	_build_course()
	_spawn_enemies()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	# [x, y, w, h, color] — top-left of rect in world px (16px grid feel)
	var solids: Array = [
		[0, 176, 160, 48, COL_FLOOR],
		[176, 160, 48, 16, COL_FLOOR],
		[240, 144, 48, 16, COL_FLOOR],
		[336, 160, 80, 64, COL_FLOOR],
		# Wall-jump corridor
		[448, 48, 16, 160, COL_WALL],
		[528, 48, 16, 160, COL_WALL],
		[448, 192, 96, 32, COL_FLOOR],
		# Exit ledge (high)
		[544, 80, 64, 16, COL_ACCENT],
		[640, 112, 48, 16, COL_FLOOR],
		[720, 144, 48, 16, COL_FLOOR],
		# Slide tunnel (standing ~28px tall; gap ~16px forces slide)
		[800, 176, 128, 48, COL_FLOOR],
		[800, 112, 128, 48, COL_WALL],
		# Final stretch
		[960, 160, 160, 64, COL_FLOOR],
		[1088, 128, 32, 32, COL_ACCENT],
		[-32, 0, 32, 224, COL_WALL],
		[1120, 0, 32, 224, COL_WALL],
	]

	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])

	for i in range(5):
		_add_spike(288.0 + i * 16.0, 200.0)

	var goal := ColorRect.new()
	goal.size = Vector2(16, 32)
	goal.position = Vector2(1096, 96)
	goal.color = Color(0.3, 1.0, 0.5, 1.0)
	geometry.add_child(goal)

	var label := Label.new()
	label.text = "META"
	label.position = Vector2(1080, 72)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(0.5, 1.0, 0.6)
	geometry.add_child(label)


func _spawn_enemies() -> void:
	# Suelo de cada plataforma (y = top del sólido). Met anclado por la base.
	# 1) Primer tramo — enseña buster vs caparazón
	_add_met(120.0, 176.0)
	# 2) Plataforma media antes de púas
	_add_met(200.0, 160.0)
	# 3) Tramo final antes del túnel de slide
	_add_met(840.0, 176.0)


func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x + w * 0.5, y + h * 0.5)

	var visual := ColorRect.new()
	visual.size = Vector2(w, h)
	visual.position = Vector2(-w * 0.5, -h * 0.5)
	visual.color = color
	body.add_child(visual)

	var edge := ColorRect.new()
	edge.size = Vector2(w, 2)
	edge.position = Vector2(-w * 0.5, -h * 0.5)
	edge.color = color.lightened(0.25)
	body.add_child(edge)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	geometry.add_child(body)


func _add_spike(x: float, y: float) -> void:
	var spike: Area2D = SpikeScene.instantiate()
	spike.position = Vector2(x, y)
	hazards.add_child(spike)


func _spawn_player() -> void:
	var player: CharacterBody2D = PlayerScene.instantiate()
	player.name = "Player"
	player.position = Vector2(48, 150)
	entities.add_child(player)
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1152
	cam.limit_bottom = 224
	cam.make_current()


func _add_hud() -> void:
	var hud: CanvasLayer = HUDScene.instantiate()
	hud.name = "HUD"
	add_child(hud)
	var player := entities.get_node_or_null("Player")
	if player and hud.has_method("bind_player"):
		hud.bind_player(player)


func _add_touch_controls() -> void:
	var touch: CanvasLayer = TouchControlsScene.instantiate()
	touch.name = "TouchControls"
	add_child(touch)
