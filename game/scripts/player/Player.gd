extends CharacterBody2D
## Player controller — Mega Man X–style feel for Stage Crash: V-Idol Challenge.
## Input: reads InputMap actions only (move_left/right, jump, slide, attack).
## Touch overlay + joypad press those same actions — do not hardcode keys here.
## GDD refs (px/frame @ 60fps, tile 16px): run 1.5, jump 4.5, grav 0.25,
## wall-jump H 2.5, slide 12 frames. Wall-jump always available.
## Buster: tap = Nv1 (1 dmg); hold → Nv2 / Nv3 con aura en ColorRect.

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
const MAX_SHOTS := 3
const SHOT_SPAWN_X := 12.0
const SHOT_SPAWN_Y := -8.0

# Collision sizes (standing ~36px tall, slide crouched)
const STAND_SIZE := Vector2(14, 28)
const STAND_OFFSET := Vector2(0, -2)
const SLIDE_SIZE := Vector2(22, 14)
const SLIDE_OFFSET := Vector2(0, 5)

const BusterShotScene := preload("res://scenes/combat/BusterShot.tscn")

signal hp_changed(current: int, maximum: int)

@onready var visual: ColorRect = $Visual
@onready var charge_aura: ColorRect = $ChargeAura
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var wall_ray_l: RayCast2D = $WallRayL
@onready var wall_ray_r: RayCast2D = $WallRayR
@onready var camera: Camera2D = $Camera2D

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


func _ready() -> void:
	add_to_group("player")
	_spawn_pos = global_position
	_apply_stand_shape()
	# Cyan placeholder = Miku palette; swap later for sprites
	visual.color = Color(0.2, 0.9, 0.95, 1.0)
	if charge_aura:
		charge_aura.visible = false
	hp_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_tick_timers(delta)

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

	# Gravity / wall slide
	if not on_floor:
		if on_wall and velocity.y > 0.0 and not _is_sliding:
			velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
		else:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	# Jump cut
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
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
		var target := input_x * RUN_SPEED
		var accel := ACCEL_GROUND if on_floor else ACCEL_AIR
		if absf(input_x) > 0.01:
			velocity.x = move_toward(velocity.x, target, accel * delta)
			facing = 1 if input_x > 0.0 else -1
		else:
			var fric := FRICTION_GROUND if on_floor else ACCEL_AIR * 0.35
			velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# Jump / wall-jump
	if _jump_buffer > 0.0:
		if _coyote > 0.0 and not _is_sliding:
			_do_jump()
		elif on_wall and not on_floor:
			_do_wall_jump(wall_dir)

	_handle_buster(delta)

	move_and_slide()
	_update_visual()
	_check_hazards_and_pits()


func _handle_buster(delta: float) -> void:
	if _is_sliding:
		# Cancel charge while sliding (no fire mid-slide)
		if _charging:
			_charging = false
			_charge_time = 0.0
		return

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
	if t >= CHARGE_LV3:
		return 3
	if t >= CHARGE_LV2:
		return 2
	return 1


func _fire_buster(level: int) -> void:
	var live := get_tree().get_nodes_in_group("player_shots")
	if live.size() >= MAX_SHOTS:
		return
	var shot: Area2D = BusterShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(facing * SHOT_SPAWN_X, SHOT_SPAWN_Y)
	if shot.has_method("setup"):
		shot.setup(facing, level)


func _tick_timers(delta: float) -> void:
	_wall_lock = maxf(_wall_lock - delta, 0.0)
	_slide_cd = maxf(_slide_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	if _is_sliding:
		_slide_timer -= delta
		if _slide_timer <= 0.0 or not is_on_floor():
			_end_slide()


func _can_slide(on_floor: bool) -> bool:
	return on_floor and not _is_sliding and _slide_cd <= 0.0


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = SLIDE_DURATION
	_invuln = INVULN_SLIDE  # stub i-frames (Encore Guard legs later)
	_apply_slide_shape()
	velocity.x = facing * SLIDE_SPEED
	velocity.y = 0.0


func _end_slide() -> void:
	_is_sliding = false
	_slide_cd = SLIDE_COOLDOWN
	_apply_stand_shape()


func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_coyote = 0.0
	_jump_buffer = 0.0
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

	var base_col := Color(0.2, 0.9, 0.95, 1.0)
	if not is_on_floor() and _is_on_wall_solid() and velocity.y > 0.0:
		base_col = Color(0.35, 0.95, 1.0, 1.0)
	elif _is_sliding:
		base_col = Color(0.15, 0.7, 0.85, 1.0)

	# Aura de carga sobre el ColorRect del jugador
	var lv := _charge_level_from_time(_charge_time) if _charging else 0
	if charge_aura:
		if lv >= 2:
			charge_aura.visible = true
			var aura_sz := visual.size + Vector2(6, 6) if lv == 2 else visual.size + Vector2(10, 10)
			charge_aura.size = aura_sz
			charge_aura.position = visual.position - Vector2(3, 3) if lv == 2 else visual.position - Vector2(5, 5)
			if lv >= 3:
				# Parpadeo blanco-dorado Nv3
				var pulse := 0.55 + 0.45 * absf(sin(_charge_time * 12.0))
				charge_aura.color = Color(1.0, 0.92, 0.35, pulse)
				base_col = Color(0.95, 0.95, 0.6, 1.0)
			else:
				charge_aura.color = Color(0.35, 0.75, 1.0, 0.45 + 0.25 * absf(sin(_charge_time * 8.0)))
				base_col = Color(0.45, 0.85, 1.0, 1.0)
		else:
			charge_aura.visible = false
			if _charging and _charge_time > 0.12:
				# Nv1 charging hint: ligero brillo en el cuerpo
				base_col = Color(0.35, 0.95, 1.0, 1.0)

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


func take_damage(amount: int) -> void:
	_take_hit(amount)


func _take_hit(amount: int) -> void:
	if _invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	_invuln = 1.0  # GDD: 1.0 s after hit
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


func is_invulnerable() -> bool:
	return _invuln > 0.0


func get_charge_level() -> int:
	## Para tests / HUD futuro.
	if not _charging:
		return 0
	return _charge_level_from_time(_charge_time)
