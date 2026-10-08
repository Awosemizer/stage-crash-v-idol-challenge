extends Node2D
const CheckpointScript := preload("res://scripts/props/Checkpoint.gd")
## Voice Archive — touch-first fortress segment.
## Voice Archive — puzzle de sellos vocales (golpe fuerte) + tanque opcional.
## Salida → Core Shaft.

const SpikeScene := preload("res://scenes/hazards/Spike.tscn")
const PlayerScene := preload("res://scenes/player/Player.tscn")
const TouchControlsScene := preload("res://scenes/ui/TouchControls.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const MetBeatScene := preload("res://scenes/enemies/MetBeat.tscn")
const VocalSealScene := preload("res://scenes/props/VocalSeal.tscn")
const EnergyTankScene := preload("res://scenes/pickups/EnergyTankPickup.tscn")
const BreakableBlockScene := preload("res://scenes/props/BreakableBlock.tscn")

const NEXT_SCENE := "res://scenes/levels/LevelCoreShaft.tscn"

const COL_FLOOR := Color(0.14, 0.18, 0.28, 1.0)
const COL_WALL := Color(0.1, 0.12, 0.2, 1.0)
const COL_ACCENT := Color(0.45, 0.75, 1.0, 1.0)
const COL_BG := Color(0.07, 0.02, 0.12, 1.0)

const LEVEL_RIGHT := 2680.0
const EXIT_X := 2624.0

@onready var geometry: Node2D = $Geometry
@onready var hazards: Node2D = $Hazards
@onready var entities: Node2D = $Entities
@onready var bg: ColorRect = $ParallaxBG/BG

var _player: CharacterBody2D = null
var _hud: CanvasLayer = null
var _seals_left := 0
var _exit_trigger: Area2D = null
var _exit_opened := false


func _ready() -> void:
	if GameState and GameState.has_method("begin_stage"):
		GameState.begin_stage("voice_archive", true)
	if AudioManager:
		AudioManager.play_stage_bgm("fortress")
	bg.color = COL_BG
	ArtKit.setup_stage_parallax(bg.get_parent(), "fortress", float(LEVEL_RIGHT))
	bg.offset_right = LEVEL_RIGHT + 64.0
	_build_course()
	_spawn_enemies()
	_add_mid_checkpoints()
	_spawn_player()
	_add_hud()
	_add_touch_controls()


func _build_course() -> void:
	# v0.56 long archive (scripts/gen_stage_courses.py): low path / upper path per screen,
	# two vocal seal doors (wall above them — break the seals), wall-jump shaft with a
	# mid foothold and the energy tank sealed inside its right wall.
	#   x0: start run
	#   x320: spike trenches — low path jumps them, upper path catwalk
	#   x768: vocal seal door — the wall above means you have to break the seals
	#   x928: wall-jump shaft 36px + mid foothold, secret in the right wall
	#   x1376: bottomless gaps between raised islands
	#   x1824: block stairs up and down, Met on the summit
	#   x2272: vocal seal door — the wall above means you have to break the seals
	#   x2432: exit run
	var solids: Array = [
		[-32, 0, 32, 224, COL_WALL],
		[LEVEL_RIGHT - 8, 0, 24, 224, COL_WALL],
		[0, 0, LEVEL_RIGHT, 16, COL_WALL],
		[0, 176, 320, 48, COL_FLOOR],
		[320, 176, 128, 48, COL_FLOOR],
		[448, 208, 48, 16, COL_WALL],
		[496, 176, 80, 48, COL_FLOOR],
		[576, 208, 48, 16, COL_WALL],
		[624, 176, 144, 48, COL_FLOOR],
		[768, 176, 160, 48, COL_FLOOR],
		[832, 16, 32, 112, COL_WALL],
		[928, 176, 448, 48, COL_FLOOR],
		[1024, 40, 16, 104, COL_WALL],
		[1040, 128, 10, 8, COL_ACCENT],
		[1076, 80, 64, 16, COL_WALL],
		[1124, 96, 16, 32, COL_WALL],
		[1076, 128, 64, 48, COL_WALL],
		[1140, 80, 48, 16, COL_FLOOR],
		[1376, 176, 96, 48, COL_FLOOR],
		[1512, 160, 64, 64, COL_ACCENT],
		[1616, 144, 48, 80, COL_ACCENT],
		[1712, 176, 112, 48, COL_FLOOR],
		[1824, 176, 448, 48, COL_FLOOR],
		[1888, 144, 64, 32, COL_FLOOR],
		[1952, 112, 64, 64, COL_ACCENT],
		[2016, 80, 64, 96, COL_FLOOR],
		[2080, 112, 64, 64, COL_ACCENT],
		[2144, 144, 64, 32, COL_FLOOR],
		[2272, 176, 160, 48, COL_FLOOR],
		[2336, 16, 32, 112, COL_WALL],
		[2432, 176, 240, 48, COL_FLOOR],
	]
	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])
	var catwalks: Array = [
		[368, 144, 56, 8, COL_ACCENT],
		[432, 112, 208, 8, COL_ACCENT],
		[656, 144, 56, 8, COL_ACCENT],
		[1204, 112, 48, 8, COL_ACCENT],
		[1268, 144, 48, 8, COL_ACCENT],
	]
	for cw in catwalks:
		_add_rect_platform(float(cw[0]), float(cw[1]), float(cw[2]), float(cw[3]), cw[4], true)
	_add_spike(456.0, 200.0)
	_add_spike(472.0, 200.0)
	_add_spike(488.0, 200.0)
	_add_spike(584.0, 200.0)
	_add_spike(600.0, 200.0)
	_add_spike(616.0, 200.0)
	_add_seal(840.0, 176.0)
	_add_seal(856.0, 176.0)
	_add_seal(2344.0, 176.0)
	_add_seal(2360.0, 176.0)
	# Tank alcove — blocks look like the wall.
	_seal_secret_rect(1076.0, 96.0, 1124.0, 128.0)
	var tank: Area2D = EnergyTankScene.instantiate()
	tank.name = "ArchiveTank"
	tank.position = Vector2(1108.0, 110.0)
	tank.z_index = -2  # detrás de los bloques: la alcoba no se ve
	var _seal_lbl = tank.get_node_or_null("Label")
	if _seal_lbl: _seal_lbl.visible = false
	entities.add_child(tank)

	var theme := Label.new()
	theme.text = "VOICE ARCHIVE · SELLOS VOCALES"
	theme.position = Vector2(132, 40)  # v0.57: fuera del HUD
	theme.add_theme_font_size_override("font_size", 7)
	theme.modulate = Color(0.55, 0.85, 1.0, 0.8)
	geometry.add_child(theme)

	# v0.59: sin cartel de instrucción en etapa (los sellos se descubren jugando).

	var exit_lbl := Label.new()
	exit_lbl.text = "CORE SHAFT →"
	exit_lbl.position = Vector2(2560, 130)
	exit_lbl.add_theme_font_size_override("font_size", 7)
	exit_lbl.modulate = COL_ACCENT
	geometry.add_child(exit_lbl)

	_exit_trigger = Area2D.new()
	_exit_trigger.name = "ExitTrigger"
	_exit_trigger.collision_layer = 0
	_exit_trigger.collision_mask = 2
	_exit_trigger.monitoring = true
	var sh := RectangleShape2D.new()
	sh.size = Vector2(28, 80)
	var col := CollisionShape2D.new()
	col.shape = sh
	_exit_trigger.position = Vector2(EXIT_X, 140.0)
	_exit_trigger.add_child(col)
	entities.add_child(_exit_trigger)
	_exit_trigger.body_entered.connect(_on_exit)


func _seal_secret_rect(x0: float, y0: float, x1: float, y1: float) -> void:
	## Rellena el hueco con bloques que se ven como la pared.
	var x := x0 + 8.0
	while x < x1 - 0.1:
		var y := y0 + 8.0
		while y < y1 - 0.1:
			_add_breakable(x, y, int(round((x - 8.0 - x0) / 16.0)) % 3)
			y += 16.0
		x += 16.0


func _add_breakable(x: float, y: float, variant: int = 0) -> void:
	var block: StaticBody2D = BreakableBlockScene.instantiate()
	block.set("tile_variant", variant)
	block.position = Vector2(x, y)
	block.set("block_color", COL_WALL)
	block.set("show_top_edge", false)
	geometry.add_child(block)


func _add_spike(x: float, y: float) -> void:
	var spike: Area2D = SpikeScene.instantiate()
	spike.position = Vector2(x, y)
	hazards.add_child(spike)


func _add_seal(x: float, floor_y: float) -> void:
	var seal: StaticBody2D = VocalSealScene.instantiate()
	seal.position = Vector2(x, floor_y)
	entities.add_child(seal)
	_seals_left += 1
	if seal.has_signal("broken"):
		seal.broken.connect(_on_seal_broken)


func _on_seal_broken() -> void:
	_seals_left = maxi(_seals_left - 1, 0)
	print("LevelVoiceArchive: sellos restantes=", _seals_left)
	if _seals_left <= 0:
		_show_banner("Sellos rotos — adelante", COL_ACCENT, 1.4)


func _on_exit(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if _seals_left > 0:
		_show_banner("Aún hay sellos…", Color(1.0, 0.6, 0.5), 1.2)
		return
	if _exit_opened:
		return
	_exit_opened = true
	if GameState and GameState.has_method("advance_fortress_segment"):
		GameState.advance_fortress_segment(2)
	get_tree().change_scene_to_file(NEXT_SCENE)


func _show_banner(text: String, color: Color, duration: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 75
	add_child(layer)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = color
	lbl.position = Vector2(99, 36)
	lbl.size = Vector2(200, 18)
	layer.add_child(lbl)
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _spawn_enemies() -> void:
	_add_met(248.0, 176.0)
	_add_met(536.0, 176.0)
	_add_met(904.0, 176.0)
	_add_met(1348.0, 176.0)
	_add_met(1784.0, 176.0)
	_add_met(2048.0, 80.0)
	_add_met(2408.0, 176.0)


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


func _add_mid_checkpoints() -> void:
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(360.0, 176.0), "voice_archive", "CK1")
	CheckpointScript.place(parent_n, Vector2(968.0, 176.0), "voice_archive", "CK2")
	CheckpointScript.place(parent_n, Vector2(1416.0, 176.0), "voice_archive", "CK3")
	CheckpointScript.place(parent_n, Vector2(1856.0, 176.0), "voice_archive", "CK4")
	CheckpointScript.place(parent_n, Vector2(2472.0, 176.0), "voice_archive", "CK5")


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	_player.name = "Player"
	var spawn_p := Vector2(56, 148)
	if GameState and GameState.has_method("get_stage_checkpoint"):
		var ck: Vector2 = GameState.get_stage_checkpoint("voice_archive")
		if ck != Vector2.ZERO:
			spawn_p = ck
	_player.position = spawn_p
	entities.add_child(_player)
	if _player.has_method("set_spawn_pos"):
		_player.set_spawn_pos(spawn_p)
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
