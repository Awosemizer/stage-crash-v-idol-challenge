extends CharacterBody2D
## Player controller — Mega Man X–style feel for Stage Crash: V-Idol Challenge.
## Input: reads InputMap actions only (move_left/right, jump, slide, attack).
## Touch overlay + joypad press those same actions — do not hardcode keys here.
## GDD refs (px/frame @ 60fps, tile 16px): run 1.5, jump 4.5, grav 0.25,
## wall-jump H 2.5, slide 12 frames. Wall-jump always available.
## Miku: Buster (tap/carga). Teto: Sable melee (sin proyectil por defecto).
## Ambos: Beat Blaze tras vencer a Beatfire Man. Personaje desde GameState.

# --- Tunables (converted to px/s / px/s²) ---
const RUN_SPEED := 90.0          # 1.5 px/frame
const ACCEL_GROUND := 900.0      # snappy but not instant
const ACCEL_AIR := 540.0
const FRICTION_GROUND := 1200.0
const JUMP_VELOCITY := -270.0    # 4.5 px/frame upward
const JUMP_CUT_MULT := 0.45      # release jump mid-air → cut velocity
const GRAVITY := 900.0           # 0.25 px/frame² → * 60²
const MAX_FALL := 360.0          # terminal fall (~6 px/frame)
const WALL_SLIDE_SPEED := 60.0   # slower descent on wall
const WALL_JUMP_H := 150.0       # 2.5 px/frame away from wall
const WALL_JUMP_V := -255.0      # slightly less than grounded jump
const WALL_JUMP_LOCK := 0.12     # brief horizontal lock after wall-jump
const SLIDE_SPEED := 180.0       # short dash along ground
const SLIDE_DURATION := 0.20     # 12 frames @ 60fps
const SLIDE_COOLDOWN := 0.15
const COYOTE_TIME := 0.08
const JUMP_BUFFER := 0.10
const INVULN_SLIDE := 0.12       # stub i-frames at slide start
const RESPAWN_Y := 400.0         # fall death threshold (level-relative)

# Buster charge (Mega Man–style)
const CHARGE_LV2 := 0.45
const CHARGE_LV3 := 1.15
const CHARGE_LV4 := 1.85  # Stage Flight arms unlock
const MAX_SHOTS := 3
const SHOT_SPAWN_X := 12.0
const SHOT_SPAWN_Y := -8.0

# Collision sizes (standing ~36px tall, slide crouched)
const STAND_SIZE := Vector2(14, 28)
const STAND_OFFSET := Vector2(0, -2)
const SLIDE_SIZE := Vector2(22, 14)
const SLIDE_OFFSET := Vector2(0, 5)

const WEAPON_BUSTER := "buster"
const WEAPON_SABER := "saber"
const WEAPON_BEAT_BLAZE := "beat_blaze"
const WEAPON_ECHO_GALE := "echo_gale"
const WEAPON_NEON_ARC := "neon_arc"
const WEAPON_FREEZE_SAMPLE := "freeze_sample"
const WEAPON_PETAL_CHORUS := "petal_chorus"
const WEAPON_QUAKE_DROP := "quake_drop"
const WEAPON_TEMPO_SPIKE := "tempo_spike"
const WEAPON_STATIC_VEIL := "static_veil"

const SABER_DURATION := 0.18
const SABER_DAMAGE := 2
const SABER_COOLDOWN := 0.22
const TETO_RUN_MULT := 0.88
const TETO_JUMP_MULT := 0.94
const TETO_ACCEL_MULT := 0.85

# Stage Flight torso — short air hover (45 frames @ 60fps)
const HOVER_DURATION := 45.0 / 60.0  # 0.75 s fuel
const HOVER_COOLDOWN := 0.40
const HOVER_HOLD_Y := 18.0           # max fall while hovering
const HOVER_LIFT := -12.0            # slight upward assist when falling

const BusterShotScene := preload("res://scenes/combat/BusterShot.tscn")
const BeatBlazeShotScene := preload("res://scenes/combat/BeatBlazeShot.tscn")
const EchoGaleShotScene := preload("res://scenes/combat/EchoGaleShot.tscn")
const NeonArcShotScene := preload("res://scenes/combat/NeonArcShot.tscn")
const FreezeSampleShotScene := preload("res://scenes/combat/FreezeSampleShot.tscn")
const PetalChorusShotScene := preload("res://scenes/combat/PetalChorusShot.tscn")
const QuakeDropShotScene := preload("res://scenes/combat/QuakeDropShot.tscn")
const TempoSpikeShotScene := preload("res://scenes/combat/TempoSpikeShot.tscn")
const StaticVeilShotScene := preload("res://scenes/combat/StaticVeilShot.tscn")

signal hp_changed(current: int, maximum: int)
signal weapon_changed(weapon_id: String, display_name: String, ammo: int, max_ammo: int)

@onready var visual: ColorRect = $Visual
@onready var charge_aura: ColorRect = $ChargeAura
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var wall_ray_l: RayCast2D = $WallRayL
@onready var wall_ray_r: RayCast2D = $WallRayR
@onready var camera: Camera2D = $Camera2D
@onready var saber_hitbox: Area2D = $SaberHitbox
@onready var saber_shape: CollisionShape2D = $SaberHitbox/CollisionShape2D
@onready var saber_visual: ColorRect = $SaberHitbox/SlashVisual

var facing := 1  # 1 = right, -1 = left
var _coyote := 0.0
var _jump_buffer := 0.0
var _wall_lock := 0.0
var _wall_lock_dir := 0
var _slide_timer := 0.0
var _slide_cd := 0.0
var _invuln := 0.0
var _is_sliding := false
var _spawn_pos := Vector2.ZERO
var max_hp := 28
var hp := 28
var _alive := true

var _charging := false
var _charge_time := 0.0
var _key1_held := false
var _key2_held := false

## Weapon inventory: owned weapons only. ammo -1 = infinite (Buster).
var _weapons: Array[Dictionary] = []
var _weapon_index := 0
var _is_teto := false
var _saber_timer := 0.0
var _saber_cd := 0.0
var _saber_hit_ids: Dictionary = {}  # instance_id -> true this swing
var _run_speed := RUN_SPEED
var _jump_vel := JUMP_VELOCITY
var _accel_ground := ACCEL_GROUND
var _accel_air := ACCEL_AIR
var _body_color := Color(0.2, 0.9, 0.95, 1.0)

# Stage Flight hover
var _hover_fuel := HOVER_DURATION
var _hover_cd := 0.0
var _is_hovering := false
var _has_flight_torso := false
var _has_flight_arms := false
var _has_encore_torso := false
var _has_encore_legs := false
var _thruster: ColorRect = null
var _wind_force := Vector2.ZERO
var _key3_held := false
var _key4_held := false
var _key5_held := false
var _key6_held := false
var _key7_held := false
var _key8_held := false
var _key9_held := false


func _ready() -> void:
	add_to_group("player")
	_spawn_pos = global_position
	_apply_stand_shape()
	_apply_character_from_state()
	if charge_aura:
		charge_aura.visible = false
	_setup_saber_hitbox()
	_ensure_thruster()
	_sync_armor_from_state()
	hp_changed.emit(hp, max_hp)
	_emit_weapon()
	var gs := _game_state()
	if gs != null and gs.has_signal("armor_changed"):
		if not gs.armor_changed.is_connected(_on_armor_changed):
			gs.armor_changed.connect(_on_armor_changed)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_tick_timers(delta)
	_handle_weapon_switch()

	var on_floor := is_on_floor()
	var on_wall := _is_on_wall_solid()
	var wall_dir := _wall_direction()  # -1 left wall, 1 right wall, 0 none

	if on_floor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	# Gravity / wall slide / Stage Flight hover
	_is_hovering = false
	if on_floor:
		_hover_fuel = HOVER_DURATION
	elif not _is_sliding:
		# Solo en ápice/caída — no cancelar el impulso del salto
		var want_hover := (
			_has_flight_torso
			and Input.is_action_pressed("jump")
			and _hover_fuel > 0.0
			and _hover_cd <= 0.0
			and _coyote <= 0.0
			and velocity.y >= -20.0
		)
		if want_hover:
			_is_hovering = true
			_hover_fuel = maxf(_hover_fuel - delta, 0.0)
			# Soft float: cancel strong fall, tiny lift
			if velocity.y > HOVER_HOLD_Y:
				velocity.y = move_toward(velocity.y, HOVER_LIFT, 1200.0 * delta)
			else:
				velocity.y = move_toward(velocity.y, HOVER_LIFT, 600.0 * delta)
			if _hover_fuel <= 0.0:
				_hover_cd = HOVER_COOLDOWN
		elif on_wall and velocity.y > 0.0:
			velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
		else:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	# Jump cut (skip while hovering — hold keeps thrusters)
	if not _is_hovering and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULT

	# Slide start
	if _can_slide(on_floor) and Input.is_action_just_pressed("slide"):
		_start_slide()

	# Horizontal move (locked briefly after wall-jump)
	var input_x := Input.get_axis("move_left", "move_right")
	if _wall_lock > 0.0:
		# Keep drifting away from wall; ignore opposite input slightly
		pass
	elif _is_sliding:
		velocity.x = facing * SLIDE_SPEED
	else:
		var target := input_x * _run_speed
		var accel := _accel_ground if on_floor else _accel_air
		if absf(input_x) > 0.01:
			velocity.x = move_toward(velocity.x, target, accel * delta)
			facing = 1 if input_x > 0.0 else -1
		else:
			var fric := FRICTION_GROUND if on_floor else _accel_air * 0.35
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# Jump / wall-jump
	if _jump_buffer > 0.0:
		if _coyote > 0.0 and not _is_sliding:
			_do_jump()
		elif on_wall and not on_floor:
			_do_wall_jump(wall_dir)

	_handle_attack(delta)

	# Wind currents (Echo Wind stage)
	if _wind_force.length_squared() > 0.01 and not _is_sliding:
		velocity += _wind_force
	_wind_force = Vector2.ZERO

	move_and_slide()
	_update_visual()
	_check_hazards_and_pits()


func _handle_weapon_switch() -> void:
	if _weapons.size() <= 1:
		# Still allow number keys to no-op cleanly
		pass
	if Input.is_action_just_pressed("weapon_next"):
		_cycle_weapon(1)
	elif Input.is_action_just_pressed("weapon_prev"):
		_cycle_weapon(-1)
	# Number keys 1–4 as fallback (edge-triggered)
	var k1 := Input.is_physical_key_pressed(KEY_1)
	var k2 := Input.is_physical_key_pressed(KEY_2)
	var k3 := Input.is_physical_key_pressed(KEY_3)
	var k4 := Input.is_physical_key_pressed(KEY_4)
	var k5 := Input.is_physical_key_pressed(KEY_5)
	var k6 := Input.is_physical_key_pressed(KEY_6)
	if k1 and not _key1_held:
		_select_weapon_by_id(WEAPON_SABER if _is_teto else WEAPON_BUSTER)
	if k2 and not _key2_held and _has_weapon(WEAPON_BEAT_BLAZE):
		_select_weapon_by_id(WEAPON_BEAT_BLAZE)
	if k3 and not _key3_held and _has_weapon(WEAPON_ECHO_GALE):
		_select_weapon_by_id(WEAPON_ECHO_GALE)
	if k4 and not _key4_held and _has_weapon(WEAPON_NEON_ARC):
		_select_weapon_by_id(WEAPON_NEON_ARC)
	if k5 and not _key5_held and _has_weapon(WEAPON_FREEZE_SAMPLE):
		_select_weapon_by_id(WEAPON_FREEZE_SAMPLE)
	if k6 and not _key6_held and _has_weapon(WEAPON_PETAL_CHORUS):
		_select_weapon_by_id(WEAPON_PETAL_CHORUS)
	var k7 := Input.is_physical_key_pressed(KEY_7)
	if k7 and not _key7_held and _has_weapon(WEAPON_QUAKE_DROP):
		_select_weapon_by_id(WEAPON_QUAKE_DROP)
	var k8 := Input.is_physical_key_pressed(KEY_8)
	if k8 and not _key8_held and _has_weapon(WEAPON_TEMPO_SPIKE):
		_select_weapon_by_id(WEAPON_TEMPO_SPIKE)
	var k9 := Input.is_physical_key_pressed(KEY_9)
	if k9 and not _key9_held and _has_weapon(WEAPON_STATIC_VEIL):
		_select_weapon_by_id(WEAPON_STATIC_VEIL)
	_key7_held = k7
	_key8_held = k8
	_key9_held = k9
	_key1_held = k1
	_key2_held = k2
	_key3_held = k3
	_key4_held = k4
	_key5_held = k5
	_key6_held = k6


func _cycle_weapon(dir: int) -> void:
	if _weapons.is_empty():
		return
	_weapon_index = (_weapon_index + dir) % _weapons.size()
	if _weapon_index < 0:
		_weapon_index = _weapons.size() - 1
	# Cancel charge when leaving buster
	_charging = false
	_charge_time = 0.0
	_emit_weapon()


func _select_weapon_by_id(wid: String) -> void:
	for i in _weapons.size():
		if str(_weapons[i].get("id", "")) == wid:
			if _weapon_index != i:
				_weapon_index = i
				_charging = false
				_charge_time = 0.0
				_emit_weapon()
			return


func _has_weapon(wid: String) -> bool:
	for w in _weapons:
		if str(w.get("id", "")) == wid:
			return true
	return false


func get_current_weapon() -> Dictionary:
	if _weapons.is_empty():
		if _is_teto:
			return {"id": WEAPON_SABER, "name": "Sable", "ammo": -1, "max_ammo": -1, "cost": 0}
		return {"id": WEAPON_BUSTER, "name": "Buster", "ammo": -1, "max_ammo": -1, "cost": 0}
	return _weapons[_weapon_index]


func get_weapon_id() -> String:
	return str(get_current_weapon().get("id", WEAPON_BUSTER))


func grant_weapon(weapon_id: String) -> void:
	## Otorga arma robada de jefe (… / Tempo Spike / Static Veil).
	var gs := _game_state()
	if gs != null and gs.has_method("unlock_weapon"):
		gs.unlock_weapon(weapon_id)
	if _has_weapon(weapon_id):
		# Refill ammo if already owned and select it
		for i in _weapons.size():
			if str(_weapons[i].get("id", "")) == weapon_id:
				_weapons[i]["ammo"] = int(_weapons[i].get("max_ammo", 28))
				_weapon_index = i
				_charging = false
				_charge_time = 0.0
				_emit_weapon()
				return
		return
	if weapon_id == WEAPON_BEAT_BLAZE:
		_weapons.append({
			"id": WEAPON_BEAT_BLAZE,
			"name": "Beat Blaze",
			"ammo": 28,
			"max_ammo": 28,
			"cost": 1,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Beat Blaze")
	elif weapon_id == WEAPON_ECHO_GALE:
		_weapons.append({
			"id": WEAPON_ECHO_GALE,
			"name": "Echo Gale",
			"ammo": 28,
			"max_ammo": 28,
			"cost": 1,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Echo Gale")
	elif weapon_id == WEAPON_NEON_ARC:
		_weapons.append({
			"id": WEAPON_NEON_ARC,
			"name": "Neon Arc",
			"ammo": 28,
			"max_ammo": 28,
			"cost": 1,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Neon Arc")
	elif weapon_id == WEAPON_FREEZE_SAMPLE:
		_weapons.append({
			"id": WEAPON_FREEZE_SAMPLE,
			"name": "Freeze Sample",
			"ammo": 28,
			"max_ammo": 28,
			"cost": 1,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Freeze Sample")
	elif weapon_id == WEAPON_PETAL_CHORUS:
		_weapons.append({
			"id": WEAPON_PETAL_CHORUS,
			"name": "Petal Chorus",
			"ammo": 28,
			"max_ammo": 28,
			"cost": 1,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Petal Chorus")
	elif weapon_id == WEAPON_QUAKE_DROP:
		_weapons.append({
			"id": WEAPON_QUAKE_DROP,
			"name": "Quake Drop",
			"ammo": 14,
			"max_ammo": 14,
			"cost": 2,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Quake Drop")
	elif weapon_id == WEAPON_TEMPO_SPIKE:
		_weapons.append({
			"id": WEAPON_TEMPO_SPIKE,
			"name": "Tempo Spike",
			"ammo": 14,
			"max_ammo": 14,
			"cost": 2,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Tempo Spike")
	elif weapon_id == WEAPON_STATIC_VEIL:
		_weapons.append({
			"id": WEAPON_STATIC_VEIL,
			"name": "Static Veil",
			"ammo": 14,
			"max_ammo": 14,
			"cost": 3,
		})
		_weapon_index = _weapons.size() - 1
		_charging = false
		_charge_time = 0.0
		_emit_weapon()
		print("Player: arma otorgada Static Veil")


func _emit_weapon() -> void:
	var w := get_current_weapon()
	weapon_changed.emit(
		str(w.get("id", WEAPON_BUSTER)),
		str(w.get("name", "Buster")),
		int(w.get("ammo", -1)),
		int(w.get("max_ammo", -1))
	)


func _handle_attack(delta: float) -> void:
	_tick_saber(delta)
	if _is_sliding:
		if _charging:
			_charging = false
			_charge_time = 0.0
		return

	var wid := get_weapon_id()
	if wid == WEAPON_BEAT_BLAZE:
		_handle_beat_blaze()
	elif wid == WEAPON_ECHO_GALE:
		_handle_echo_gale()
	elif wid == WEAPON_NEON_ARC:
		_handle_neon_arc()
	elif wid == WEAPON_FREEZE_SAMPLE:
		_handle_freeze_sample()
	elif wid == WEAPON_PETAL_CHORUS:
		_handle_petal_chorus()
	elif wid == WEAPON_QUAKE_DROP:
		_handle_quake_drop()
	elif wid == WEAPON_TEMPO_SPIKE:
		_handle_tempo_spike()
	elif wid == WEAPON_STATIC_VEIL:
		_handle_static_veil()
	elif wid == WEAPON_SABER:
		_handle_saber()
	else:
		_handle_buster(delta)



func _apply_character_from_state() -> void:
	_is_teto = false
	var gs := _game_state()
	if gs != null and gs.has_method("is_teto") and gs.is_teto():
		_is_teto = true
	if _is_teto:
		_body_color = Color(0.92, 0.28, 0.35, 1.0)
		_run_speed = RUN_SPEED * TETO_RUN_MULT
		_jump_vel = JUMP_VELOCITY * TETO_JUMP_MULT
		_accel_ground = ACCEL_GROUND * TETO_ACCEL_MULT
		_accel_air = ACCEL_AIR * TETO_ACCEL_MULT
		_weapons = [
			{"id": WEAPON_SABER, "name": "Sable", "ammo": -1, "max_ammo": -1, "cost": 0},
		]
	else:
		_body_color = Color(0.2, 0.9, 0.95, 1.0)
		_run_speed = RUN_SPEED
		_jump_vel = JUMP_VELOCITY
		_accel_ground = ACCEL_GROUND
		_accel_air = ACCEL_AIR
		_weapons = [
			{"id": WEAPON_BUSTER, "name": "Buster", "ammo": -1, "max_ammo": -1, "cost": 0},
		]
	_weapon_index = 0
	if visual:
		visual.color = _body_color
	_restore_unlocked_weapons()


func _restore_unlocked_weapons() -> void:
	## Otorga armas ya desbloqueadas en GameState (incl. Tempo Spike / Static Veil).
	var gs := _game_state()
	if gs == null or not gs.has_method("get_unlocked_weapons"):
		return
	for wid in gs.get_unlocked_weapons():
		grant_weapon(str(wid))
	# Keep default primary selected after restore
	_select_weapon_by_id(WEAPON_SABER if _is_teto else WEAPON_BUSTER)


func _game_state() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")


func is_teto() -> bool:
	return _is_teto


func get_body_color() -> Color:
	return _body_color


func _setup_saber_hitbox() -> void:
	if saber_hitbox == null:
		return
	saber_hitbox.monitoring = false
	saber_hitbox.monitorable = false
	if saber_shape:
		saber_shape.disabled = true
	if saber_visual:
		saber_visual.visible = false
	if not saber_hitbox.body_entered.is_connected(_on_saber_body_entered):
		saber_hitbox.body_entered.connect(_on_saber_body_entered)
	if not saber_hitbox.area_entered.is_connected(_on_saber_area_entered):
		saber_hitbox.area_entered.connect(_on_saber_area_entered)


func _handle_saber() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_swing_saber()


func _swing_saber() -> void:
	if _saber_cd > 0.0 or _saber_timer > 0.0:
		return
	if saber_hitbox == null:
		return
	_saber_hit_ids.clear()
	_saber_timer = SABER_DURATION
	if AudioManager:
		AudioManager.play_sfx("shoot", 0.92)
	_saber_cd = SABER_COOLDOWN
	_position_saber()
	saber_hitbox.monitoring = true
	if saber_shape:
		saber_shape.disabled = false
	if saber_visual:
		saber_visual.visible = true
	# Immediate overlap check (bodies already inside)
	for a in saber_hitbox.get_overlapping_areas():
		_saber_try_hit(a)
	for b in saber_hitbox.get_overlapping_bodies():
		_saber_try_hit(b)


func _tick_saber(delta: float) -> void:
	_saber_cd = maxf(_saber_cd - delta, 0.0)
	if _saber_timer > 0.0:
		_saber_timer -= delta
		_position_saber()
		if _saber_timer <= 0.0:
			_end_saber()


func _end_saber() -> void:
	_saber_timer = 0.0
	if saber_hitbox:
		saber_hitbox.monitoring = false
	if saber_shape:
		saber_shape.disabled = true
	if saber_visual:
		saber_visual.visible = false


func _position_saber() -> void:
	if saber_hitbox == null:
		return
	# Flip hitbox offset with facing
	var ox := 16.0 * float(facing)
	if saber_shape:
		saber_shape.position = Vector2(ox, -6.0)
	if saber_visual:
		if facing >= 0:
			saber_visual.position = Vector2(6, -16)
			saber_visual.size = Vector2(22, 20)
		else:
			saber_visual.position = Vector2(-28, -16)
			saber_visual.size = Vector2(22, 20)


func _on_saber_body_entered(body: Node) -> void:
	_saber_try_hit(body)


func _on_saber_area_entered(area: Node) -> void:
	_saber_try_hit(area)


func _saber_try_hit(target: Node) -> void:
	if target == null or _saber_timer <= 0.0:
		return
	if target.is_in_group("player") or target.is_in_group("player_shots"):
		return
	var id := target.get_instance_id()
	if _saber_hit_ids.has(id):
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		_saber_hit_ids[id] = true
		if target.has_method("take_damage"):
			target.take_damage(SABER_DAMAGE)


func _handle_beat_blaze() -> void:
	# Tap only — no charge
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_beat_blaze()


func _fire_beat_blaze() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 1))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = BeatBlazeShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func _handle_echo_gale() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_echo_gale()


func _fire_echo_gale() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 1))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = EchoGaleShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func _handle_neon_arc() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_neon_arc()


func _fire_neon_arc() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 1))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = NeonArcShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)



func _handle_freeze_sample() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_freeze_sample()


func _fire_freeze_sample() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 1))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = FreezeSampleShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func _handle_petal_chorus() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_petal_chorus()


func _fire_petal_chorus() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 1))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = PetalChorusShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func _handle_quake_drop() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_quake_drop()


func _fire_quake_drop() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 2))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = QuakeDropShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)




func _handle_tempo_spike() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_tempo_spike()


func _fire_tempo_spike() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 2))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = TempoSpikeShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func _handle_static_veil() -> void:
	if _charging:
		_charging = false
		_charge_time = 0.0
	if Input.is_action_just_pressed("attack"):
		_fire_static_veil()


func _fire_static_veil() -> void:
	if AudioManager:
		AudioManager.play_sfx("shoot")
	var w := get_current_weapon()
	var ammo: int = int(w.get("ammo", 0))
	var cost: int = int(w.get("cost", 3))
	if ammo < cost:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	ammo -= cost
	_weapons[_weapon_index]["ammo"] = ammo
	_emit_weapon()
	var shot: Area2D = StaticVeilShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing)


func heal(amount: int) -> void:
	## Cura PV (Petal Chorus / tanques). Cap a max_hp.
	if not _alive or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func _handle_buster(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_charging = true
		_charge_time = 0.0
	elif _charging and Input.is_action_pressed("attack"):
		_charge_time += delta
	elif _charging and Input.is_action_just_released("attack"):
		_fire_buster(_charge_level_from_time(_charge_time))
		_charging = false
		_charge_time = 0.0
	elif not Input.is_action_pressed("attack"):
		_charging = false
		_charge_time = 0.0


func _charge_level_from_time(t: float) -> int:
	if _has_flight_arms and t >= CHARGE_LV4:
		return 4
	if t >= CHARGE_LV3:
		return 3
	if t >= CHARGE_LV2:
		return 2
	return 1


func _fire_buster(level: int) -> void:
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	if AudioManager:
		AudioManager.play_sfx("shoot", 1.0 + 0.06 * float(level - 1))
	var shot: Area2D = BusterShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing, level)
	# Stage Flight arms: +1 damage stub (weapon+)
	if _has_flight_arms and "damage" in shot:
		shot.damage = int(shot.damage) + 1


func _tick_timers(delta: float) -> void:
	_wall_lock = maxf(_wall_lock - delta, 0.0)
	_slide_cd = maxf(_slide_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_hover_cd = maxf(_hover_cd - delta, 0.0)
	if _is_sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0 or not is_on_floor():
			_end_slide()


func _can_slide(on_floor: bool) -> bool:
	return on_floor and not _is_sliding and _slide_cd <= 0.0


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = SLIDE_DURATION
	# Encore Guard: legs = longer slide i-frames; torso = hyper armor
	_invuln = INVULN_SLIDE
	if _has_encore_legs:
		_invuln = 0.30
	if _has_encore_torso:
		_invuln = maxf(_invuln, 0.38)
	_apply_slide_shape()
	velocity.x = facing * SLIDE_SPEED
	velocity.y = 0.0


func _end_slide() -> void:
	_is_sliding = false
	_slide_cd = SLIDE_COOLDOWN
	_apply_stand_shape()


func _do_jump() -> void:
	velocity.y = _jump_vel
	_coyote = 0.0
	_jump_buffer = 0.0
	if AudioManager:
		AudioManager.play_sfx("jump")
	if _is_sliding:
		_end_slide()


func _do_wall_jump(wall_dir: int) -> void:
	# Push away from the wall we are touching
	var push := -wall_dir
	if push == 0:
		# Fallback from rays
		if wall_ray_l.is_colliding():
			push = 1
		elif wall_ray_r.is_colliding():
			push = -1
		else:
			push = -facing
	velocity.x = push * WALL_JUMP_H
	velocity.y = WALL_JUMP_V
	facing = push
	_wall_lock = WALL_JUMP_LOCK
	_wall_lock_dir = push
	_coyote = 0.0
	_jump_buffer = 0.0
	if AudioManager:
		AudioManager.play_sfx("jump", 1.08)
	if _is_sliding:
		_end_slide()


func _is_on_wall_solid() -> bool:
	return wall_ray_l.is_colliding() or wall_ray_r.is_colliding() or is_on_wall()


func _wall_direction() -> int:
	if wall_ray_l.is_colliding() or (is_on_wall() and get_wall_normal().x > 0.5):
		return -1  # wall on left
	if wall_ray_r.is_colliding() or (is_on_wall() and get_wall_normal().x < -0.5):
		return 1  # wall on right
	return 0


func _apply_stand_shape() -> void:
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = STAND_SIZE
	collision.position = STAND_OFFSET
	visual.size = Vector2(16, 32)
	visual.position = Vector2(-8, -18)


func _apply_slide_shape() -> void:
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SLIDE_SIZE
	collision.position = SLIDE_OFFSET
	visual.size = Vector2(24, 14)
	visual.position = Vector2(-12, -2)


func _update_visual() -> void:
	# Flip placeholder with facing; flash during invuln
	visual.scale.x = 1.0
	if facing < 0:
		visual.position.x = absf(visual.size.x) * 0.5
		# Keep ColorRect left-anchored; mirror via offset feel
		visual.position.x = -visual.size.x + (8 if not _is_sliding else 12)
	else:
		visual.position.x = -visual.size.x * 0.5

	var base_col := _body_color
	if not is_on_floor() and _is_on_wall_solid() and velocity.y > 0.0:
		base_col = _body_color.lightened(0.15)
	elif _is_sliding:
		base_col = _body_color.darkened(0.12)
	elif _saber_timer > 0.0:
		base_col = _body_color.lightened(0.2)

	# Aura de carga solo con Buster
	var lv := 0
	if get_weapon_id() == WEAPON_BUSTER and _charging:
		lv = _charge_level_from_time(_charge_time)
	if charge_aura:
		if lv >= 2:
			charge_aura.visible = true
			var aura_sz := visual.size + Vector2(6, 6) if lv == 2 else visual.size + Vector2(10, 10)
			charge_aura.size = aura_sz
			charge_aura.position = visual.position - Vector2(3, 3) if lv == 2 else visual.position - Vector2(5, 5)
			if lv >= 4:
				# Nv4 stub (brazos): pulso violeta-dorado
				var pulse4 := 0.6 + 0.4 * absf(sin(_charge_time * 16.0))
				charge_aura.color = Color(0.85, 0.45, 1.0, pulse4)
				base_col = Color(0.9, 0.7, 1.0, 1.0)
			elif lv >= 3:
				# Parpadeo blanco-dorado Nv3
				var pulse := 0.55 + 0.45 * absf(sin(_charge_time * 12.0))
				charge_aura.color = Color(1.0, 0.92, 0.35, pulse)
				base_col = Color(0.95, 0.95, 0.6, 1.0)
			else:
				charge_aura.color = Color(0.35, 0.75, 1.0, 0.45 + 0.25 * absf(sin(_charge_time * 8.0)))
				base_col = Color(0.45, 0.85, 1.0, 1.0)
		else:
			charge_aura.visible = false
			if get_weapon_id() == WEAPON_BUSTER and _charging and _charge_time > 0.12:
				# Nv1 charging hint: ligero brillo en el cuerpo
				base_col = Color(0.35, 0.95, 1.0, 1.0)
			elif get_weapon_id() == WEAPON_BEAT_BLAZE:
				base_col = Color(0.95, 0.55, 0.25, 1.0)
			elif get_weapon_id() == WEAPON_NEON_ARC:
				base_col = Color(0.95, 0.9, 0.25, 1.0)

	if _is_hovering:
		base_col = base_col.lerp(Color(0.45, 0.9, 1.0, 1.0), 0.35)
	_update_thruster()

	if _invuln > 0.0:
		visual.color = base_col
		visual.color.a = 0.45 if fmod(_invuln, 0.06) < 0.03 else 1.0
	else:
		visual.color = base_col
		visual.color.a = 1.0


func _check_hazards_and_pits() -> void:
	if global_position.y > RESPAWN_Y:
		_respawn()
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider and collider.is_in_group("hazards"):
			if _invuln <= 0.0:
				_take_hit(4)
			break


func take_hit(amount: int) -> void:
	## Alias kept for hazards / slide collisions.
	take_damage(amount)


func apply_wind(force: Vector2) -> void:
	## Acumula empuje de corrientes (WindCurrent) este frame.
	_wind_force += force


func take_damage(amount: int) -> void:
	_take_hit(amount)


func _take_hit(amount: int) -> void:
	if _invuln > 0.0:
		return
	# Hard: +2 daño de contacto / golpes
	if GameState and GameState.has_method("scale_incoming_damage"):
		amount = int(GameState.scale_incoming_damage(amount))
	# Encore Guard torso: reduce contact / hit damage by 1 (min 1)
	if _has_encore_torso and amount > 1:
		amount = maxi(1, amount - 1)
	hp = maxi(hp - amount, 0)
	# GDD: 1.0 s Normal / 0.6 s Hard
	if GameState and GameState.has_method("get_hurt_invuln_time"):
		_invuln = float(GameState.get_hurt_invuln_time())
	else:
		_invuln = 1.0
	if GameState and GameState.has_method("note_player_damaged"):
		GameState.note_player_damaged()
	if AudioManager:
		AudioManager.play_sfx("hurt")
	# Cancel charge on hit
	_charging = false
	_charge_time = 0.0
	velocity = Vector2(-facing * 80.0, -120.0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_respawn()


func _respawn() -> void:
	hp = max_hp
	_invuln = 0.5
	_is_sliding = false
	_charging = false
	_charge_time = 0.0
	_apply_stand_shape()
	velocity = Vector2.ZERO
	global_position = _spawn_pos
	hp_changed.emit(hp, max_hp)


func set_spawn_pos(pos: Vector2) -> void:
	_spawn_pos = pos


func is_invulnerable() -> bool:
	return _invuln > 0.0


func get_charge_level() -> int:
	## Para tests / HUD futuro.
	if not _charging or get_weapon_id() != WEAPON_BUSTER:
		return 0
	return _charge_level_from_time(_charge_time)

func _on_armor_changed(_set_id: String) -> void:
	_sync_armor_from_state()


func _sync_armor_from_state() -> void:
	_has_flight_torso = false
	_has_flight_arms = false
	_has_encore_torso = false
	_has_encore_legs = false
	var gs := _game_state()
	if gs != null and gs.has_method("has_flight_torso_equipped"):
		_has_flight_torso = bool(gs.has_flight_torso_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_flight_torso = bool(gs.is_armor_equipped("flight", "torso"))
	if gs != null and gs.has_method("has_flight_arms_equipped"):
		_has_flight_arms = bool(gs.has_flight_arms_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_flight_arms = bool(gs.is_armor_equipped("flight", "arms"))
	if gs != null and gs.has_method("has_encore_torso_equipped"):
		_has_encore_torso = bool(gs.has_encore_torso_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_encore_torso = bool(gs.is_armor_equipped("encore", "torso"))
	if gs != null and gs.has_method("has_encore_legs_equipped"):
		_has_encore_legs = bool(gs.has_encore_legs_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_encore_legs = bool(gs.is_armor_equipped("encore", "legs"))


func on_armor_pickup(set_id: String, piece_id: String, _display_name: String = "") -> void:
	## Llamado por ArmorPickup tras grant en GameState.
	_sync_armor_from_state()
	if set_id == "flight" and piece_id == "torso":
		_hover_fuel = HOVER_DURATION
		_hover_cd = 0.0
		print("Player: Stage Flight torso equipado — hover listo")
	elif set_id == "flight" and piece_id == "arms":
		print("Player: Stage Flight brazos — carga Nv4 + daño+")
	elif set_id == "encore" and piece_id == "torso":
		print("Player: Encore Guard torso — defensa + hyper armor slide")
	elif set_id == "encore" and piece_id == "legs":
		print("Player: Encore Guard piernas — más i-frames en slide")
	elif set_id == "encore" and piece_id == "head":
		print("Player: Encore Guard casco — revelación de debilidades")


func has_flight_hover() -> bool:
	return _has_flight_torso


func has_flight_arms() -> bool:
	return _has_flight_arms


func has_encore_torso() -> bool:
	return _has_encore_torso


func has_encore_legs() -> bool:
	return _has_encore_legs


func is_hovering() -> bool:
	return _is_hovering


func get_hover_fuel_ratio() -> float:
	return clampf(_hover_fuel / HOVER_DURATION, 0.0, 1.0)


func _ensure_thruster() -> void:
	if _thruster != null and is_instance_valid(_thruster):
		return
	_thruster = ColorRect.new()
	_thruster.name = "ThrusterStub"
	_thruster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thruster.visible = false
	_thruster.z_index = -1
	_thruster.size = Vector2(8, 6)
	_thruster.color = Color(0.4, 0.85, 1.0, 0.7)
	add_child(_thruster)


func _update_thruster() -> void:
	if _thruster == null:
		return
	if _is_hovering:
		_thruster.visible = true
		var pulse := 0.45 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.02))
		_thruster.color = Color(0.35, 0.9, 1.0, pulse)
		_thruster.size = Vector2(8 + 2.0 * pulse, 5 + 3.0 * pulse)
		_thruster.position = Vector2(-_thruster.size.x * 0.5, 10.0)
	else:
		_thruster.visible = false
