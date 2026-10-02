extends Node2D
## Lobby Neon — entrada fortaleza + mid-boss Refrain Unit.
## Tras victoria → Voice Archive.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const RefrainUnitScene := preload("res://scenes/bosses/RefrainUnit.tscn")

const NEXT_SCENE := "res://scenes/levels/LevelVoiceArchive.tscn"
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"

const COL_FLOOR := Color(0.2, 0.12, 0.28, 1.0)
const COL_WALL := Color(0.12, 0.08, 0.18, 1.0)
const COL_NEON := Color(0.95, 0.35, 0.9, 1.0)
const COL_BG := Color(0.05, 0.03, 0.1, 1.0)
const COL_ARENA := Color(0.28, 0.14, 0.35, 1.0)
const COL_GATE := Color(0.9, 0.45, 1.0, 1.0)

const LEVEL_RIGHT := 960.0
const ARENA_LEFT := 640.0
const ARENA_FLOOR_Y := 176.0
const GATE_X := 624.0

@onready var geometry: Node2D = $Geometry
@onready var hazards: Node2D = $Hazards
@onready var entities: Node2D = $Entities
@onready var bg: ColorRect = $ParallaxBG/BG

var _gate_body: StaticBody2D = null
var _gate_visual: ColorRect = null
var _boss: Node = null
var _boss_started := false
var _boss_defeated := false
var _win_banner: CanvasLayer = null
var _arena_trigger: Area2D = null
var _player: CharacterBody2D = null
var _hud: CanvasLayer = null


func _ready() -> void:
	if AudioManager:
		AudioManager.play_stage_bgm("fortress")
	bg.color = COL_BG
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_course()
	_spawn_enemies()
	_build_boss_arena()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	var solids: Array = [
		[0, 176, 120, 48, COL_FLOOR],
		[140, 144, 48, 16, COL_NEON],
		[210, 112, 40, 16, COL_FLOOR],
		[270, 176, 96, 48, COL_FLOOR],
		[390, 144, 48, 16, COL_NEON],
		[460, 176, 160, 48, COL_FLOOR],
		# Slide tunnel
		[520, 112, 96, 48, COL_WALL],
		[-32, 0, 32, 224, COL_WALL],
	]
	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])
	_add_spike(160.0, 200.0)
	_add_spike(176.0, 200.0)
	var theme := Label.new()
	theme.text = "LOBBY NEON · SYNTHOCORP"
	theme.position = Vector2(12, 8)
	theme.add_theme_font_size_override("font_size", 7)
	theme.modulate = Color(0.95, 0.5, 1.0, 0.75)
	geometry.add_child(theme)
	var lbl := Label.new()
	lbl.text = "REFRAIN →"
	lbl.position = Vector2(560, 136)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.modulate = COL_NEON
	geometry.add_child(lbl)


func _build_boss_arena() -> void:
	_add_rect_platform(ARENA_LEFT, ARENA_FLOOR_Y, 304.0, 48.0, COL_ARENA)
	_add_rect_platform(ARENA_LEFT, 0.0, 304.0, 20.0, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 16.0, 0.0, 32.0, 224.0, COL_WALL)
	_add_rect_platform(ARENA_LEFT + 40.0, 120.0, 36.0, 10.0, COL_NEON)
	_add_rect_platform(ARENA_LEFT + 220.0, 120.0, 36.0, 10.0, COL_NEON)

	_gate_visual = ColorRect.new()
	_gate_visual.name = "GateVisual"
	_gate_visual.size = Vector2(12, 80)
	_gate_visual.position = Vector2(GATE_X, 80)
	_gate_visual.color = Color(COL_GATE.r, COL_GATE.g, COL_GATE.b, 0.35)
	geometry.add_child(_gate_visual)

	_arena_trigger = Area2D.new()
	_arena_trigger.name = "ArenaTrigger"
	_arena_trigger.collision_layer = 0
	_arena_trigger.collision_mask = 2
	_arena_trigger.monitoring = true
	var trig_shape := RectangleShape2D.new()
	trig_shape.size = Vector2(24, 96)
	var trig_col := CollisionShape2D.new()
	trig_col.shape = trig_shape
	_arena_trigger.position = Vector2(ARENA_LEFT + 36.0, 128.0)
	_arena_trigger.add_child(trig_col)
	entities.add_child(_arena_trigger)
	_arena_trigger.body_entered.connect(_on_arena_entered)

	_boss = RefrainUnitScene.instantiate()
	_boss.name = "RefrainUnit"
	_boss.position = Vector2(ARENA_LEFT + 180.0, ARENA_FLOOR_Y)
	entities.add_child(_boss)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)


func _on_arena_entered(body: Node) -> void:
	if _boss_started or _boss_defeated:
		return
	if body == null or not body.is_in_group("player"):
		return
	_start_boss_fight()


func _start_boss_fight() -> void:
	_boss_started = true
	_close_gate()
	if _player and _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(Vector2(ARENA_LEFT + 40.0, ARENA_FLOOR_Y - 20.0))
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = int(ARENA_LEFT)
			cam.limit_right = int(LEVEL_RIGHT)
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡REFRAIN UNIT!", COL_NEON, 1.5)
	print("LevelFortressLobby: Refrain Unit")


func _close_gate() -> void:
	if _gate_body != null:
		return
	_gate_body = StaticBody2D.new()
	_gate_body.name = "BossGate"
	_gate_body.collision_layer = 1
	_gate_body.position = Vector2(GATE_X + 6.0, 128.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 96)
	var col := CollisionShape2D.new()
	col.shape = shape
	_gate_body.add_child(col)
	geometry.add_child(_gate_body)
	if _gate_visual:
		_gate_visual.color = COL_GATE


func _open_gate() -> void:
	if _gate_body and is_instance_valid(_gate_body):
		_gate_body.queue_free()
		_gate_body = null
	if _gate_visual:
		_gate_visual.color = Color(0.5, 1.0, 0.7, 0.55)


func _on_boss_died() -> void:
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	if GameState and GameState.has_method("complete_boss_fight_track"):
		GameState.complete_boss_fight_track()
	_open_gate()
	_show_win_banner()
	print("LevelFortressLobby: Refrain Unit derrotado → Voice Archive")


func _show_win_banner() -> void:
	if _win_banner and is_instance_valid(_win_banner):
		_win_banner.queue_free()
	_win_banner = CanvasLayer.new()
	_win_banner.layer = 80
	add_child(_win_banner)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_banner.add_child(root)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.12, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = COL_NEON
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(196, 88)
	panel.position = Vector2(30, 60)
	root.add_child(panel)
	var title := Label.new()
	title.text = "¡REFRAIN CAÍDO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = COL_NEON
	title.position = Vector2(0, 8)
	title.size = Vector2(196, 16)
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "Avanzando al Voice Archive…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.85, 0.75, 1.0)
	sub.position = Vector2(0, 28)
	sub.size = Vector2(196, 14)
	panel.add_child(sub)
	var btn := Button.new()
	btn.text = "Continuar"
	btn.add_theme_font_size_override("font_size", 8)
	btn.position = Vector2(48, 50)
	btn.size = Vector2(100, 22)
	btn.pressed.connect(_go_next)
	panel.add_child(btn)
	get_tree().create_timer(4.0).timeout.connect(func () -> void:
		if is_instance_valid(self) and _boss_defeated:
			_go_next()
	)


func _go_next() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)


func _show_banner(text: String, color: Color, duration: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 75
	add_child(layer)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = color
	lbl.position = Vector2(40, 24)
	lbl.size = Vector2(176, 20)
	layer.add_child(lbl)
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _spawn_enemies() -> void:
	_add_met(80.0, 176.0)
	_add_met(300.0, 176.0)


func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	var visual := ColorRect.new()
	visual.size = Vector2(w, h)
	visual.position = Vector2(-w * 0.5, -h * 0.5)
	visual.color = color
	body.add_child(visual)
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
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	_player.position = Vector2(40, 150)
	entities.add_child(_player)
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_RIGHT)
	cam.limit_bottom = 224
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
	var touch: CanvasLayer = TouchControlsScene.instantiate()
	touch.name = "TouchControls"
	add_child(touch)
