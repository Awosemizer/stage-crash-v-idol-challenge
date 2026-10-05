extends Node2D
const CheckpointScript := preload("res://scripts/props/Checkpoint.gd")
## Core Shaft — subida vertical en tres tramos + Overdub Titan.
## v0.55: suelo con foso y Met (low path) o pasarela alta (upper path),
## pozo de wall-jump de 36px con mid foothold, escalada final con dos Met-Beats.
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
const COL_BG := Color(0.07, 0.02, 0.12, 1.0)
const COL_ARENA := Color(0.25, 0.16, 0.38, 1.0)

# Tall vertical level — camera follows Y. Arena is the top screen (0..224).
const LEVEL_RIGHT := 384.0
const LEVEL_BOTTOM := 784.0
const ARENA_FLOOR_Y := 176.0
const SHAFT_FLOOR_Y := 736.0
const ARENA_HOLE_X := 8.0      # climb enters the arena through a gap in its floor
const ARENA_HOLE_W := 40.0

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
	ArtKit.setup_stage_parallax(bg.get_parent(), "fortress", float(LEVEL_RIGHT), LEVEL_BOTTOM + 80.0)
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
	# Solid floors/walls + thin catwalks you can jump up through (one-way).
	# Footholds rise 32px (Teto jumps ~36). Gaps between steps stay ≤16px.
	var solids: Array = [
		# shaft walls (thick so wide phones never see past them)
		[-40, 0, 48, LEVEL_BOTTOM + 80, COL_WALL],
		[LEVEL_RIGHT - 8, 0, 48, LEVEL_BOTTOM + 80, COL_WALL],
		# ── Tramo 1 · low path: floor, spike pit, Met-Beat ──
		[8, SHAFT_FLOOR_Y, 168, 48, COL_FLOOR],
		[176, SHAFT_FLOOR_Y + 16, 32, 32, COL_WALL],
		[208, SHAFT_FLOOR_Y, 168, 48, COL_FLOOR],
		# landing A (checkpoint) — shaft entrance on the left
		[8, 608, 288, 12, COL_FLOOR],
		# ── Tramo 2 · wall-jump shaft: 36px open air, mid foothold ──
		[44, 512, 16, 56, COL_WALL],
		[8, 560, 10, 8, COL_LEDGE],
		# landing B (checkpoint) — its left end is the shaft lip
		[44, 496, LEVEL_RIGHT - 52, 16, COL_FLOOR],
	]
	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])
	var catwalks: Array = [
		# low path climbs the right wall after the Met
		[320, 704, 56, 10],
		[248, 672, 64, 10],
		[312, 640, 64, 10],
		# upper path: corner step + catwalk over the pit and the Met
		[8, 704, 48, 10],
		[64, 672, 168, 10],
		# ── Tramo 3 · open climb to the arena hole ──
		[304, 464, 72, 10],
		[176, 432, 112, 10],
		[64, 400, 96, 10],
		[8, 368, 48, 10],
		[64, 336, 112, 10],
		[192, 304, 72, 10],
		[280, 272, 96, 10],
		[8, 240, 256, 10],
		[ARENA_HOLE_X, 208, ARENA_HOLE_W - 4.0, 8],
	]
	for c in catwalks:
		_add_rect_platform(float(c[0]), float(c[1]), float(c[2]), float(c[3]), COL_LEDGE, true)
	# Spikes only in the low-path pit; the catwalk above skips them.
	for i in range(2):
		_add_spike(184.0 + i * 16.0, SHAFT_FLOOR_Y + 8.0)


func _build_boss_arena() -> void:
	# Top screen: floor with a climb hole on the left, two dodge ledges.
	var floor_x := ARENA_HOLE_X + ARENA_HOLE_W
	_add_rect_platform(floor_x, ARENA_FLOOR_Y, LEVEL_RIGHT - 8.0 - floor_x, 16, COL_ARENA)
	_add_rect_platform(8, 0, LEVEL_RIGHT - 16, 16, COL_WALL)
	_add_rect_platform(80, ARENA_FLOOR_Y - 32.0, 40, 10, COL_LEDGE, true)
	_add_rect_platform(320, ARENA_FLOOR_Y - 32.0, 48, 10, COL_LEDGE, true)

	_arena_trigger = Area2D.new()
	_arena_trigger.name = "ArenaTrigger"
	_arena_trigger.collision_layer = 0
	_arena_trigger.collision_mask = 2
	_arena_trigger.monitoring = true
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 64)
	var col := CollisionShape2D.new()
	col.shape = sh
	_arena_trigger.position = Vector2(152, ARENA_FLOOR_Y - 32)
	_arena_trigger.add_child(col)
	entities.add_child(_arena_trigger)
	_arena_trigger.body_entered.connect(_on_arena_entered)

	_boss = OverdubTitanScene.instantiate()
	_boss.name = "OverdubTitan"
	_boss.position = Vector2(264, ARENA_FLOOR_Y)
	entities.add_child(_boss)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)


func _close_gate() -> void:
	## Seal the climb hole so the fight stays on the top screen.
	if _gate_body != null:
		return
	_gate_body = StaticBody2D.new()
	_gate_body.name = "ArenaHoleGate"
	_gate_body.collision_layer = 1
	_gate_body.position = Vector2(ARENA_HOLE_X + ARENA_HOLE_W * 0.5, ARENA_FLOOR_Y + 8.0)
	ArtKit.add_tiled_platform_visuals(_gate_body, ARENA_HOLE_W, 16, COL_ARENA, "fortress")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(ARENA_HOLE_W, 16)
	var col := CollisionShape2D.new()
	col.shape = shape
	_gate_body.add_child(col)
	geometry.call_deferred("add_child", _gate_body)


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
		_player.set_spawn_pos(Vector2(60, ARENA_FLOOR_Y - 20))
	if GameState and GameState.has_method("set_stage_checkpoint"):
		GameState.set_stage_checkpoint(Vector2(60, ARENA_FLOOR_Y - 20), "core_shaft")
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_top = 0
			cam.limit_bottom = int(ARENA_FLOOR_Y + 48)
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
	_add_met(296.0, SHAFT_FLOOR_Y)  # low path, past the pit
	_add_met(196.0, 432.0)          # climb: guards the left lip
	_add_met(156.0, 336.0)          # climb: guards the right lip


func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x + w * 0.5, y + h * 0.5)
	ArtKit.add_tiled_platform_visuals(body, w, h, color, "fortress")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.one_way_collision = one_way
	body.add_child(col)
	geometry.add_child(body)


func _add_spike(x: float, y: float) -> void:
	var spike: Area2D = SpikeScene.instantiate()
	spike.position = Vector2(x, y)
	hazards.add_child(spike)


func _add_mid_checkpoints() -> void:
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(232.0, 608.0), "core_shaft", "CK1")
	CheckpointScript.place(parent_n, Vector2(120.0, 496.0), "core_shaft", "CK2")


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	var spawn_p := Vector2(96, SHAFT_FLOOR_Y - 24)
	if GameState and GameState.has_method("get_stage_checkpoint"):
		var ck: Vector2 = GameState.get_stage_checkpoint("core_shaft")
		if ck != Vector2.ZERO:
			spawn_p = ck
	_player.position = spawn_p
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(spawn_p)
	# CRITICAL: default fall death is y>400; shaft floor is ~736
	if _player.has_method("set_fall_death_y"):
		_player.set_fall_death_y(LEVEL_BOTTOM + 60.0)
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(LEVEL_RIGHT)
	cam.limit_bottom = int(LEVEL_BOTTOM)
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
