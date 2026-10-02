extends Node2D
## Chorus Bloom (touch-first) — invernadero / escenario floral. Secreto: Energy Tank.
## Arena final: Chorus Bloom → otorga Petal Chorus.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const ChorusBloomScene := preload("res://scenes/bosses/ChorusBloom.tscn")
const BreakableBlockScene := preload("res://scenes/props/BreakableBlock.tscn")
const EnergyTankScene := preload("res://scenes/pickups/EnergyTankPickup.tscn")
const VinePlatformScene := preload("res://scenes/props/VinePlatform.tscn")
const PetalHazardScene := preload("res://scenes/hazards/PetalHazard.tscn")

const COL_FLOOR := Color(0.28, 0.38, 0.22, 1.0)
const COL_WALL := Color(0.18, 0.28, 0.16, 1.0)
const COL_ACCENT := Color(0.85, 0.45, 0.75, 1.0)
const COL_BG := Color(0.08, 0.14, 0.1, 1.0)
const COL_ARENA := Color(0.32, 0.42, 0.28, 1.0)
const COL_GATE := Color(0.95, 0.55, 0.8, 1.0)
const COL_VINE := Color(0.3, 0.7, 0.4, 1.0)

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
	if AudioManager:
		AudioManager.play_stage_bgm("chorus_bloom")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "chorus_bloom", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_course()
	_spawn_enemies()
	_build_boss_arena()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	var solids: Array = [
		# Touch-first — sealed pits, fair gaps, 20px slide clearance
		[0, 176, 160, 48, COL_FLOOR],
		# Approach ledges (wider)
		[144, 144, 56, 16, COL_VINE],
		[208, 112, 48, 16, COL_FLOOR],
		[248, 160, 40, 16, COL_FLOOR],  # safe ledge before spike / shaft
		# Wall-jump shaft — 48px gap + mid foothold
		[304, 80, 16, 128, COL_WALL],
		[368, 32, 16, 176, COL_WALL],
		[304, 192, 80, 32, COL_FLOOR],
		[320, 128, 32, 12, COL_ACCENT],  # mid foothold for touch wall-jumps
		# Secret alcove (high, left of shaft)
		[208, 0, 16, 64, COL_WALL],
		[224, 0, 96, 16, COL_WALL],
		[224, 48, 80, 16, COL_ACCENT],
		[208, 48, 16, 16, COL_WALL],
		# Mid stretch (wider pads)
		[400, 144, 64, 16, COL_FLOOR],
		[480, 112, 56, 16, COL_VINE],
		[552, 80, 56, 16, COL_ACCENT],
		# Stage floor
		[624, 176, 144, 48, COL_FLOOR],
		[624, 120, 48, 16, COL_VINE],
		[688, 144, 56, 16, COL_FLOOR],
		# Slide tunnel — 20px clearance
		[784, 176, 144, 48, COL_FLOOR],
		[784, 108, 144, 48, COL_WALL],
		# Final stretch continuous (no softlock hole)
		[928, 160, 192, 64, COL_FLOOR],
		[-32, 0, 32, 224, COL_WALL],
	]

	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])

	# Spike pit fair for touch
	for i in range(3):
		_add_spike(256.0 + i * 12.0, 200.0)

	# Moving / growing vine platforms
	_add_vine(Vector2(160, 128), Vector2(220, 96), Vector2(48, 12), 2.2, 0.0)
	_add_vine(Vector2(420, 120), Vector2(500, 88), Vector2(48, 12), 2.0, 0.4)
	_add_vine(Vector2(640, 148), Vector2(720, 112), Vector2(48, 12), 2.6, 0.8)
	_add_vine(Vector2(820, 148), Vector2(890, 116), Vector2(44, 12), 1.9, 0.25)
	_add_vine(Vector2(1000, 128), Vector2(1060, 100), Vector2(48, 12), 2.3, 0.55)

	# Petal hazards (above touch UI zone; fair spacing)
	_add_petal(200.0, 100.0)
	_add_petal(460.0, 90.0)
	_add_petal(700.0, 100.0)
	_add_petal(920.0, 90.0)

	_build_secret_energy_tank()

	var label := Label.new()
	label.text = "JEFE →"
	label.position = Vector2(1080, 136)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(0.95, 0.6, 0.85)
	geometry.add_child(label)

	var theme_lbl := Label.new()
	theme_lbl.text = "INVERNADERO SYNTHO"
	theme_lbl.position = Vector2(16, 8)
	theme_lbl.add_theme_font_size_override("font_size", 7)
	theme_lbl.modulate = Color(0.7, 0.95, 0.55, 0.75)
	geometry.add_child(theme_lbl)


func _add_vine(a: Vector2, b: Vector2, sz: Vector2, period: float, phase: float) -> void:
	var plat: AnimatableBody2D = VinePlatformScene.instantiate()
	plat.position = a
	if plat.has_method("configure"):
		plat.configure(a, b, sz, period, phase)
	geometry.add_child(plat)


func _add_petal(x: float, y: float) -> void:
	var petal: Area2D = PetalHazardScene.instantiate()
	petal.position = Vector2(x, y)
	if petal.has_method("configure"):
		petal.configure(Vector2(x, y))
	hazards.add_child(petal)


func _build_boss_arena() -> void:
	_add_rect_platform(ARENA_LEFT, ARENA_FLOOR_Y, 320.0, 48.0, COL_ARENA)
	_add_rect_platform(ARENA_LEFT, 0.0, 320.0, 20.0, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 16.0, 0.0, 32.0, 224.0, COL_WALL)
	_add_rect_platform(ARENA_LEFT + 20.0, 112.0, 56.0, 12.0, COL_VINE)
	_add_rect_platform(ARENA_LEFT + 244.0, 112.0, 56.0, 12.0, COL_ACCENT)
	_add_vine(
		Vector2(ARENA_LEFT + 100.0, 140.0),
		Vector2(ARENA_LEFT + 200.0, 140.0),
		Vector2(40, 12), 2.1, 0.3
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
	gate_lbl.modulate = Color(0.95, 0.7, 0.85, 0.8)
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

	_boss = ChorusBloomScene.instantiate()
	_boss.name = "ChorusBloom"
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
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = int(ARENA_LEFT)
			cam.limit_right = int(LEVEL_RIGHT)
			cam.limit_top = 0
			cam.limit_bottom = 224
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡CHORUS BLOOM!", Color(0.95, 0.55, 0.85), 1.6)
	print("LevelChorusBloom: combate vs Chorus Bloom iniciado")


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
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	_open_gate()
	if GameState.has_method("mark_boss_defeated"):
		GameState.mark_boss_defeated(GameState.BOSS_CHORUS_BLOOM)
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_right = int(LEVEL_RIGHT)
	if _player and _player.has_method("grant_weapon"):
		_player.grant_weapon("petal_chorus")
	_show_win_banner()
	print("LevelChorusBloom: Chorus Bloom derrotado — Petal Chorus otorgado")


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
	sb.bg_color = Color(0.08, 0.12, 0.1, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.55, 0.8, 1.0)
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
	title.modulate = Color(0.95, 0.65, 0.85, 1.0)
	title.position = Vector2(0, 6)
	title.size = Vector2(196, 18)
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Arma obtenida: Petal Chorus"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.7, 0.95, 0.55, 1.0)
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
	bn.bg_color = Color(0.14, 0.24, 0.18, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.95, 0.55, 0.8, 1.0)
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
	hint.modulate = Color(0.75, 0.9, 0.8, 0.7)
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
	_add_breakable(312.0, 48.0)
	_add_breakable(312.0, 64.0)
	var pickup: Area2D = EnergyTankScene.instantiate()
	pickup.name = "EnergyTankPickup"
	pickup.position = Vector2(252.0, 40.0)
	entities.add_child(pickup)
	var hint := Label.new()
	hint.name = "SecretHint"
	hint.text = "¿…?"
	hint.position = Vector2(276, 20)
	hint.add_theme_font_size_override("font_size", 6)
	hint.modulate = Color(0.95, 0.7, 0.85, 0.55)
	geometry.add_child(hint)
	var room_lbl := Label.new()
	room_lbl.text = "SECRETO"
	room_lbl.position = Vector2(196, 12)
	room_lbl.add_theme_font_size_override("font_size", 6)
	room_lbl.modulate = Color(0.7, 0.95, 0.55, 0.7)
	geometry.add_child(room_lbl)
	print("LevelChorusBloom: secreto Energy Tank en alcoba x~220")


func _add_breakable(x: float, y: float) -> void:
	var block: StaticBody2D = BreakableBlockScene.instantiate()
	block.position = Vector2(x, y)
	geometry.add_child(block)


func _spawn_enemies() -> void:
	_add_met(96.0, 176.0)
	_add_met(500.0, 112.0)
	_add_met(860.0, 176.0)


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


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	_player.position = Vector2(56, 148)
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(Vector2(56, 148))
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
	elif GameState.has_method("get_energy_tanks") and _hud.has_method("set_energy_tanks"):
		_hud.set_energy_tanks(GameState.get_energy_tanks())


func _add_touch_controls() -> void:
	var touch: CanvasLayer = TouchControlsScene.instantiate()
	touch.name = "TouchControls"
	add_child(touch)
