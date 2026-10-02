extends CharacterBody2D
## Metronome — jefe fábrica de relojes / tempo. HP 28, contacto 4.
## Ataques a intervalos fijos (tick/tock). Debilidad: Neon Arc ×3 (weak_to_neon_arc).

signal died
signal hp_changed(current: int, maximum: int)
signal tick_pulse(phase: int)

const HP_MAX := 28
const CONTACT_DAMAGE := 4
const GRAVITY := 560.0
const DASH_H := 140.0
const BEAT_NORMAL := 0.65  ## intervalo fijo de ataque
const BEAT_RAGE := 0.38
const HIT_FLASH := 0.12
const INVULN_ON_HIT := 0.08
const TELEGRAPH := 0.28

enum State { IDLE, TELEGRAPH, VOLLEY, DASH, DEAD }

const TempoNeedleScene := preload("res://scenes/combat/TempoNeedle.tscn")

var hp := HP_MAX
var _state: State = State.IDLE
var _beat := 0.0
var _phase := 0
var _flash := 0.0
var _invuln := 0.0
var _alive := true
var _active := false
var _facing := -1
var _telegraph_t := 0.0
var _dash_t := 0.0
var _tick_side := 1

@onready var visual: ColorRect = $Visual
@onready var trim: ColorRect = $Trim
@onready var pendulum: ColorRect = $Pendulum
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel
@onready var telegraph: ColorRect = $Telegraph


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("weak_to_neon_arc")
	visual.color = Color(0.65, 0.7, 0.82, 1.0)
	if trim:
		trim.color = Color(0.9, 0.75, 0.35, 0.9)
	if pendulum:
		pendulum.color = Color(0.55, 0.58, 0.7, 0.95)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "METRONOME"
	if telegraph:
		telegraph.visible = false
	_refresh_hp_bar()
	set_physics_process(true)
	_active = false


func activate() -> void:
	_active = true
	_beat = 0.3
	_state = State.IDLE
	_phase = 0


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_flash = maxf(_flash - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_update_facing()
	_swing_pendulum(delta)

	if _active:
		match _state:
			State.IDLE:
				_tick_idle(delta)
			State.TELEGRAPH:
				_tick_telegraph(delta)
			State.VOLLEY:
				pass
			State.DASH:
				_tick_dash(delta)
			State.DEAD:
				pass

	if _state != State.DASH:
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
		else:
			velocity.y = 0.0

	move_and_slide()
	_refresh_look()
	_check_contact_overlap()


func _beat_interval() -> float:
	return BEAT_RAGE if hp <= HP_MAX / 2 else BEAT_NORMAL


func _tick_idle(delta: float) -> void:
	_beat -= delta
	velocity.x = move_toward(velocity.x, 0.0, 480.0 * delta)
	if _beat > 0.0:
		return
	match _phase % 4:
		0, 1:
			_start_telegraph()
		2:
			_do_volley()
		3:
			_start_dash()
	_phase += 1


func _start_telegraph() -> void:
	_state = State.TELEGRAPH
	_telegraph_t = TELEGRAPH if hp > HP_MAX / 2 else TELEGRAPH * 0.75
	velocity.x = 0.0
	if telegraph:
		telegraph.visible = true
		telegraph.color = Color(0.85, 0.8, 0.4, 0.5)


func _tick_telegraph(delta: float) -> void:
	_telegraph_t -= delta
	if telegraph:
		telegraph.color.a = 0.3 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.03))
	if _telegraph_t <= 0.0:
		_do_volley()


func _do_volley() -> void:
	_state = State.VOLLEY
	if telegraph:
		telegraph.visible = false
	_update_facing()
	_tick_side *= -1
	tick_pulse.emit(_tick_side)
	var count := 4 if hp <= HP_MAX / 2 else 3
	for i in count:
		var ang := deg_to_rad(-18.0 + float(i) * 12.0)
		var dir := Vector2(float(_facing), 0.0).rotated(ang)
		_spawn_needle(dir, 125.0 + float(i) * 12.0)
	# Fixed-interval side needle (tick/tock)
	_spawn_needle(Vector2(float(_tick_side), -0.15), 150.0)
	_state = State.IDLE
	_beat = _beat_interval()


func _start_dash() -> void:
	_state = State.DASH
	_update_facing()
	_dash_t = 0.35 if hp > HP_MAX / 2 else 0.28
	velocity.x = float(_facing) * DASH_H
	velocity.y = 0.0
	if telegraph:
		telegraph.visible = false


func _tick_dash(delta: float) -> void:
	_dash_t -= delta
	if _dash_t <= 0.0 or is_on_wall():
		velocity.x = 0.0
		_spawn_needle(Vector2(-1, -0.4), 110.0)
		_spawn_needle(Vector2(1, -0.4), 110.0)
		_state = State.IDLE
		_beat = _beat_interval() * 0.55


func _spawn_needle(dir: Vector2, spd: float = 130.0) -> void:
	var shot: Area2D = TempoNeedleScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(_facing * 8.0, -24.0)
	if shot.has_method("setup"):
		shot.setup(dir, spd)


func _swing_pendulum(_delta: float) -> void:
	if pendulum == null:
		return
	var amp := 10.0 if _active else 4.0
	var rate := 0.012 if hp > HP_MAX / 2 else 0.02
	pendulum.position.x = sin(Time.get_ticks_msec() * rate) * amp - 2.0


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


func take_damage(amount: int) -> bool:
	if not _alive or not _active:
		return false
	if _invuln > 0.0:
		return false
	hp = maxi(hp - amount, 0)
	if AudioManager:
		AudioManager.play_sfx("boss_hit")
	_flash = HIT_FLASH
	_invuln = INVULN_ON_HIT
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
	if telegraph:
		telegraph.visible = false
	died.emit()
	visual.color = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.45).timeout
	queue_free()


func _refresh_hp_bar() -> void:
	if hp_bar_bg == null or hp_bar_fill == null:
		return
	var ratio := 0.0 if HP_MAX <= 0 else float(hp) / float(HP_MAX)
	hp_bar_fill.size.x = maxf(hp_bar_bg.size.x * ratio, 0.0)
	if ratio > 0.5:
		hp_bar_fill.color = Color(0.7, 0.75, 0.9, 1.0)
	else:
		hp_bar_fill.color = Color(0.95, 0.4, 0.35, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.65, 0.7, 0.82, 1.0)
	if hp <= HP_MAX / 2:
		base = Color(0.75, 0.55, 0.7, 1.0)
	if _state == State.TELEGRAPH:
		base = Color(0.9, 0.85, 0.45, 1.0)
	elif _state == State.DASH:
		base = Color(0.5, 0.55, 0.7, 1.0)
	elif _state == State.VOLLEY:
		base = Color(0.8, 0.82, 0.95, 1.0)
	if _flash > 0.0:
		visual.color = Color(1, 1, 1, 1)
	else:
		visual.color = base
	if trim:
		trim.position.x = (-14.0 if _facing > 0 else 2.0)


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
