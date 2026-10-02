extends Node2D
const CheckpointScript := preload("res://scripts/props/Checkpoint.gd")
## Core Shaft — touch-first vertical climb + arena.
## Core Shaft — sección vertical (hover ayuda) + Overdub Titan.
## Tras victoria → Heart of CORE-9.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const OverdubTitanScene := preload("res://scenes/bosses/OverdubTitan.tscn")

const NEXT_SCENE := "res://scenes/levels/LevelHeartCore9.tscn"

const COL_FLOOR := Color(0.18, 0.12, 0.28, 1.0)
const COL_WALL := Color(0.1, 0.08, 0.16, 1.0)
const COL_LEDGE := Color(0.65, 0.4, 0.95, 1.0)
const COL_BG := Color(0.04, 0.03, 0.08, 1.0)
const COL_ARENA := Color(0.25, 0.16, 0.38, 1.0)

# Tall vertical level — camera follows Y
const LEVEL_RIGHT := 320.0
const LEVEL_BOTTOM := 640.0
const ARENA_FLOOR_Y := 80.0  # near top
const SHAFT_FLOOR_Y := 560.0

@onready var geometry: Node2D = $Geometry
@onready var hazards: Node2D = $Hazards
@onready var entities: Node2D = $Entities
@onready var bg: ColorRect = $ParallaxBG/BG

var _boss: Node = null
var _boss_started := false
var _boss_defeated := false
var _arena_trigger: Area2D = null
var _player: CharacterBody2D = null
var _hud: CanvasLayer = null
var _win_banner: CanvasLayer = null
var _gate_body: StaticBody2D = null


func _ready() -> void:
	if GameState and GameState.has_method("begin_stage"):
		GameState.begin_stage("core_shaft", true)
	if AudioManager:
		AudioManager.play_stage_bgm("fortress")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "fortress", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	bg.offset_bottom = LEVEL_BOTTOM + 64.0
	_build_course()
	_spawn_enemies()
	_build_boss_arena()
	_add_mid_checkpoints()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	# Bottom start platform
	_add_rect_platform(0, SHAFT_FLOOR_Y, 180, 80, COL_FLOOR)
	# Walls of shaft
	_add_rect_platform(-16, 0, 24, LEVEL_BOTTOM + 80, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 8, 0, 24, LEVEL_BOTTOM + 80, COL_WALL)
	# Climbing ledges (hover helps big gaps)
	# Wider footholds + tighter vertical spacing for touch climbs
	# Touch-first climb — ~40px vertical gaps, wider pads, no mid-air spike softlock
	var ledges = [
		[24, 508, 80, 12],
		[176, 468, 80, 12],
		[24, 428, 72, 12],
		[184, 388, 80, 12],
		[24, 348, 72, 12],
		[184, 308, 80, 12],
		[24, 268, 72, 12],
		[184, 228, 80, 12],
		[24, 188, 72, 12],
		[184, 148, 80, 12],
		[40, 120, 72, 12],
	]
	for L in ledges:
		_add_rect_platform(float(L[0]), float(L[1]), float(L[2]), float(L[3]), COL_LEDGE)
	# Spikes only on bottom floor (not floating mid-climb)
	_add_spike(140.0, SHAFT_FLOOR_Y + 16.0)
	_add_spike(200.0, SHAFT_FLOOR_Y + 16.0)
	# Safety net floor under climb so falls respawn instead of softlock void
	_add_rect_platform(0, LEVEL_BOTTOM + 40, LEVEL_RIGHT, 24, COL_WALL)

	var theme := Label.new()
	theme.text = "CORE SHAFT · ASCENSO"
	theme.position = Vector2(40, SHAFT_FLOOR_Y - 40)
	theme.add_theme_font_size_override("font_size", 7)
	theme.modulate = Color(0.75, 0.55, 1.0, 0.8)
	geometry.add_child(theme)
	var hint := Label.new()
	hint.text = "Hover (Stage Flight) ayuda en huecos"
	hint.position = Vector2(24, SHAFT_FLOOR_Y - 28)
	hint.add_theme_font_size_override("font_size", 5)
	hint.modulate = Color(0.6, 0.85, 1.0, 0.65)
	geometry.add_child(hint)


func _build_boss_arena() -> void:
	# Top arena
	_add_rect_platform(16, ARENA_FLOOR_Y, LEVEL_RIGHT - 32, 40, COL_ARENA)
	_add_rect_platform(16, 0, LEVEL_RIGHT - 32, 16, COL_WALL)
	_add_rect_platform(32, 48, 56, 12, COL_LEDGE)
	_add_rect_platform(212, 48, 56, 12, COL_LEDGE)

	_arena_trigger = Area2D.new()
	_arena_trigger.name = "ArenaTrigger"
	_arena_trigger.collision_layer = 0
	_arena_trigger.collision_mask = 2
	_arena_trigger.monitoring = true
	var sh := RectangleShape2D.new()
	sh.size = Vector2(80, 40)
	var col := CollisionShape2D.new()
	col.shape = sh
	_arena_trigger.position = Vector2(160, ARENA_FLOOR_Y - 20)
	_arena_trigger.add_child(col)
	entities.add_child(_arena_trigger)
	_arena_trigger.body_entered.connect(_on_arena_entered)

	_boss = OverdubTitanScene.instantiate()
	_boss.name = "OverdubTitan"
	_boss.position = Vector2(200, ARENA_FLOOR_Y)
	entities.add_child(_boss)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)

	var lbl := Label.new()
	lbl.text = "OVERDUB TITAN"
	lbl.position = Vector2(100, 20)
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.modulate = Color(0.85, 0.6, 1.0)
	geometry.add_child(lbl)


func _on_arena_entered(body: Node) -> void:
	if _boss_started or _boss_defeated:
		return
	if body == null or not body.is_in_group("player"):
		return
	_start_boss_fight()


func _start_boss_fight() -> void:
	_boss_started = true
	if _player and _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(Vector2(60, ARENA_FLOOR_Y - 20))
	if GameState and GameState.has_method("set_stage_checkpoint"):
		GameState.set_stage_checkpoint(Vector2(60, ARENA_FLOOR_Y - 20), "core_shaft")
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_top = 0
			cam.limit_bottom = int(ARENA_FLOOR_Y + 80)
			cam.limit_left = 0
			cam.limit_right = int(LEVEL_RIGHT)
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡OVERDUB TITAN!", Color(0.75, 0.5, 1.0), 1.5)
	print("LevelCoreShaft: Overdub Titan")


func _on_boss_died() -> void:
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	if GameState and GameState.has_method("complete_boss_fight_track"):
		GameState.complete_boss_fight_track()
	if GameState and GameState.has_method("advance_fortress_segment"):
		GameState.advance_fortress_segment(3)
	_show_win_banner()
	print("LevelCoreShaft: Titan derrotado → Heart CORE-9")


func _show_win_banner() -> void:
	_win_banner = CanvasLayer.new()
	_win_banner.layer = 80
	add_child(_win_banner)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_banner.add_child(root)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.14, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.75, 0.5, 1.0)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(196, 84)
	var vp := get_viewport().get_visible_rect().size
	panel.position = Vector2((vp.x - 196.0) * 0.5, (vp.y - 84.0) * 0.5)
	root.add_child(panel)
	var title := Label.new()
	title.text = "¡EJE LIBRE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(0.85, 0.6, 1.0)
	title.position = Vector2(0, 8)
	title.size = Vector2(196, 16)
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "Al corazón de CORE-9…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.position = Vector2(0, 28)
	sub.size = Vector2(196, 14)
	panel.add_child(sub)
	var btn := Button.new()
	btn.text = "Continuar"
	btn.position = Vector2(48, 50)
	btn.size = Vector2(100, 22)
	btn.add_theme_font_size_override("font_size", 8)
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
	lbl.position = Vector2(40, 40)
	lbl.size = Vector2(176, 20)
	layer.add_child(lbl)
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _spawn_enemies() -> void:
	_add_met(80.0, SHAFT_FLOOR_Y)
	_add_met(210.0, 340.0)


func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


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


func _add_spike(x: float, y: float) -> void:
	var spike: Area2D = SpikeScene.instantiate()
	spike.position = Vector2(x, y)
	hazards.add_child(spike)


func _add_mid_checkpoints() -> void:
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(80.0, 468.0), "core_shaft", "CK1")
	CheckpointScript.place(parent_n, Vector2(80.0, 268.0), "core_shaft", "CK2")


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	var spawn_p := Vector2(56, SHAFT_FLOOR_Y - 24)
	if GameState and GameState.has_method("get_stage_checkpoint"):
		var ck: Vector2 = GameState.get_stage_checkpoint("core_shaft")
		if ck != Vector2.ZERO:
			spawn_p = ck
	_player.position = spawn_p
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(spawn_p)
	# CRITICAL: default fall death is y>400; shaft floor is ~560
	if _player.has_method("set_fall_death_y"):
		_player.set_fall_death_y(LEVEL_BOTTOM + 60.0)
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_RIGHT)
	cam.limit_bottom = int(LEVEL_BOTTOM + 80)
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
