extends Node2D
## Heart CORE-9 — touch-first final arena.
## Heart of CORE-9 — arena final. Tras victoria → Ending.

const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const Core9Scene := preload("res://scenes/bosses/Core9.tscn")

const ENDING_SCENE := "res://scenes/ui/EndingScreen.tscn"

const COL_FLOOR := Color(0.22, 0.1, 0.32, 1.0)
const COL_WALL := Color(0.1, 0.05, 0.16, 1.0)
const COL_ACCENT := Color(0.9, 0.4, 1.0, 1.0)
const COL_BG := Color(0.07, 0.02, 0.12, 1.0)

const LEVEL_RIGHT := 384.0
const FLOOR_Y := 176.0

@onready var geometry: Node2D = $Geometry
@onready var hazards: Node2D = $Hazards
@onready var entities: Node2D = $Entities
@onready var bg: ColorRect = $ParallaxBG/BG

var _boss: Node = null
var _boss_started := false
var _boss_defeated := false
var _player: CharacterBody2D = null
var _hud: CanvasLayer = null
var _phase_banner: CanvasLayer = null


func _ready() -> void:
	if GameState and GameState.has_method("begin_stage"):
		GameState.begin_stage("heart_core9", true)
	if AudioManager:
		AudioManager.play_stage_bgm("core9")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "fortress", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_arena()
	_spawn_player()
	_add_hud()
	_add_touch_controls()
	# Auto-start shortly after spawn
	get_tree().create_timer(0.6).timeout.connect(_start_boss_fight)


func _build_arena() -> void:
	_add_rect_platform(0, FLOOR_Y, LEVEL_RIGHT, 48, COL_FLOOR)
	_add_rect_platform(0, 0, LEVEL_RIGHT, 20, COL_WALL)
	_add_rect_platform(-16, 0, 24, 224, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 8, 0, 24, 224, COL_WALL)
	# Pads above touch UI zone
	_add_rect_platform(40, 112, 56, 12, COL_ACCENT)
	_add_rect_platform(LEVEL_RIGHT - 96, 112, 56, 12, COL_ACCENT)

	var theme := Label.new()
	theme.text = "HEART OF CORE-9"
	theme.position = Vector2(70, 28)
	theme.add_theme_font_size_override("font_size", 9)
	theme.modulate = Color(0.95, 0.55, 1.0, 0.9)
	geometry.add_child(theme)

	_boss = Core9Scene.instantiate()
	_boss.name = "Core9"
	_boss.position = Vector2(LEVEL_RIGHT * 0.62, FLOOR_Y)
	entities.add_child(_boss)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)
	if _boss.has_signal("phase_changed"):
		_boss.phase_changed.connect(_on_phase_changed)


func _start_boss_fight() -> void:
	if _boss_started or _boss_defeated:
		return
	_boss_started = true
	if _player and _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(Vector2(56, FLOOR_Y - 20))
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡CORE-9!", COL_ACCENT, 1.6)
	print("LevelHeartCore9: combate final")


func _on_phase_changed(phase: int) -> void:
	var texts := {
		1: "FASE 1 — Notas del DJ",
		2: "FASE 2 — Copia un ataque",
		3: "NÚCLEO — solo Nv4, Sonic Slash o Counter",
	}
	_show_banner(str(texts.get(phase, "FASE %d" % phase)), COL_ACCENT, 1.3)


func _on_boss_died() -> void:
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	if GameState.has_method("mark_boss_defeated"):
		GameState.mark_boss_defeated(GameState.BOSS_CORE9)
	_show_win_then_ending()
	print("LevelHeartCore9: CORE-9 derrotado")


func _show_win_then_ending() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.03, 0.12, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = COL_ACCENT
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(210, 100)
	var vp := get_viewport().get_visible_rect().size
	panel.position = Vector2((vp.x - 210.0) * 0.5, (vp.y - 100.0) * 0.5)
	root.add_child(panel)
	var title := Label.new()
	title.text = "¡CORE-9 CAÍDO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = COL_ACCENT
	title.position = Vector2(0, 8)
	title.size = Vector2(210, 18)
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "El escenario se apaga…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.position = Vector2(0, 30)
	sub.size = Vector2(210, 14)
	panel.add_child(sub)
	var btn := Button.new()
	btn.text = "Ver ending"
	btn.add_theme_font_size_override("font_size", 9)
	btn.position = Vector2(40, 54)
	btn.size = Vector2(130, 28)
	btn.pressed.connect(_go_ending)
	panel.add_child(btn)
	get_tree().create_timer(3.2).timeout.connect(func () -> void:
		if is_instance_valid(self) and _boss_defeated:
			_go_ending()
	)


func _go_ending() -> void:
	get_tree().change_scene_to_file(ENDING_SCENE)


func _show_banner(text: String, color: Color, duration: float) -> void:
	if _phase_banner and is_instance_valid(_phase_banner):
		_phase_banner.queue_free()
	_phase_banner = CanvasLayer.new()
	_phase_banner.layer = 75
	add_child(_phase_banner)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = color
	lbl.position = Vector2(28, 44)
	lbl.size = Vector2(200, 18)
	_phase_banner.add_child(lbl)
	var layer_ref := _phase_banner
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer_ref):
			layer_ref.queue_free()
	)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	ArtKit.add_tiled_platform_visuals(body, w, h, color, "fortress")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	geometry.add_child(body)


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	_player.position = Vector2(56, FLOOR_Y - 24)
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(Vector2(56, FLOOR_Y - 24))
	if _player.has_method("set_fall_death_y"):
		_player.set_fall_death_y(280.0)
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_RIGHT)
	cam.limit_bottom = 224
	cam.drag_left_margin = 0.22
	cam.drag_right_margin = 0.22
	cam.drag_top_margin = 0.18
	cam.drag_bottom_margin = 0.45
	cam.offset = Vector2(0, -22)
	cam.position_smoothing_speed = 10.0
	cam.make_current()


func _add_hud() -> void:
	_hud = HUDScene.instantiate()
	_hud.name = "HUD"
	add_child(_hud)
	var player := entities.get_node_or_null("Player")
	if player and _hud.has_method("bind_player"):
		_hud.bind_player(player)
	if _hud.has_method("sync_energy_tanks_from_state"):
		_hud.sync_energy_tanks_from_state()


func _add_touch_controls() -> void:
	add_child(TouchControlsScene.instantiate())
