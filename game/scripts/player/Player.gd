extends CharacterBody2D
## Player controller — Mega Man X–style feel for Stage Crash: V-Idol Challenge.
## Input: reads InputMap actions only (move_left/right, jump, slide, attack).
## Touch overlay + joypad press those same actions — do not hardcode keys here.
## GDD refs (px/frame @ 60fps, tile 16px): run 1.5, jump 4.5, grav 0.25,
## wall-jump H 2.5, slide 12 frames. Wall-jump always available.
## Miku: Buster (tap/carga; Nv4 con Flight arms). Teto: Sable (+ Sonic Slash con Flight arms).
## Encore Guard: Barrier Pulse (Miku) / Counter Guard (Teto). Flight set completo: hover+.
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
const WALL_JUMP_LOCK := 0.16     # brief horizontal lock after wall-jump (touch)
const SLIDE_SPEED := 180.0       # short dash along ground
const SLIDE_DURATION := 0.22     # ~13 frames @ 60fps — slightly more reliable
const SLIDE_COOLDOWN := 0.10     # snappier re-slide on touch
const COYOTE_TIME := 0.12        # forgiving ledge jumps (touch)
const JUMP_BUFFER := 0.14        # early jump press still counts
const WALL_COYOTE := 0.10        # brief wall memory for touch wall-jump
const SLIDE_BUFFER := 0.12       # press slide slightly before landing
const SLIDE_AIR_GRACE := 0.06    # don't cancel slide on 1–2-frame air blip
const INVULN_SLIDE := 0.14       # stub i-frames at slide start
const HURT_FLASH := 0.22         # clear red/white flash on hit
const RESPAWN_Y := 400.0         # fall death threshold (level-relative)
const RESPAWN_INVULN := 0.65     # brief i-frames after pit/death respawn (snappy)
const CHECKPOINT_FLASH := 0.28   # spawn ping when checkpoint updates
const RESPAWN_FADE := 0.12       # quick blackout on death — less frustration

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
const HOVER_DURATION_FULL := 60.0 / 60.0  # full Stage Flight set bonus
const HOVER_COOLDOWN := 0.40
const HOVER_HOLD_Y := 18.0           # max fall while hovering
const HOVER_LIFT := -12.0            # slight upward assist when falling

# Encore Guard specials
const BARRIER_DURATION := 0.50
const BARRIER_COOLDOWN := 0.85
const DOUBLE_SLIDE_WINDOW := 0.30
const PARRY_WINDOW := 0.16
const COUNTER_DAMAGE := 4
const SONIC_CHARGE := 0.45  # hold attack for Sonic Slash (Flight arms)

const BusterShotScene := preload("res://scenes/combat/BusterShot.tscn")
const SonicSlashShotScene := preload("res://scenes/combat/SonicSlashShot.tscn")
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

@onready var visual: Sprite2D = $Visual
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
var _wall_coyote := 0.0
var _last_wall_dir := 0  # remembered while wall-coyote active
var _wall_lock := 0.0
var _wall_lock_dir := 0
var _slide_timer := 0.0
var _slide_cd := 0.0
var _slide_buffer := 0.0
var _slide_air_timer := 0.0
var _invuln := 0.0
var _hurt_flash := 0.0
var _checkpoint_flash := 0.0
var _respawn_fade := 0.0
var _was_on_floor := false
var _death_veil: ColorRect = null
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
var _anim_time := 0.0
var _tex_idle: Texture2D
var _tex_run: Texture2D
var _tex_jump: Texture2D
var _tex_slide: Texture2D
var _run_frame := 0
var _idle_frame := 0
var _charge_rings: Dictionary = {}
var _prev_charge_lv := 0
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
var _has_flight_head := false
var _has_full_flight := false
var _has_encore_torso := false
var _has_encore_legs := false
var _has_encore_head := false
var _thruster: ColorRect = null
var _wind_force := Vector2.ZERO
# Encore specials / Teto charge
var _barrier_timer := 0.0
var _barrier_cd := 0.0
var _slide_tap_window := 0.0
var _parry_window := 0.0
var _barrier_visual: ColorRect = null
var _parry_visual: ColorRect = null
var _pending_saber_after_parry := false
var _key3_held := false
var _key4_held := false
var _key5_held := false
var _key6_held := false
var _key7_held := false
var _key8_held := false
var _key9_held := false


func _ready() -> void:
	apply_touch_camera_feel()
	add_to_group("player")
	_spawn_pos = global_position
	_apply_stand_shape()
	_apply_character_from_state()
	if charge_aura:
		charge_aura.visible = false
	_setup_saber_hitbox()
	_ensure_thruster()
	_ensure_barrier_visuals()
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
	if on_floor and not _was_on_floor and velocity.y >= 0.0:
		_spawn_land_dust()
	_was_on_floor = on_floor
	var on_wall := _is_on_wall_solid()
	var wall_dir := _wall_direction()  # -1 left wall, 1 right wall, 0 none

	if on_floor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	if on_wall and not on_floor:
		_wall_coyote = WALL_COYOTE
		if wall_dir != 0:
			_last_wall_dir = wall_dir
	else:
		_wall_coyote = maxf(_wall_coyote - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	# Slide buffer — early press still fires on landing
	if Input.is_action_just_pressed("slide"):
		_slide_buffer = SLIDE_BUFFER
	else:
		_slide_buffer = maxf(_slide_buffer - delta, 0.0)

	# Gravity / wall slide / Stage Flight hover
	_is_hovering = false
	if on_floor:
		_hover_fuel = _hover_max()
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

	# Slide start (+ buffer + Miku Encore Barrier Pulse via double-tap slide)
	var want_slide := Input.is_action_just_pressed("slide") or _slide_buffer > 0.0
	if want_slide and _can_slide(on_floor):
		_slide_buffer = 0.0
		if (
			_has_encore_torso
			and not _is_teto
			and _slide_tap_window > 0.0
			and _barrier_cd <= 0.0
		):
			_activate_barrier_pulse()
			_slide_tap_window = 0.0
			_start_slide()
		else:
			_start_slide()
			if _has_encore_torso and not _is_teto:
				_slide_tap_window = DOUBLE_SLIDE_WINDOW

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

	# Jump / wall-jump (wall coyote helps touch timing)
	if _jump_buffer > 0.0:
		if _coyote > 0.0 and not _is_sliding:
			_do_jump()
		elif (on_wall or _wall_coyote > 0.0) and not on_floor and not _is_sliding:
			_do_wall_jump(wall_dir if wall_dir != 0 else _last_wall_dir)

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


func get_owned_weapons() -> Array:
	## Snapshot for pause weapon strip / HUD.
	var out: Array = []
	for w in _weapons:
		out.append({
			"id": str(w.get("id", "")),
			"name": str(w.get("name", "")),
			"ammo": int(w.get("ammo", -1)),
			"max_ammo": int(w.get("max_ammo", -1)),
		})
	return out


func select_weapon(weapon_id: String) -> void:
	_select_weapon_by_id(weapon_id)


func cycle_weapon(dir: int) -> void:
	_cycle_weapon(dir)


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



func _ping_ammo_empty() -> void:
	_emit_weapon()
	var hud := get_tree().get_first_node_in_group("hud") if get_tree() else null
	if hud != null and hud.has_method("flash_ammo_empty"):
		hud.flash_ammo_empty()

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
	_load_character_sprites()
	_restore_unlocked_weapons()



func _load_character_sprites() -> void:
	var prefix := "teto" if _is_teto else "miku"
	_tex_idle = load("res://assets/sprites/player/%s_idle.png" % prefix) as Texture2D
	_tex_run = load("res://assets/sprites/player/%s_run.png" % prefix) as Texture2D
	_tex_jump = load("res://assets/sprites/player/%s_jump.png" % prefix) as Texture2D
	_tex_slide = load("res://assets/sprites/player/%s_slide.png" % prefix) as Texture2D
	if visual:
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.centered = true
		visual.position = Vector2(0, -2)
		visual.region_enabled = false
		if _tex_idle:
			visual.texture = _tex_idle
			visual.region_enabled = true
			visual.region_rect = Rect2(0, 0, 16, 32)
		visual.modulate = Color.WHITE
	if _charge_rings.is_empty():
		_charge_rings = ArtKit.make_charge_aura_layers(self)


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
	## Teto: tap = sable (+ Counter Guard con Encore torso).
	## Hold con Flight arms = Sonic Slash al soltar.
	if Input.is_action_just_pressed("attack"):
		# Encore Counter Guard: brief parry window before swing
		if _has_encore_torso and _saber_timer <= 0.0 and _parry_window <= 0.0:
			_parry_window = PARRY_WINDOW
			_pending_saber_after_parry = not _has_flight_arms
		if _has_flight_arms:
			_charging = true
			_charge_time = 0.0
		elif not _has_encore_torso:
			_swing_saber()
	elif _charging and Input.is_action_pressed("attack"):
		_charge_time += get_physics_process_delta_time()
	elif _charging and Input.is_action_just_released("attack"):
		var charged := _has_flight_arms and _charge_time >= SONIC_CHARGE
		_charging = false
		_charge_time = 0.0
		_pending_saber_after_parry = false
		_parry_window = 0.0
		if charged:
			_fire_sonic_slash()
		else:
			_swing_saber()
	elif not Input.is_action_pressed("attack"):
		if _charging:
			_charging = false
			_charge_time = 0.0


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
	var parent_fx := get_parent()
	if parent_fx == null:
		parent_fx = get_tree().current_scene
	ArtKit.spawn_slash_arc(parent_fx, global_position + Vector2(facing * 8.0, -2.0), facing)
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
		saber_visual.color = Color(0.95, 0.55, 0.65, 0.85)


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
			var applied = target.take_damage(SABER_DAMAGE)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, applied != false)


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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_ping_ammo_empty()
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
		_prev_charge_lv = 1
	elif _charging and Input.is_action_pressed("attack"):
		_charge_time += delta
		var lv_now := _charge_level_from_time(_charge_time)
		if lv_now > _prev_charge_lv:
			if AudioManager:
				if lv_now >= 3:
					AudioManager.play_sfx("charge_full")
				else:
					AudioManager.play_sfx("charge_tick")
			_prev_charge_lv = lv_now
	elif _charging and Input.is_action_just_released("attack"):
		_fire_buster(_charge_level_from_time(_charge_time))
		_charging = false
		_charge_time = 0.0
		_prev_charge_lv = 0
	elif not Input.is_action_pressed("attack"):
		_charging = false
		_charge_time = 0.0
		_prev_charge_lv = 0


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
	var muzzle_pos := global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	shot.global_position = muzzle_pos
	ArtKit.spawn_muzzle_flash(parent_node, muzzle_pos, facing)
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
	_barrier_cd = maxf(_barrier_cd - delta, 0.0)
	_slide_tap_window = maxf(_slide_tap_window - delta, 0.0)
	if _barrier_timer > 0.0:
		_barrier_timer = maxf(_barrier_timer - delta, 0.0)
		if _barrier_timer <= 0.0:
			_end_barrier_pulse()
	if _parry_window > 0.0:
		_parry_window = maxf(_parry_window - delta, 0.0)
		if _parry_window <= 0.0 and _pending_saber_after_parry:
			_pending_saber_after_parry = false
			_swing_saber()
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_checkpoint_flash = maxf(_checkpoint_flash - delta, 0.0)
	_respawn_fade = maxf(_respawn_fade - delta, 0.0)
	if _death_veil != null and is_instance_valid(_death_veil):
		var a := 0.0 if _respawn_fade <= 0.0 else clampf(_respawn_fade / RESPAWN_FADE, 0.0, 1.0) * 0.55
		_death_veil.color = Color(0, 0, 0, a)
	if _is_sliding:
		_slide_timer -= delta
		if is_on_floor():
			_slide_air_timer = 0.0
		else:
			_slide_air_timer += delta
		if _slide_timer <= 0.0 or _slide_air_timer > SLIDE_AIR_GRACE:
			_end_slide()


func _can_slide(on_floor: bool) -> bool:
	return on_floor and not _is_sliding and _slide_cd <= 0.0


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = SLIDE_DURATION
	_slide_air_timer = 0.0
	_slide_buffer = 0.0
	if AudioManager:
		AudioManager.play_sfx("slide")
	# Encore Guard: legs = longer slide i-frames; torso = hyper armor
	_invuln = INVULN_SLIDE
	if _has_encore_legs:
		_invuln = 0.30
	if _has_encore_torso:
		_invuln = maxf(_invuln, 0.38)
	_apply_slide_shape()
	velocity.x = facing * SLIDE_SPEED
	velocity.y = 0.0
	# slide dust
	var parent_sl := get_parent()
	if parent_sl:
		ArtKit.spawn_dust_puff(parent_sl, global_position + Vector2(-facing * 6.0, 12), facing, 0.7)


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
	_spawn_jump_dust()
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
	_wall_coyote = 0.0
	_jump_buffer = 0.0
	if AudioManager:
		AudioManager.play_sfx("wall_jump")
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
	if visual:
		visual.position = Vector2(0, -2)
		visual.scale = Vector2.ONE


func _apply_slide_shape() -> void:
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SLIDE_SIZE
	collision.position = SLIDE_OFFSET
	if visual:
		visual.position = Vector2(0, 4)
		visual.scale = Vector2.ONE


func _update_visual() -> void:
	# Pixel sprite: flip_h, pose frames, modulate flash. Collision untouched.
	if visual == null:
		return
	_anim_time += 1.0 / 60.0
	visual.flip_h = facing < 0

	var moving := absf(velocity.x) > 12.0
	if _is_sliding and _tex_slide:
		visual.region_enabled = false
		visual.texture = _tex_slide
		visual.position = Vector2(0, 4)
	elif not is_on_floor() and _tex_jump:
		visual.texture = _tex_jump
		visual.region_enabled = true
		var jf := 0 if velocity.y < -40.0 else 1
		visual.region_rect = Rect2(jf * 16, 0, 16, 32)
		visual.position = Vector2(0, -2)
	elif moving and is_on_floor() and _tex_run:
		visual.texture = _tex_run
		visual.region_enabled = true
		_run_frame = int(_anim_time * 12.0) % ArtKit.RUN_FRAMES
		visual.region_rect = Rect2(_run_frame * 16, 0, 16, 32)
		visual.position = Vector2(0, -2)
	elif _tex_idle:
		visual.texture = _tex_idle
		visual.region_enabled = true
		_idle_frame = int(_anim_time * 2.0) % 2
		visual.region_rect = Rect2(_idle_frame * 16, 0, 16, 32)
		visual.position = Vector2(0, -2)

	var base_mod := Color.WHITE
	if not is_on_floor() and _is_on_wall_solid() and velocity.y > 0.0:
		base_mod = Color(1.1, 1.1, 1.15, 1.0)
	elif _is_sliding:
		base_mod = Color(0.9, 0.9, 0.95, 1.0)
	elif _saber_timer > 0.0:
		base_mod = Color(1.15, 1.05, 1.05, 1.0)

	# Aura de carga: Buster (Miku) o Sonic Slash (Teto + Flight arms)
	var lv := 0
	if get_weapon_id() == WEAPON_BUSTER and _charging:
		lv = _charge_level_from_time(_charge_time)
	elif get_weapon_id() == WEAPON_SABER and _charging and _has_flight_arms:
		lv = 3 if _charge_time >= SONIC_CHARGE else (2 if _charge_time >= 0.2 else 0)
	if charge_aura:
		# Clearer charge read on phone: show early (pre-lv2) aura + bigger pulses at lv2+
		if lv >= 1 or (_charging and _charge_time > 0.10 and (get_weapon_id() == WEAPON_BUSTER or get_weapon_id() == WEAPON_SABER)):
			charge_aura.visible = true
			var aura_sz := Vector2(18, 32)
			if lv >= 4:
				aura_sz = Vector2(30, 46)
			elif lv >= 3:
				aura_sz = Vector2(28, 44)
			elif lv >= 2:
				aura_sz = Vector2(24, 40)
			charge_aura.size = aura_sz
			charge_aura.position = Vector2(-aura_sz.x * 0.5, -24)
			if lv >= 4:
				var pulse4 := 0.7 + 0.3 * absf(sin(_charge_time * 18.0))
				charge_aura.color = Color(0.9, 0.4, 1.0, pulse4)
				base_mod = Color(1.1, 0.95, 1.25, 1.0)
			elif lv >= 3:
				var pulse := 0.65 + 0.35 * absf(sin(_charge_time * 14.0))
				charge_aura.color = Color(1.0, 0.92, 0.25, pulse)
				base_mod = Color(1.15, 1.12, 0.8, 1.0)
			elif lv >= 2:
				charge_aura.color = Color(0.3, 0.85, 1.0, 0.55 + 0.35 * absf(sin(_charge_time * 10.0)))
				base_mod = Color(0.85, 1.1, 1.2, 1.0)
			else:
				# Pre-threshold / early charge hint (reads on dark stages)
				charge_aura.color = Color(0.45, 0.9, 1.0, 0.28 + 0.22 * absf(sin(_charge_time * 9.0)))
				base_mod = Color(0.88, 1.08, 1.18, 1.0)
		else:
			charge_aura.visible = false
			if get_weapon_id() == WEAPON_BEAT_BLAZE:
				base_mod = Color(1.15, 0.9, 0.75, 1.0)
			elif get_weapon_id() == WEAPON_NEON_ARC:
				base_mod = Color(1.1, 1.1, 0.75, 1.0)

	if _is_hovering:
		base_mod = base_mod.lerp(Color(0.85, 1.05, 1.2, 1.0), 0.35)
	if _barrier_timer > 0.0:
		base_mod = base_mod.lerp(Color(0.55, 0.85, 1.0, 1.0), 0.45)
	if _parry_window > 0.0:
		base_mod = base_mod.lerp(Color(1.0, 0.75, 0.35, 1.0), 0.5)
	_update_charge_rings(lv)
	_update_thruster()
	_update_barrier_visuals()

	# Hurt flash: strong red/white pulses so damage reads clearly on phone screens
	if _hurt_flash > 0.0:
		var pulse := fmod(_hurt_flash * 18.0, 1.0)
		if pulse < 0.5:
			base_mod = Color(1.55, 0.28, 0.32, 1.0)
		else:
			base_mod = Color(1.35, 1.35, 1.35, 1.0)
	elif _checkpoint_flash > 0.0:
		# Soft cyan ping — checkpoint updated (not a hit)
		var cp := fmod(_checkpoint_flash * 14.0, 1.0)
		base_mod = Color(0.55, 1.15, 1.3, 1.0) if cp < 0.5 else Color(0.9, 1.05, 1.15, 1.0)
	elif _invuln > 0.0:
		# Remaining i-frames: alpha blink
		base_mod.a = 0.4 if fmod(_invuln, 0.08) < 0.04 else 1.0
	else:
		base_mod.a = 1.0
	visual.modulate = base_mod




func apply_touch_camera_feel() -> void:
	## Bias view upward so the player sits above the on-screen touch cluster.
	if camera == null:
		return
	camera.offset = Vector2(0, -22)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.22
	camera.drag_right_margin = 0.22
	camera.drag_top_margin = 0.18
	camera.drag_bottom_margin = 0.45


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
	# Counter Guard: timed parry → counter slash, no damage
	if _parry_window > 0.0 and _is_teto and _has_encore_torso:
		_trigger_counter_guard()
		return
	# Barrier Pulse absorbs hits while active
	if _barrier_timer > 0.0:
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
	_hurt_flash = HURT_FLASH
	# Cancel charge on hit
	_charging = false
	_charge_time = 0.0
	velocity = Vector2(-facing * 90.0, -130.0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_respawn()


func _respawn() -> void:
	## Instant tele + short veil — no long death wait.
	hp = max_hp
	_invuln = RESPAWN_INVULN
	_hurt_flash = 0.0
	_respawn_fade = RESPAWN_FADE
	_is_sliding = false
	_slide_timer = 0.0
	_charging = false
	_charge_time = 0.0
	_saber_timer = 0.0
	_wall_lock = 0.0
	_apply_stand_shape()
	velocity = Vector2.ZERO
	global_position = _spawn_pos
	_ensure_death_veil()
	hp_changed.emit(hp, max_hp)



func _spawn_jump_dust() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	ArtKit.spawn_dust_puff(parent_node, global_position + Vector2(0, 12), facing)


func _spawn_land_dust() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	ArtKit.spawn_dust_puff(parent_node, global_position + Vector2(0, 12), facing, 0.85)


func _ensure_death_veil() -> void:
	if _death_veil != null and is_instance_valid(_death_veil):
		_death_veil.color = Color(0, 0, 0, 0.55)
		return
	var layer := CanvasLayer.new()
	layer.layer = 90
	layer.name = "DeathVeilLayer"
	add_child(layer)
	_death_veil = ColorRect.new()
	_death_veil.name = "DeathVeil"
	_death_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_veil.color = Color(0, 0, 0, 0.55)
	_death_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_death_veil)


func set_spawn_pos(pos: Vector2) -> void:
	var prev := _spawn_pos
	_spawn_pos = pos
	# Checkpoint feel: only ping after the level has started and spawn moved meaningfully
	if prev != Vector2.ZERO and prev.distance_to(pos) > 40.0 and _alive:
		_checkpoint_flash = CHECKPOINT_FLASH
		if AudioManager:
			AudioManager.play_sfx("pickup")


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
	_has_flight_head = false
	_has_full_flight = false
	_has_encore_torso = false
	_has_encore_legs = false
	_has_encore_head = false
	var gs := _game_state()
	if gs != null and gs.has_method("has_flight_torso_equipped"):
		_has_flight_torso = bool(gs.has_flight_torso_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_flight_torso = bool(gs.is_armor_equipped("flight", "torso"))
	if gs != null and gs.has_method("has_flight_arms_equipped"):
		_has_flight_arms = bool(gs.has_flight_arms_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_flight_arms = bool(gs.is_armor_equipped("flight", "arms"))
	if gs != null and gs.has_method("has_flight_head_equipped"):
		_has_flight_head = bool(gs.has_flight_head_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_flight_head = bool(gs.is_armor_equipped("flight", "head"))
	if gs != null and gs.has_method("has_full_flight_equipped"):
		_has_full_flight = bool(gs.has_full_flight_equipped())
	else:
		_has_full_flight = _has_flight_torso and _has_flight_arms and _has_flight_head
	if gs != null and gs.has_method("has_encore_torso_equipped"):
		_has_encore_torso = bool(gs.has_encore_torso_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_encore_torso = bool(gs.is_armor_equipped("encore", "torso"))
	if gs != null and gs.has_method("has_encore_legs_equipped"):
		_has_encore_legs = bool(gs.has_encore_legs_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_encore_legs = bool(gs.is_armor_equipped("encore", "legs"))
	if gs != null and gs.has_method("has_encore_head_equipped"):
		_has_encore_head = bool(gs.has_encore_head_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		_has_encore_head = bool(gs.is_armor_equipped("encore", "head"))
	# Cap fuel if set bonus lost mid-air
	_hover_fuel = minf(_hover_fuel, _hover_max())


func on_armor_pickup(set_id: String, piece_id: String, _display_name: String = "") -> void:
	## Llamado por ArmorPickup tras grant en GameState.
	_sync_armor_from_state()
	if set_id == "flight" and piece_id == "torso":
		_hover_fuel = _hover_max()
		_hover_cd = 0.0
		print("Player: Stage Flight torso equipado — hover listo")
	elif set_id == "flight" and piece_id == "arms":
		print("Player: Stage Flight brazos — Miku Nv4 / Teto Sonic Slash")
	elif set_id == "flight" and piece_id == "head":
		print("Player: Stage Flight casco — radar / menos oscuridad")
	elif set_id == "encore" and piece_id == "torso":
		print("Player: Encore Guard torso — defensa + Barrier/Counter")
	elif set_id == "encore" and piece_id == "legs":
		print("Player: Encore Guard piernas — más i-frames en slide")
	elif set_id == "encore" and piece_id == "head":
		print("Player: Encore Guard casco — revelación de debilidades")
	if _has_full_flight:
		print("Player: Stage Flight completo — hover prolongado")


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
	var mx := _hover_max()
	if mx <= 0.0:
		return 0.0
	return clampf(_hover_fuel / mx, 0.0, 1.0)


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


func _hover_max() -> float:
	return HOVER_DURATION_FULL if _has_full_flight else HOVER_DURATION


func has_full_flight() -> bool:
	return _has_full_flight


func has_flight_head() -> bool:
	return _has_flight_head


func has_encore_head() -> bool:
	return _has_encore_head


func is_barrier_active() -> bool:
	return _barrier_timer > 0.0


func is_parrying() -> bool:
	return _parry_window > 0.0


func try_block_projectile(shot: Node) -> bool:
	## Barrera / Counter absorben proyectiles enemigos. Devuelve true si bloqueó.
	if shot == null:
		return false
	if _barrier_timer > 0.0:
		_reflect_enemy_shot(shot)
		return true
	if _parry_window > 0.0 and _is_teto and _has_encore_torso:
		_trigger_counter_guard()
		return true
	return false


func _activate_barrier_pulse() -> void:
	## Miku + Encore torso: escudo breve que refleja proyectiles chicos.
	if _is_teto or not _has_encore_torso:
		return
	if _barrier_cd > 0.0 or _barrier_timer > 0.0:
		return
	_barrier_timer = BARRIER_DURATION
	_barrier_cd = BARRIER_COOLDOWN
	_invuln = maxf(_invuln, BARRIER_DURATION)
	if AudioManager:
		AudioManager.play_sfx("shoot", 0.75)
	print("Player: Barrier Pulse")


func _end_barrier_pulse() -> void:
	_barrier_timer = 0.0


func _reflect_enemy_shot(shot: Node) -> void:
	## Absorbe proyectil enemigo y dispara un buster Nv1 de rebote (stub reflect).
	## Caller (enemy shot) is responsible for queue_free on the incoming shot.
	if shot == null or not is_instance_valid(shot):
		return
	var origin := global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot is Node2D:
		origin = (shot as Node2D).global_position
	var bounce: Area2D = BusterShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	if parent_node == null:
		return
	parent_node.add_child(bounce)
	bounce.global_position = origin
	if bounce.has_method("setup"):
		bounce.setup(facing, 1)


func _trigger_counter_guard() -> void:
	## Teto + Encore: parry exitoso → i-frames + slash potenciado + dash corto.
	_parry_window = 0.0
	_pending_saber_after_parry = false
	_charging = false
	_charge_time = 0.0
	_invuln = maxf(_invuln, 0.35)
	velocity.x = facing * 120.0
	velocity.y = minf(velocity.y, -40.0)
	_swing_saber_counter()
	if AudioManager:
		AudioManager.play_sfx("shoot", 1.15)
	print("Player: Counter Guard!")


func _swing_saber_counter() -> void:
	## Como _swing_saber pero daño COUNTER_DAMAGE y fuerza re-swing.
	if saber_hitbox == null:
		return
	_saber_hit_ids.clear()
	_saber_timer = SABER_DURATION * 1.25
	_saber_cd = SABER_COOLDOWN * 0.85
	_position_saber()
	saber_hitbox.monitoring = true
	if saber_shape:
		saber_shape.disabled = false
	if saber_visual:
		saber_visual.visible = true
		saber_visual.color = Color(1.0, 0.85, 0.3, 0.9)
	for a in saber_hitbox.get_overlapping_areas():
		_saber_try_hit_counter(a)
	for b in saber_hitbox.get_overlapping_bodies():
		_saber_try_hit_counter(b)


func _saber_try_hit_counter(target: Node) -> void:
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
			target.take_damage(COUNTER_DAMAGE)


func _fire_sonic_slash() -> void:
	## Teto + Flight arms: onda de corte a media distancia.
	if not _has_flight_arms:
		return
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		_swing_saber()
		return
	if AudioManager:
		AudioManager.play_sfx("shoot", 0.85)
	var shot: Area2D = SonicSlashShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * (SHOT_SPAWN_X + 6.0), SHOT_SPAWN_Y)
	ArtKit.spawn_slash_arc(parent_node, shot.global_position, facing)
	if shot.has_method("setup"):
		shot.setup(facing)
	print("Player: Sonic Slash")


func _ensure_barrier_visuals() -> void:
	if _barrier_visual == null or not is_instance_valid(_barrier_visual):
		_barrier_visual = ColorRect.new()
		_barrier_visual.name = "BarrierPulseVisual"
		_barrier_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_barrier_visual.visible = false
		_barrier_visual.z_index = 2
		_barrier_visual.size = Vector2(28, 36)
		_barrier_visual.color = Color(0.4, 0.8, 1.0, 0.35)
		add_child(_barrier_visual)
	if _parry_visual == null or not is_instance_valid(_parry_visual):
		_parry_visual = ColorRect.new()
		_parry_visual.name = "ParryGuardVisual"
		_parry_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parry_visual.visible = false
		_parry_visual.z_index = 2
		_parry_visual.size = Vector2(18, 24)
		_parry_visual.color = Color(1.0, 0.8, 0.3, 0.45)
		add_child(_parry_visual)


func _update_barrier_visuals() -> void:
	if _barrier_visual:
		if _barrier_timer > 0.0:
			_barrier_visual.visible = true
			var pulse := 0.25 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.025))
			_barrier_visual.color = Color(0.35, 0.85, 1.0, pulse)
			_barrier_visual.size = Vector2(30, 38)
			_barrier_visual.position = Vector2(-15, -22)
		else:
			_barrier_visual.visible = false
	if _parry_visual:
		if _parry_window > 0.0:
			_parry_visual.visible = true
			var ox := 10.0 * float(facing)
			_parry_visual.position = Vector2(ox - 9.0, -18)
			_parry_visual.color = Color(1.0, 0.82, 0.3, 0.35 + 0.3 * absf(sin(Time.get_ticks_msec() * 0.04)))
		else:
			_parry_visual.visible = false


func _update_charge_rings(lv: int) -> void:
	var inner: Sprite2D = _charge_rings.get("inner") as Sprite2D
	var outer: Sprite2D = _charge_rings.get("outer") as Sprite2D
	if inner == null and outer == null:
		return
	var show_rings := lv >= 1
	if inner:
		inner.visible = show_rings
		if show_rings:
			inner.rotation = _anim_time * 4.0
			if lv >= 2:
				inner.modulate = Color(0.5, 0.85, 1.0, 0.65 + 0.3 * absf(sin(_anim_time * 8.0)))
				inner.scale = Vector2(0.9, 1.0) if lv == 2 else Vector2(1.05, 1.15)
			else:
				inner.modulate = Color(0.55, 0.9, 1.0, 0.35 + 0.2 * absf(sin(_anim_time * 7.0)))
				inner.scale = Vector2(0.7, 0.8)
	if outer:
		outer.visible = lv >= 3
		if outer.visible:
			outer.rotation = -_anim_time * 3.0
			if lv >= 4:
				outer.modulate = Color(0.9, 0.45, 1.0, 0.65 + 0.3 * absf(sin(_anim_time * 14.0)))
			else:
				outer.modulate = Color(1.0, 0.9, 0.35, 0.6 + 0.3 * absf(sin(_anim_time * 10.0)))
			outer.scale = Vector2(1.15, 1.25)
