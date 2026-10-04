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

const NEXT_SCENE := "res://scenes/levels/LevelCoreShaft.tscn"

const COL_FLOOR := Color(0.14, 0.18, 0.28, 1.0)
const COL_WALL := Color(0.1, 0.12, 0.2, 1.0)
const COL_ACCENT := Color(0.45, 0.75, 1.0, 1.0)
const COL_BG := Color(0.07, 0.02, 0.12, 1.0)

const LEVEL_RIGHT := 880.0
const EXIT_X := 820.0

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
	# v0.54 — floor still hits the seals; a stair climbs over them so the exit stays open.
	var solids: Array = [
		[0, 176, LEVEL_RIGHT, 48, COL_FLOOR],
		[-32, 0, 32, 224, COL_WALL],
		[LEVEL_RIGHT - 8, 0, 24, 224, COL_WALL],
		[0, 0, LEVEL_RIGHT, 16, COL_WALL],
		# Seal bypass — vertical stair over the vocal seals
		[160, 144, 64, 16, COL_ACCENT],
		[240, 112, 64, 16, COL_ACCENT],
		[304, 80, 96, 16, COL_ACCENT],
		[416, 112, 64, 16, COL_ACCENT],
		[496, 144, 64, 16, COL_ACCENT],
	]
	for s in solids:
		_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])

	_add_seal(320.0, 176.0)
	_add_seal(336.0, 176.0)

	var tank: Area2D = EnergyTankScene.instantiate()
	tank.name = "ArchiveTank"
	tank.position = Vector2(352.0, 64.0)
	entities.add_child(tank)

	var theme := Label.new()
	theme.text = "VOICE ARCHIVE · SELLOS VOCALES"
	theme.position = Vector2(12, 20)
	theme.add_theme_font_size_override("font_size", 7)
	theme.modulate = Color(0.55, 0.85, 1.0, 0.8)
	geometry.add_child(theme)

	var hint := Label.new()
	hint.text = "Rompe sellos con carga Nv2+ / arma especial / sable"
	hint.position = Vector2(12, 32)
	hint.add_theme_font_size_override("font_size", 5)
	hint.modulate = Color(0.7, 0.8, 0.95, 0.7)
	geometry.add_child(hint)

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

	var exit_lbl := Label.new()
	exit_lbl.text = "CORE SHAFT →"
	exit_lbl.position = Vector2(760, 130)
	exit_lbl.add_theme_font_size_override("font_size", 7)
	exit_lbl.modulate = COL_ACCENT
	geometry.add_child(exit_lbl)

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
	lbl.position = Vector2(28, 28)
	lbl.size = Vector2(200, 18)
	layer.add_child(lbl)
	get_tree().create_timer(duration).timeout.connect(func () -> void:
		if is_instance_valid(layer):
			layer.queue_free()
	)


func _spawn_enemies() -> void:
	_add_met(100.0, 176.0)
	_add_met(500.0, 176.0)


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


func _add_mid_checkpoints() -> void:
	var parent_n: Node = geometry if geometry else self
	CheckpointScript.place(parent_n, Vector2(200.0, 176.0), "voice_archive", "CK1")
	CheckpointScript.place(parent_n, Vector2(640.0, 176.0), "voice_archive", "CK2")


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
