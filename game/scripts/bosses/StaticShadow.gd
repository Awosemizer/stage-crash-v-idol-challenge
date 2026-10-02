extends CharacterBody2D
## Static Shadow — jefe backstage / ruido blanco. HP 28, contacto 4.
## Ataques de zona estática. Debilidad: Petal Chorus ×3 (weak_to_petal_chorus).

signal died
signal hp_changed(current: int, maximum: int)

const HP_MAX := 28
const CONTACT_DAMAGE := 4
const GRAVITY := 560.0
const DASH_H := 120.0
const BEAT_NORMAL := 0.85
const BEAT_RAGE := 0.48
const HIT_FLASH := 0.12
const INVULN_ON_HIT := 0.08
const TELEGRAPH := 0.32

enum State { IDLE, TELEGRAPH, ZONE, DASH, BURST, DEAD }

const StaticZoneScene := preload("res://scenes/hazards/StaticZone.tscn")

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

@onready var visual: ColorRect = $Visual
@onready var trim: ColorRect = $Trim
@onready var static_fx: ColorRect = $StaticFx
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel
@onready var telegraph: ColorRect = $Telegraph


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("weak_to_petal_chorus")
	visual.color = Color(0.35, 0.3, 0.45, 1.0)
	if trim:
		trim.color = Color(0.75, 0.7, 0.9, 0.85)
	if static_fx:
		static_fx.color = Color(0.95, 0.95, 1.0, 0.25)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "STATIC SHADOW"
	if telegraph:
		telegraph.visible = false
	_refresh_hp_bar()
	set_physics_process(true)
	_active = false


func activate() -> void:
	if GameState and GameState.has_method("begin_boss_fight_track"):
		GameState.begin_boss_fight_track()
	_active = true
	_beat = 0.35
	_state = State.IDLE
	_phase = 0


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_flash = maxf(_flash - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_update_facing()
	_flicker_static(delta)

	if _active:
		match _state:
			State.IDLE:
				_tick_idle(delta)
			State.TELEGRAPH:
				_tick_telegraph(delta)
			State.ZONE, State.BURST:
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
			_do_burst()
		3:
			_start_dash()
	_phase += 1


func _start_telegraph() -> void:
	_state = State.TELEGRAPH
	_telegraph_t = TELEGRAPH if hp > HP_MAX / 2 else TELEGRAPH * 0.7
	velocity.x = 0.0
	if telegraph:
		telegraph.visible = true
		telegraph.color = Color(0.9, 0.85, 1.0, 0.45)


func _tick_telegraph(delta: float) -> void:
	_telegraph_t -= delta
	if telegraph:
		telegraph.color.a = 0.25 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.035))
	if _telegraph_t <= 0.0:
		_do_zone()


func _do_zone() -> void:
	_state = State.ZONE
	if telegraph:
		telegraph.visible = false
	_update_facing()
	# Drop static zones near player and under self
	var player := _get_player()
	var targets: Array[Vector2] = [
		global_position + Vector2(0, -8),
		global_position + Vector2(float(_facing) * 56.0, -8),
	]
	if player:
		targets.append(Vector2(player.global_position.x, global_position.y - 8.0))
	if hp <= HP_MAX / 2:
		targets.append(global_position + Vector2(float(-_facing) * 72.0, -8))
	for pos in targets:
		_spawn_zone(pos, 1.8 if hp > HP_MAX / 2 else 2.2)
	_state = State.IDLE
	_beat = _beat_interval()


func _do_burst() -> void:
	_state = State.BURST
	if telegraph:
		telegraph.visible = false
	# Ring of zones around boss
	for i in range(3 if hp > HP_MAX / 2 else 5):
		var ang := float(i) * TAU / float(3 if hp > HP_MAX / 2 else 5)
		var offset := Vector2(cos(ang), sin(ang) * 0.35) * 48.0
		_spawn_zone(global_position + offset + Vector2(0, -10), 1.4)
	_state = State.IDLE
	_beat = _beat_interval() * 0.7


func _start_dash() -> void:
	_state = State.DASH
	_update_facing()
	_dash_t = 0.32 if hp > HP_MAX / 2 else 0.26
	velocity.x = float(_facing) * DASH_H
	velocity.y = 0.0
	if telegraph:
		telegraph.visible = false


func _tick_dash(delta: float) -> void:
	_dash_t -= delta
	if _dash_t <= 0.0 or is_on_wall():
		velocity.x = 0.0
		_spawn_zone(global_position + Vector2(-40, -8), 1.2)
		_spawn_zone(global_position + Vector2(40, -8), 1.2)
		_state = State.IDLE
		_beat = _beat_interval() * 0.55


func _spawn_zone(pos: Vector2, life: float = 1.8) -> void:
	var zone: Area2D = StaticZoneScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(zone)
	zone.global_position = pos
	if zone.has_method("setup"):
		zone.setup(life, 3 if hp > HP_MAX / 2 else 4)


func _flicker_static(_delta: float) -> void:
	if static_fx == null:
		return
	var rate := 0.04 if _active else 0.02
	static_fx.color.a = 0.1 + 0.35 * absf(sin(Time.get_ticks_msec() * rate))
	static_fx.visible = int(Time.get_ticks_msec() / 40) % 4 != 0


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
		hp_bar_fill.color = Color(0.65, 0.55, 0.9, 1.0)
	else:
		hp_bar_fill.color = Color(0.95, 0.4, 0.45, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.35, 0.3, 0.45, 1.0)
	if hp <= HP_MAX / 2:
		base = Color(0.5, 0.28, 0.55, 1.0)
	if _state == State.TELEGRAPH:
		base = Color(0.7, 0.65, 0.9, 1.0)
	elif _state == State.DASH:
		base = Color(0.25, 0.22, 0.35, 1.0)
	elif _state == State.ZONE or _state == State.BURST:
		base = Color(0.55, 0.5, 0.7, 1.0)
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
