extends CharacterBody2D
## Glitch Ice — jefe estudio congelado / frame glitch. HP 28, contacto 4.
## Patrones: idle, hielo glitch shots, tele-dash (frame skip).
## Debilidad: Neon Arc ×3 (grupo weak_to_neon_arc).

signal died
signal hp_changed(current: int, maximum: int)

const HP_MAX := 28
const CONTACT_DAMAGE := 4
const GRAVITY := 520.0
const TELE_H := 150.0
const BEAT_NORMAL := 0.75
const BEAT_RAGE := 0.42
const HIT_FLASH := 0.12
const INVULN_ON_HIT := 0.08

enum State { IDLE, SHOOT, TELE, DEAD }

const IceGlitchShotScene := preload("res://scenes/combat/IceGlitchShot.tscn")

var hp := HP_MAX
var _state: State = State.IDLE
var _beat := 0.0
var _phase := 0
var _flash := 0.0
var _invuln := 0.0
var _alive := true
var _active := false
var _facing := -1
var _tele_t := 0.0

@onready var visual: ColorRect = $Visual
@onready var trim: ColorRect = $Trim
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("weak_to_neon_arc")
	visual.color = Color(0.55, 0.85, 1.0, 1.0)
	if trim:
		trim.color = Color(0.95, 0.55, 1.0, 0.9)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "GLITCH ICE"
	_refresh_hp_bar()
	set_physics_process(true)
	_active = false


func activate() -> void:
	if GameState and GameState.has_method("begin_boss_fight_track"):
		GameState.begin_boss_fight_track()
	_active = true
	_beat = 0.4
	_state = State.IDLE
	_phase = 0


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_flash = maxf(_flash - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_update_facing()

	if _active:
		match _state:
			State.IDLE:
				_tick_idle(delta)
			State.SHOOT:
				pass
			State.TELE:
				_tick_tele(delta)
			State.DEAD:
				pass

	if _state != State.TELE:
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
		else:
			velocity.y = 0.0

	move_and_slide()
	_refresh_look()
	_check_contact_overlap()


func _beat_interval() -> float:
	return BEAT_RAGE if hp <= HP_MAX / 2 else BEAT_NORMAL


func _tick_idle(delta: float) -> void:
	_beat -= delta
	velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
	if _beat > 0.0:
		return
	match _phase % 3:
		0, 1:
			_do_shoot()
		2:
			_start_tele()
	_phase += 1


func _do_shoot() -> void:
	_state = State.SHOOT
	_update_facing()
	var count := 4 if hp <= HP_MAX / 2 else 3
	for i in count:
		var ang := deg_to_rad(-18.0 + i * 12.0)
		var dir := Vector2(float(_facing), 0.0).rotated(ang)
		_spawn_ice(dir)
	_state = State.IDLE
	_beat = _beat_interval() * 0.85


func _start_tele() -> void:
	_state = State.TELE
	_update_facing()
	_tele_t = 0.28
	# Brief vanish then reappear closer to player
	if visual:
		visual.modulate.a = 0.25
	velocity = Vector2.ZERO


func _tick_tele(delta: float) -> void:
	_tele_t -= delta
	if _tele_t > 0.14:
		return
	if _tele_t > 0.0:
		# Mid-tele: snap toward player
		var player := _get_player()
		if player:
			var target_x := player.global_position.x - float(_facing) * 48.0
			global_position.x = move_toward(global_position.x, target_x, TELE_H * delta * 8.0)
		return
	# Land burst
	if visual:
		visual.modulate.a = 1.0
	_spawn_ice(Vector2(-1, 0), 140.0)
	_spawn_ice(Vector2(1, 0), 140.0)
	_spawn_ice(Vector2(0, -1), 110.0)
	_state = State.IDLE
	_beat = _beat_interval() * 0.35


func _spawn_ice(dir: Vector2, spd: float = 120.0) -> void:
	var shot: Area2D = IceGlitchShotScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(_facing * 10.0, -22.0)
	if shot.has_method("setup"):
		shot.setup(dir, spd)


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
		hp_bar_fill.color = Color(0.55, 0.9, 1.0, 1.0)
	else:
		hp_bar_fill.color = Color(0.95, 0.45, 0.85, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.55, 0.85, 1.0, 1.0)
	if hp <= HP_MAX / 2:
		base = Color(0.75, 0.95, 1.0, 1.0)
	if _state == State.TELE:
		base = Color(0.95, 0.55, 1.0, 1.0)
	elif _state == State.SHOOT:
		base = Color(0.7, 1.0, 1.0, 1.0)
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
