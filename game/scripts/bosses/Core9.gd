extends CharacterBody2D
## CORE-9 — jefe final. 3 fases:
## 1) patrones de notas / torretas
## 2) copia 2 ataques de Robot Masters derrotados (GameState)
## 3) núcleo expuesto — solo golpes fuertes cuentan bien (×1.5)

signal died
signal hp_changed(current: int, maximum: int)
signal phase_changed(phase: int)

const HP_MAX := 56
const CONTACT_DAMAGE := 4
const GRAVITY := 500.0
const BEAT_P1 := 0.7
const BEAT_P2 := 0.55
const BEAT_P3 := 0.45
const HIT_FLASH := 0.1
const INVULN_ON_HIT := 0.06
const PHASE2_HP := 38
const PHASE3_HP := 18

enum State { IDLE, NOTE, TURRET, COPY_A, COPY_B, CORE_PULSE, DEAD }

const FireballScene := preload("res://scenes/combat/Fireball.tscn")
const IceGlitchScene := preload("res://scenes/combat/IceGlitchShot.tscn")
const ElectricZigzagScene := preload("res://scenes/combat/ElectricZigzagShot.tscn")
const WindGustScene := preload("res://scenes/combat/WindGust.tscn")
const QuakeWaveScene := preload("res://scenes/hazards/QuakeWave.tscn")
const StaticZoneScene := preload("res://scenes/hazards/StaticZone.tscn")

var hp := HP_MAX
var _state: State = State.IDLE
var _beat := 0.0
var _flash := 0.0
var _invuln := 0.0
var _alive := true
var _active := false
var _facing := -1
var _phase := 1
var _cycle := 0
var _copy_ids: Array = []  # boss ids for phase 2

@onready var visual: ColorRect = $Visual
@onready var core: ColorRect = $Core
@onready var trim: ColorRect = $Trim
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel
@onready var phase_label: Label = $PhaseLabel


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("core9")
	if visual:
		visual.color = Color(0.45, 0.2, 0.65, 1.0)
	if core:
		core.color = Color(1.0, 0.4, 0.95, 0.85)
		core.visible = false
	if trim:
		trim.color = Color(0.85, 0.5, 1.0, 0.9)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "CORE-9"
	_refresh_phase_label()
	_refresh_hp_bar()
	_active = false
	_pick_copy_attacks()


func activate() -> void:
	_active = true
	_beat = 0.4
	_state = State.IDLE
	_phase = 1
	_cycle = 0
	_pick_copy_attacks()
	phase_changed.emit(_phase)
	_refresh_phase_label()
	print("CORE-9: fase 1 — notas/torretas; copia P2=", _copy_ids)


func _pick_copy_attacks() -> void:
	_copy_ids.clear()
	var pool: Array = []
	var gs = GameState
	var candidates := [
		["beatfire", "fire"],
		["echo_wind", "wind"],
		["neon_volt", "volt"],
		["glitch_ice", "ice"],
		["chorus_bloom", "petal"],
		["bassquake", "quake"],
		["metronome", "tempo"],
		["static_shadow", "static"],
	]
	for c in candidates:
		if gs.is_boss_defeated(str(c[0])):
			pool.append(str(c[1]))
	if pool.is_empty():
		pool = ["fire", "volt"]
	# Pick up to 2 distinct
	pool.shuffle()
	_copy_ids = pool.slice(0, mini(2, pool.size()))
	if _copy_ids.size() < 2:
		_copy_ids.append("fire" if "fire" not in _copy_ids else "ice")


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_flash = maxf(_flash - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_update_facing()
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	else:
		velocity.y = 0.0

	if _active and _state == State.IDLE:
		_tick_idle(delta)

	move_and_slide()
	_refresh_look()
	_check_contact_overlap()


func _beat_interval() -> float:
	match _phase:
		2:
			return BEAT_P2
		3:
			return BEAT_P3
		_:
			return BEAT_P1


func _tick_idle(delta: float) -> void:
	_beat -= delta
	velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
	if _beat > 0.0:
		return
	match _phase:
		1:
			match _cycle % 2:
				0:
					_do_notes()
				1:
					_do_turrets()
		2:
			match _cycle % 2:
				0:
					_do_copy(_copy_ids[0] if _copy_ids.size() > 0 else "fire")
				1:
					_do_copy(_copy_ids[1] if _copy_ids.size() > 1 else "volt")
		3:
			_do_core_pulse()
	_cycle += 1


func _do_notes() -> void:
	_state = State.NOTE
	_update_facing()
	# Fan of neon notes
	var n := 3 if hp > PHASE2_HP else 4
	for i in n:
		var ang := deg_to_rad(-18.0 + float(i) * (36.0 / float(maxi(n - 1, 1))))
		var dir := Vector2(float(_facing), 0.0).rotated(ang)
		_spawn_fireball(dir, Color(0.9, 0.55, 1.0, 1.0), 160.0)
	_state = State.IDLE
	_beat = _beat_interval()


func _do_turrets() -> void:
	_state = State.TURRET
	# Drop two note turrets as static fireballs from ceiling spots
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	var player := _get_player()
	var xs: Array = [global_position.x - 48.0, global_position.x + 48.0]
	if player:
		xs.append(player.global_position.x)
	for x in xs:
		var fb: Area2D = FireballScene.instantiate()
		parent_node.add_child(fb)
		fb.global_position = Vector2(float(x), global_position.y - 72.0)
		if fb.has_method("setup"):
			fb.setup(Vector2(0, 1), 120.0)
		if fb.has_node("Visual"):
			fb.get_node("Visual").color = Color(0.7, 0.4, 1.0, 1.0)
	_state = State.IDLE
	_beat = _beat_interval() * 0.9


func _do_copy(atk: String) -> void:
	_state = State.COPY_A
	_update_facing()
	match atk:
		"fire":
			_spawn_fireball(Vector2(float(_facing), 0), Color(1.0, 0.4, 0.15, 1.0), 150.0)
			_spawn_fireball(Vector2(float(_facing), -0.2).normalized(), Color(1.0, 0.4, 0.15, 1.0), 150.0)
		"wind":
			_spawn_wind()
		"volt":
			_spawn_volt()
		"ice":
			_spawn_ice()
		"petal":
			_spawn_petal()
		"quake":
			_spawn_quake()
		"tempo":
			_spawn_fireball(Vector2(float(_facing), 0), Color(0.85, 0.85, 0.95, 1.0), 200.0)
			_spawn_fireball(Vector2(float(-_facing), 0), Color(0.85, 0.85, 0.95, 1.0), 200.0)
		"static":
			_spawn_static()
		_:
			_spawn_fireball(Vector2(float(_facing), 0), Color(0.9, 0.5, 1.0, 1.0), 150.0)
	_state = State.IDLE
	_beat = _beat_interval()


func _do_core_pulse() -> void:
	_state = State.CORE_PULSE
	if core:
		core.visible = true
	# Radial pulses
	for i in range(5):
		var ang := float(i) * TAU / 5.0 + float(Time.get_ticks_msec() % 1000) * 0.001
		var dir := Vector2(cos(ang), sin(ang) * 0.5).normalized()
		_spawn_fireball(dir, Color(1.0, 0.6, 1.0, 1.0), 130.0)
	_state = State.IDLE
	_beat = _beat_interval()


func _spawn_fireball(dir: Vector2, col: Color, spd: float) -> void:
	var fb: Area2D = FireballScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(fb)
	fb.global_position = global_position + Vector2(_facing * 8.0, -20.0)
	if fb.has_method("setup"):
		fb.setup(dir, spd)
	if fb.has_node("Visual"):
		fb.get_node("Visual").color = col


func _spawn_wind() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	if ResourceLoader.exists("res://scenes/combat/WindGust.tscn"):
		var g: Area2D = WindGustScene.instantiate()
		parent_node.add_child(g)
		g.global_position = global_position + Vector2(_facing * 12.0, -16.0)
		if g.has_method("setup"):
			g.setup(Vector2(float(_facing), -0.1).normalized())
	else:
		_spawn_fireball(Vector2(float(_facing), -0.15).normalized(), Color(0.5, 1.0, 0.8, 1.0), 170.0)


func _spawn_volt() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	if ResourceLoader.exists("res://scenes/combat/ElectricZigzagShot.tscn"):
		var z: Area2D = ElectricZigzagScene.instantiate()
		parent_node.add_child(z)
		z.global_position = global_position + Vector2(_facing * 10.0, -18.0)
		if z.has_method("setup"):
			z.setup(Vector2(float(_facing), 0.0))
	else:
		_spawn_fireball(Vector2(float(_facing), 0), Color(1.0, 1.0, 0.3, 1.0), 180.0)


func _spawn_ice() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	if ResourceLoader.exists("res://scenes/combat/IceGlitchShot.tscn"):
		var ice: Area2D = IceGlitchScene.instantiate()
		parent_node.add_child(ice)
		ice.global_position = global_position + Vector2(_facing * 10.0, -18.0)
		if ice.has_method("setup"):
			ice.setup(Vector2(float(_facing), 0.0))
	else:
		_spawn_fireball(Vector2(float(_facing), 0), Color(0.5, 0.85, 1.0, 1.0), 140.0)


func _spawn_petal() -> void:
	# PetalHazard may not expose setup — use fireball stand-in
	_spawn_fireball(Vector2(float(_facing), -0.3).normalized(), Color(1.0, 0.5, 0.75, 1.0), 130.0)
	_spawn_fireball(Vector2(float(_facing), 0.15).normalized(), Color(1.0, 0.55, 0.8, 1.0), 120.0)


func _spawn_quake() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	for side in [-1, 1]:
		var wave: Node2D = QuakeWaveScene.instantiate()
		parent_node.add_child(wave)
		wave.global_position = global_position + Vector2(side * 16.0, -2.0)
		if wave.has_method("setup"):
			wave.setup(side)


func _spawn_static() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	var zone: Area2D = StaticZoneScene.instantiate()
	parent_node.add_child(zone)
	zone.global_position = global_position + Vector2(float(_facing) * 40.0, -8.0)
	if zone.has_method("setup"):
		zone.setup(1.6, 3)


func _check_phase_transition() -> void:
	var prev := _phase
	if hp <= PHASE3_HP:
		_phase = 3
		if core:
			core.visible = true
	elif hp <= PHASE2_HP:
		_phase = 2
	else:
		_phase = 1
	if _phase != prev:
		phase_changed.emit(_phase)
		_refresh_phase_label()
		_beat = 0.25
		print("CORE-9: transición a fase ", _phase)


func take_damage(amount: int) -> bool:
	if not _alive or not _active:
		return false
	if _invuln > 0.0:
		return false
	var dmg := amount
	if _phase == 3:
		# Only strong attacks count well
		if amount >= 3:
			# Charge Nv3/Nv4, saber×?, high weapons — ×1.5
			dmg = int(round(float(amount) * 1.5))
		elif amount >= 2:
			dmg = amount  # mid weapons ok
		else:
			dmg = 1  # weak tick only
	hp = maxi(hp - dmg, 0)
	if AudioManager:
		AudioManager.play_sfx("boss_hit")
	_flash = HIT_FLASH
	_invuln = INVULN_ON_HIT
	_check_phase_transition()
	hp_changed.emit(hp, HP_MAX)
	_refresh_hp_bar()
	if hp <= 0:
		_die()
	return true


func _die() -> void:
	_alive = false
	_active = false
	_state = State.DEAD
	velocity = Vector2.ZERO
	died.emit()
	if visual:
		visual.color = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.55).timeout
	queue_free()


func _update_facing() -> void:
	var player := _get_player()
	if player == null:
		return
	_facing = 1 if player.global_position.x >= global_position.x else -1


func _get_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node2D


func _refresh_hp_bar() -> void:
	if hp_bar_bg == null or hp_bar_fill == null:
		return
	var ratio := 0.0 if HP_MAX <= 0 else float(hp) / float(HP_MAX)
	hp_bar_fill.size.x = maxf(hp_bar_bg.size.x * ratio, 0.0)
	match _phase:
		3:
			hp_bar_fill.color = Color(1.0, 0.35, 0.9, 1.0)
		2:
			hp_bar_fill.color = Color(0.75, 0.4, 1.0, 1.0)
		_:
			hp_bar_fill.color = Color(0.6, 0.35, 0.95, 1.0)


func _refresh_phase_label() -> void:
	if phase_label == null:
		return
	phase_label.text = "FASE %d" % _phase


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.45, 0.2, 0.65, 1.0)
	if _phase == 2:
		base = Color(0.55, 0.18, 0.75, 1.0)
	elif _phase == 3:
		base = Color(0.7, 0.15, 0.85, 1.0)
	if _flash > 0.0:
		visual.color = Color(1, 1, 1, 1)
	else:
		visual.color = base
	if core and _phase == 3:
		core.visible = true
		core.color.a = 0.55 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.01))


func _on_contact_body(body: Node) -> void:
	_hurt_player(body)


func _check_contact_overlap() -> void:
	if not _alive or contact == null:
		return
	for b in contact.get_overlapping_bodies():
		_hurt_player(b)


func _hurt_player(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)
