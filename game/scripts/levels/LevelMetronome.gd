extends Node2D

const CheckpointScript := preload("res://scripts/props/Checkpoint.gd")
## Metronome (touch-first) — fábrica de relojes / metrónomos. Púas a intervalos fijos.
## Secreto: piernas Encore Guard (más i-frames en slide). Arena: Metronome → Tempo Spike.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const MetronomeSpikeScene := preload("res://scenes/hazards/MetronomeSpike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const MetronomeScene := preload("res://scenes/bosses/Metronome.tscn")
const BreakableBlockScene := preload("res://scenes/props/BreakableBlock.tscn")
const ArmorPickupScene := preload("res://scenes/pickups/ArmorPickup.tscn")

const COL_FLOOR := Color(0.28, 0.3, 0.38, 1.0)
const COL_WALL := Color(0.18, 0.2, 0.28, 1.0)
const COL_ACCENT := Color(0.85, 0.75, 0.35, 1.0)
const COL_BG := Color(0.11, 0.10, 0.12, 1.0)
const COL_ARENA := Color(0.32, 0.34, 0.42, 1.0)
const COL_GATE := Color(0.75, 0.8, 0.9, 1.0)
const COL_METAL := Color(0.42, 0.44, 0.5, 1.0)

const LEVEL_RIGHT := 3216.0
const ARENA_LEFT := 2880.0
const ARENA_FLOOR_Y := 176.0
const GATE_X := 2864.0

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
		GameState.begin_stage("metronome", true)
	if AudioManager:
		AudioManager.play_stage_bgm("metronome")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "metronome", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_course()
	_add_mid_checkpoints()
	_spawn_enemies()
	_build_boss_arena()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	# v0.56 long course (scripts/gen_stage_courses.py). Every screen has a low path
	# and most have an upper path. Rises <= 32px, one wall-jump shaft with a mid foothold.
	#   x0: start run
	#   x320: spike trenches — low path jumps them, upper path catwalk
	#   x768: metronome spikes on the beat (low path) / catwalk (upper path)
	#   x1216: wall-jump shaft 36px + mid foothold, secret in the right wall
	#   x1664: pillars over a spike floor — low path is the spikes, hop the tops
	#   x2112: block stairs up and down, Met on the summit
	#   x2560: corridor to the gate
	var solids: Array = [
		[-32, 0, 32, 224, COL_WALL],
		[0, 176, 320, 48, COL_FLOOR],
		[320, 176, 128, 48, COL_FLOOR],
		[448, 208, 48, 16, COL_WALL],
		[496, 176, 80, 48, COL_FLOOR],
		[576, 208, 48, 16, COL_WALL],
		[624, 176, 144, 48, COL_FLOOR],
		[768, 176, 448, 48, COL_FLOOR],
		[1216, 176, 448, 48, COL_FLOOR],
		[1312, 40, 16, 104, COL_WALL],
		[1328, 128, 10, 8, COL_METAL],
		[1364, 80, 64, 16, COL_WALL],
		[1412, 96, 16, 32, COL_WALL],
		[1364, 128, 64, 48, COL_WALL],
		[1428, 80, 48, 16, COL_FLOOR],
		[1664, 176, 96, 48, COL_FLOOR],
		[1760, 208, 48, 16, COL_WALL],
		[1808, 160, 32, 64, COL_METAL],
		[1840, 208, 32, 16, COL_WALL],
		[1872, 144, 32, 80, COL_METAL],
		[1904, 208, 32, 16, COL_WALL],
		[1936, 160, 32, 64, COL_METAL],
		[1968, 208, 48, 16, COL_WALL],
		[2016, 176, 96, 48, COL_FLOOR],
		[2112, 176, 448, 48, COL_FLOOR],
		[2176, 144, 64, 32, COL_FLOOR],
		[2240, 112, 64, 64, COL_METAL],
		[2304, 80, 64, 96, COL_FLOOR],
		[2368, 112, 64, 64, COL_METAL],
		[2432, 144, 64, 32, COL_FLOOR],
		[2560, 176, 320, 48, COL_FLOOR],
	]
	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])
	# upper path catwalks — one-way, jump up through them
	var catwalks: Array = [
		[368, 144, 56, 8, COL_METAL],
		[432, 112, 208, 8, COL_METAL],
		[656, 144, 56, 8, COL_METAL],
		[824, 144, 48, 8, COL_METAL],
		[888, 112, 184, 8, COL_METAL],
		[1088, 144, 56, 8, COL_METAL],
		[1492, 112, 48, 8, COL_METAL],
		[1556, 144, 48, 8, COL_METAL],
		[1832, 112, 112, 8, COL_METAL],
	]
	for cw in catwalks:
		_add_rect_platform(float(cw[0]), float(cw[1]), float(cw[2]), float(cw[3]), cw[4], true)
	var spikes: Array = [
		Vector2(456, 200),
		Vector2(472, 200),
		Vector2(488, 200),
		Vector2(584, 200),
		Vector2(600, 200),
		Vector2(616, 200),
		Vector2(1768, 200),
		Vector2(1784, 200),
		Vector2(1800, 200),
		Vector2(1848, 200),
		Vector2(1864, 200),
		Vector2(1912, 200),
		Vector2(1928, 200),
		Vector2(1976, 200),
		Vector2(1992, 200),
		Vector2(2008, 200),
	]
	for sp in spikes:
		_add_spike(sp.x, sp.y)
	_add_metro_spike(Vector2(888, 168), 1.0, 0.35, 0.00)
	_add_metro_spike(Vector2(916, 168), 1.0, 0.35, 0.50)
	_add_metro_spike(Vector2(1000, 168), 1.0, 0.35, 0.15)
	_add_metro_spike(Vector2(1028, 168), 1.0, 0.35, 0.65)
	_add_metro_spike(Vector2(1112, 168), 1.0, 0.35, 0.30)
	_add_metro_spike(Vector2(1140, 168), 1.0, 0.35, 0.80)
	_build_secret_encore_legs()

	var label := Label.new()
	label.text = "JEFE →"
	label.position = Vector2(2824, 136)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(0.8, 0.85, 0.95)
	geometry.add_child(label)

	var theme_lbl := Label.new()
	theme_lbl.text = "FÁBRICA DE RELÓJES"
	theme_lbl.position = Vector2(16, 8)
	theme_lbl.add_theme_font_size_override("font_size", 7)
	theme_lbl.modulate = Color(0.75, 0.8, 0.9, 0.75)
	geometry.add_child(theme_lbl)


func _add_metro_spike(pos: Vector2, period: float, on_ratio: float, phase: float) -> void:
	var spike: Area2D = MetronomeSpikeScene.instantiate()
	spike.position = pos
	spike.period = period
	spike.on_ratio = on_ratio
	spike.phase_offset = phase
	hazards.add_child(spike)


func _build_boss_arena() -> void:
	_add_rect_platform(ARENA_LEFT, ARENA_FLOOR_Y, 320.0, 48.0, COL_ARENA)
	_add_rect_platform(ARENA_LEFT, 0.0, 320.0, 20.0, COL_WALL)
	_add_rect_platform(LEVEL_RIGHT - 16.0, 0.0, 32.0, 224.0, COL_WALL)
	_add_rect_platform(ARENA_LEFT + 20.0, 112.0, 56.0, 12.0, COL_METAL)
	_add_rect_platform(ARENA_LEFT + 244.0, 112.0, 56.0, 12.0, COL_ACCENT)
	# Arena metronome spikes (synced)
	_add_metro_spike(Vector2(ARENA_LEFT + 80.0, ARENA_FLOOR_Y - 8.0), 0.8, 0.4, 0.0)
	_add_metro_spike(Vector2(ARENA_LEFT + 160.0, ARENA_FLOOR_Y - 8.0), 0.8, 0.4, 0.4)
	_add_metro_spike(Vector2(ARENA_LEFT + 240.0, ARENA_FLOOR_Y - 8.0), 0.8, 0.4, 0.0)

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
	gate_lbl.modulate = Color(0.8, 0.85, 0.95, 0.8)
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

	_boss = MetronomeScene.instantiate()
	_boss.name = "Metronome"
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
		GameState.set_stage_checkpoint(Vector2(ARENA_LEFT + 48.0, ARENA_FLOOR_Y - 20.0), "metronome")
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = int(ARENA_LEFT)
			cam.limit_right = int(LEVEL_RIGHT)
			cam.limit_top = 0
			cam.limit_bottom = 224
	if _boss and _boss.has_method("activate"):
		_boss.activate()
	_show_banner("¡METRONOME!", Color(0.8, 0.85, 0.95), 1.6)
	print("LevelMetronome: combate vs Metronome iniciado")


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
		GameState.clear_stage_checkpoint("metronome")
	if AudioManager:
		AudioManager.play_victory()
	_boss_defeated = true
	_open_gate()
	if GameState.has_method("mark_boss_defeated"):
		GameState.mark_boss_defeated(GameState.BOSS_METRONOME)
	if _player:
		var cam: Camera2D = _player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_right = int(LEVEL_RIGHT)
			cam.offset = Vector2.ZERO
	if _player and _player.has_method("grant_weapon"):
		_player.grant_weapon("tempo_spike")
	_show_win_banner()
	print("LevelMetronome: Metronome derrotado — Tempo Spike otorgado")


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
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.75, 0.8, 0.9, 1.0)
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
	title.modulate = Color(0.8, 0.85, 0.95, 1.0)
	title.position = Vector2(0, 6)
	title.size = Vector2(196, 18)
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Arma obtenida: Tempo Spike"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.7, 0.75, 0.9, 1.0)
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
	bn.bg_color = Color(0.16, 0.16, 0.22, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.75, 0.8, 0.9, 1.0)
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
	hint.modulate = Color(0.7, 0.75, 0.85, 0.7)
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


func _build_secret_encore_legs() -> void:
	## Alcoba secreta dentro de la pared derecha del pozo de wall-jump.
	_seal_secret_rect(1364.0, 96.0, 1380.0, 128.0)
	var pickup: Area2D = ArmorPickupScene.instantiate()
	pickup.name = "EncoreLegsPickup"
	pickup.position = Vector2(1396.0, 110.0)
	pickup.armor_set = "encore"
	pickup.armor_piece = "legs"
	pickup.display_name_es = "Piernas Encore Guard"
	pickup.toast_hint_es = "Más i-frames al slide"
	if pickup.has_node("Glow"):
		pickup.get_node("Glow").color = Color(0.85, 0.55, 0.25, 0.4)
	if pickup.has_node("Visual"):
		pickup.get_node("Visual").color = Color(0.8, 0.5, 0.2, 1.0)
	entities.add_child(pickup)
	print("LevelMetronome: secreto Encore Guard legs en alcoba x~220")

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
	# 1 Met per screen-ish, always on a floor top (y = floor).
	_add_met(248.0, 176.0)
	_add_met(536.0, 176.0)
	_add_met(968.0, 112.0)
	_add_met(1636.0, 176.0)
	_add_met(2080.0, 176.0)
	_add_met(2336.0, 80.0)
	_add_met(2720.0, 176.0)


func _add_met(x: float, floor_y: float) -> void:
	var met: Area2D = MetBeatScene.instantiate()
	met.position = Vector2(x, floor_y)
	entities.add_child(met)


func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x + w * 0.5, y + h * 0.5)

	ArtKit.add_tiled_platform_visuals(body, w, h, color)

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
	## v0.56: one checkpoint per section of the long metronome course.
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(360.0, 176.0), "metronome", "CK1")
	CheckpointScript.place(parent_n, Vector2(800.0, 176.0), "metronome", "CK2")
	CheckpointScript.place(parent_n, Vector2(1256.0, 176.0), "metronome", "CK3")
	CheckpointScript.place(parent_n, Vector2(1704.0, 176.0), "metronome", "CK4")
	CheckpointScript.place(parent_n, Vector2(2144.0, 176.0), "metronome", "CK5")
	CheckpointScript.place(parent_n, Vector2(2600.0, 176.0), "metronome", "CK6")


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	var spawn_p := Vector2(56, 148)
	if GameState and GameState.has_method("get_stage_checkpoint"):
		var ck: Vector2 = GameState.get_stage_checkpoint("metronome")
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
