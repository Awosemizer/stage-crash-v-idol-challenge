extends Node2D

const CheckpointScript := preload("res://scripts/props/Checkpoint.gd")
## Glitch Ice (touch-first) — estudio congelado / plataformas frame-skip. Secreto: Energy Tank.
## Arena final: Glitch Ice → otorga Freeze Sample.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const GlitchIceScene := preload("res://scenes/bosses/GlitchIce.tscn")
const BreakableBlockScene := preload("res://scenes/props/BreakableBlock.tscn")
const EnergyTankScene := preload("res://scenes/pickups/EnergyTankPickup.tscn")
const FrameSkipScene := preload("res://scenes/props/FrameSkipPlatform.tscn")

const COL_FLOOR := Color(0.22, 0.32, 0.42, 1.0)
const COL_WALL := Color(0.14, 0.2, 0.28, 1.0)
const COL_ACCENT := Color(0.55, 0.85, 1.0, 1.0)
const COL_BG := Color(0.16, 0.32, 0.42, 1.0)
const COL_ARENA := Color(0.25, 0.35, 0.48, 1.0)
const COL_GATE := Color(0.7, 0.9, 1.0, 1.0)
const COL_ICE := Color(0.65, 0.92, 1.0, 1.0)

const LEVEL_RIGHT := 1472.0
const ARENA_LEFT := 1136.0
const ARENA_FLOOR_Y := 176.0
const GATE_X := 1120.0

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
	if GameState and GameState.has_method("begin_stage"):
		GameState.begin_stage("glitch_ice", true)
	if AudioManager:
		AudioManager.play_stage_bgm("glitch_ice")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "glitch_ice", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_course()
	_add_mid_checkpoints()
	_spawn_enemies()
	_build_boss_arena()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	# v0.54 — low path is solid ice; upper path blinks across frame-skip pads.
	# Shaft gap 40px with a mid foothold. Slide crawl is optional.
	var solids: Array = [
		[-32, 0, 32, 224, COL_WALL],
		# low path
		[0, 176, 220, 48, COL_FLOOR],
		[220, 208, 36, 16, COL_WALL],
		[256, 176, 400, 48, COL_FLOOR],
		[672, 176, 40, 48, COL_FLOOR],
		[728, 176, 232, 48, COL_FLOOR],
		[960, 176, 176, 48, COL_FLOOR],
		# upper path steps onto the glitch shelf
		[48, 144, 64, 16, COL_ICE],
		[128, 112, 64, 16, COL_FLOOR],
		[208, 80, 96, 16, COL_ACCENT],
		# wall-jump shaft — 40px open air, mid foothold (not the Beatfire chimney)
		[656, 24, 16, 152, COL_WALL],
		[712, 88, 16, 88, COL_WALL],
		[608, 112, 48, 16, COL_ICE],
		[672, 136, 20, 12, COL_ICE],
		[728, 96, 80, 16, COL_ACCENT],
		[824, 128, 64, 16, COL_FLOOR],
		[904, 160, 64, 16, COL_ICE],
		# sealed tank room off the high shelf
		[824, 64, 64, 16, COL_ACCENT],
		[888, 64, 112, 16, COL_WALL],
		[888, 0, 128, 16, COL_WALL],
		[1000, 0, 16, 80, COL_WALL],
		# optional crawl
		[860, 144, 64, 16, COL_ICE],
		[924, 112, 48, 16, COL_FLOOR],
		[972, 108, 80, 48, COL_WALL],
	]

	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])

	for i in range(3):
		_add_spike(226.0 + i * 12.0, 200.0)

	# Blink pads on the upper shelf. Missing one drops you to the low path.
	_add_frame_skip(Vector2(360, 74), Vector2(360, 112), Vector2(56, 12), 1.25, 0.0)
	_add_frame_skip(Vector2(440, 74), Vector2(500, 74), Vector2(56, 12), 1.1, 0.4)
	_add_frame_skip(Vector2(520, 100), Vector2(520, 140), Vector2(56, 12), 1.35, 0.2)
	_add_frame_skip(Vector2(600, 100), Vector2(640, 140), Vector2(48, 12), 1.0, 0.55)

	_build_secret_energy_tank()

	var label := Label.new()
	label.text = "JEFE →"
	label.position = Vector2(1080, 136)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(0.7, 0.95, 1.0)
	geometry.add_child(label)

	var theme_lbl := Label.new()
	theme_lbl.text = "ESTUDIO GLITCH"
	theme_lbl.position = Vector2(16, 8)
	theme_lbl.add_theme_font_size_override("font_size", 7)
	theme_lbl.modulate = Color(0.65, 0.9, 1.0, 0.75)
	geometry.add_child(theme_lbl)

func _add_frame_skip(a: Vector2, b: Vector2, sz: Vector2, period: float, phase: float) -> void:
	var plat: StaticBody2D = FrameSkipScene.instantiate()
	plat.position = a
	if plat.has_method("configure"):
		plat.configure(a, b, sz, period, phase)
	geometry.add_child(plat)


func _build_boss_arena() -> void:
	_add_rect_platform(ARENA_LEFT, ARENA_FLOOR_Y, 320.0, 48.0, COL_ARENA)
	_add_rect_platform(ARENA_LEFT, 0.0, 320.0, 20.0, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 16.0, 0.0, 32.0, 224.0, COL_WALL)
	_add_rect_platform(ARENA_LEFT + 20.0, 112.0, 56.0, 12.0, COL_ICE)
	_add_rect_platform(ARENA_LEFT + 244.0, 112.0, 56.0, 12.0, COL_ACCENT)
	# Frame-skip platforms in arena
	_add_frame_skip(
		Vector2(ARENA_LEFT + 100.0, 140.0),
		Vector2(ARENA_LEFT + 200.0, 140.0),
		Vector2(40, 12), 1.1, 0.25
	)

	_gate_visual = ColorRect.new()
	_gate_visual.name = "GateVisual"
	_gate_visual.size = Vector2(12, 80)
	_gate_visual.position = Vector2(GATE_X, 80)
	_gate_visual.color = Color(COL_GATE.r, COL_GATE.g, COL_GATE.b, 0.35)
	geometry.add_child(_gate_visual)

	var gate_lbl := Label.new()
	gate_lbl.text = "PUERTA"
	gate_lbl.position = Vector2(GATE_X - 8, 64)
	gate_lbl.add_theme_font_size_override("font_size", 6)
	gate_lbl.modulate = Color(0.75, 0.95, 1.0, 0.8)
	geometry.add_child(gate_lbl)

	_arena_trigger = Area2D.new()
	_arena_trigger.name = "ArenaTrigger"
	_arena_trigger.collision_layer = 0
	_arena_trigger.collision_mask = 2
	_arena_trigger.monitoring = true
	_arena_trigger.monitorable = false
	var trig_shape := RectangleShape2D.new()
	trig_shape.size = Vector2(24, 96)
	var trig_col := CollisionShape2D.new()
	trig_col.shape = trig_shape
	_arena_trigger.position = Vector2(ARENA_LEFT + 40.0, 128.0)
	_arena_trigger.add_child(trig_col)
	entities.add_child(_arena_trigger)
	_arena_trigger.body_entered.connect(_on_arena_entered)

	_boss = GlitchIceScene.instantiate()
	_boss.name = "GlitchIce"
	_boss.position = Vector2(ARENA_LEFT + 200.0, ARENA_FLOOR_Y)
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
		_player.set_spawn_pos(Vector2(ARENA_LEFT + 48.0, ARENA_FLOOR_Y - 20.0))
	if GameState and GameState.has_method("set_stage_checkpoint"):
		GameState.set_stage_checkpoint(Vector2(ARENA_LEFT + 48.0, ARENA_FLOOR_Y - 20.0), "glitch_ice")
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = int(ARENA_LEFT)
			cam.limit_right = int(LEVEL_RIGHT)
			cam.limit_top = 0
			cam.limit_bottom = 224
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡GLITCH ICE!", Color(0.65, 0.95, 1.0), 1.6)
	print("LevelGlitchIce: combate vs Glitch Ice iniciado")


func _close_gate() -> void:
	if _gate_body != null:
		return
	_gate_body = StaticBody2D.new()
	_gate_body.name = "BossGate"
	_gate_body.collision_layer = 1
	_gate_body.collision_mask = 0
	_gate_body.position = Vector2(GATE_X + 6.0, 128.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 96)
	var col := CollisionShape2D.new()
	col.shape = shape
	_gate_body.add_child(col)
	geometry.add_child(_gate_body)
	if _gate_visual:
		_gate_visual.color = COL_GATE
		_gate_visual.size = Vector2(12, 96)
		_gate_visual.position = Vector2(GATE_X, 80)


func _open_gate() -> void:
	if _gate_body and is_instance_valid(_gate_body):
		_gate_body.queue_free()
		_gate_body = null
	if _gate_visual:
		_gate_visual.color = Color(0.5, 1.0, 0.7, 0.55)


func _on_boss_died() -> void:
	if GameState and GameState.has_method("clear_stage_checkpoint"):
		GameState.clear_stage_checkpoint("glitch_ice")
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	_open_gate()
	if GameState.has_method("mark_boss_defeated"):
		GameState.mark_boss_defeated(GameState.BOSS_GLITCH_ICE)
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_right = int(LEVEL_RIGHT)
	if _player and _player.has_method("grant_weapon"):
		_player.grant_weapon("freeze_sample")
	_show_win_banner()
	print("LevelGlitchIce: Glitch Ice derrotado — Freeze Sample otorgado")


func _show_win_banner() -> void:
	if _win_banner and is_instance_valid(_win_banner):
		_win_banner.queue_free()
	_win_banner = CanvasLayer.new()
	_win_banner.name = "WinBanner"
	_win_banner.layer = 80
	add_child(_win_banner)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_banner.add_child(root)
	var panel := Panel.new()
	panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.1, 0.16, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.55, 0.9, 1.0, 1.0)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(196, 96)
	var vp := get_viewport().get_visible_rect().size
	panel.position = Vector2((vp.x - 196.0) * 0.5, (vp.y - 96.0) * 0.5)
	root.add_child(panel)
	var title := Label.new()
	title.name = "Title"
	title.text = "¡VICTORIA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(0.7, 0.95, 1.0, 1.0)
	title.position = Vector2(0, 6)
	title.size = Vector2(196, 18)
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Arma obtenida: Freeze Sample"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.65, 0.95, 1.0, 1.0)
	sub.position = Vector2(0, 26)
	sub.size = Vector2(196, 14)
	panel.add_child(sub)
	var back_btn := Button.new()
	back_btn.name = "ReturnBossSelect"
	back_btn.text = "Volver al selector"
	back_btn.add_theme_font_size_override("font_size", 8)
	back_btn.position = Vector2(28, 48)
	back_btn.size = Vector2(140, 24)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.12, 0.22, 0.32, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.55, 0.9, 1.0, 1.0)
	bn.set_corner_radius_all(3)
	var bh := bn.duplicate()
	bh.bg_color = bn.bg_color.lightened(0.12)
	var bp := bn.duplicate()
	bp.bg_color = bn.bg_color.darkened(0.15)
	back_btn.add_theme_stylebox_override("normal", bn)
	back_btn.add_theme_stylebox_override("hover", bh)
	back_btn.add_theme_stylebox_override("pressed", bp)
	back_btn.add_theme_stylebox_override("focus", bh)
	back_btn.pressed.connect(_return_to_boss_select)
	panel.add_child(back_btn)
	var hint := Label.new()
	hint.name = "AutoHint"
	hint.text = "Auto en 6s…"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 5)
	hint.modulate = Color(0.75, 0.85, 0.95, 0.7)
	hint.position = Vector2(0, 78)
	hint.size = Vector2(196, 10)
	panel.add_child(hint)
	get_tree().create_timer(6.0).timeout.connect(func () -> void:
		if is_instance_valid(self) and _boss_defeated:
			_return_to_boss_select()
	)


func _return_to_boss_select() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/BossSelect.tscn")


func _show_banner(text: String, color: Color, duration: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 75
	add_child(layer)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = color
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	lbl.position = Vector2(48, 24)
	lbl.size = Vector2(160, 20)
	layer.add_child(lbl)
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _build_secret_energy_tank() -> void:
	## Alcoba secreta: Energy Tank (no armadura).
	_seal_secret_rect(888.0, 16.0, 920.0, 64.0)
	var pickup: Area2D = EnergyTankScene.instantiate()
	pickup.name = "EnergyTankPickup"
	pickup.position = Vector2(950.0, 46.0)
	entities.add_child(pickup)
	print("LevelGlitchIce: secreto Energy Tank en alcoba x~220")

func _seal_secret_rect(x0: float, y0: float, x1: float, y1: float) -> void:
	## Rellena el hueco con bloques que se ven como la pared. El pickup no se mueve.
	var x := x0 + 8.0
	while x < x1 - 0.1:
		var y := y0 + 8.0
		while y < y1 - 0.1:
			_add_breakable(x, y)
			y += 16.0
		x += 16.0


func _add_breakable(x: float, y: float) -> void:
	var block: StaticBody2D = BreakableBlockScene.instantiate()
	block.position = Vector2(x, y)
	block.set("block_color", COL_WALL)
	geometry.add_child(block)


func _spawn_enemies() -> void:
	_add_met(80.0, 176.0)
	_add_met(400.0, 176.0)
	_add_met(1040.0, 176.0)

func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x + w * 0.5, y + h * 0.5)

	ArtKit.add_tiled_platform_visuals(body, w, h, color)

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
	## Clear mid-stage markers for glitch_ice (touch-visible cyan pillars).
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(400.0, 176.0), "glitch_ice", "CK1")
	CheckpointScript.place(parent_n, Vector2(1040.0, 176.0), "glitch_ice", "CK2")

func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	var spawn_p := Vector2(56, 148)
	if GameState and GameState.has_method("get_stage_checkpoint"):
		var ck: Vector2 = GameState.get_stage_checkpoint("glitch_ice")
		if ck != Vector2.ZERO:
			spawn_p = ck
	_player.position = spawn_p
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(spawn_p)
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
	# Sync energy tanks from GameState
	if _hud.has_method("sync_energy_tanks_from_state"):
		_hud.sync_energy_tanks_from_state()
	elif GameState.has_method("get_energy_tanks") and _hud.has_method("set_energy_tanks"):
		_hud.set_energy_tanks(GameState.get_energy_tanks())


func _add_touch_controls() -> void:
	var touch: CanvasLayer = TouchControlsScene.instantiate()
	touch.name = "TouchControls"
	add_child(touch)
