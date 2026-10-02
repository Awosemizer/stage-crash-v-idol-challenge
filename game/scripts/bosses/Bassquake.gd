extends CharacterBody2D
## Bassquake — jefe subwoofer industrial. HP 28, contacto 4.
## Patrones: idle, quake stomp (ondas), salto pesado.
## Debilidad: Freeze Sample ×3 (grupo weak_to_freeze_sample).

signal died
signal hp_changed(current: int, maximum: int)
signal quake_pulse(intensity: float)

const HP_MAX := 28
const CONTACT_DAMAGE := 4
const GRAVITY := 640.0
const JUMP_V := -240.0
const STOMP_V := 420.0
const BEAT_NORMAL := 0.78
const BEAT_RAGE := 0.42
const HIT_FLASH := 0.12
const INVULN_ON_HIT := 0.08
const TELEGRAPH := 0.45

enum State { IDLE, TELEGRAPH, STOMP, JUMP, DEAD }

const QuakeWaveScene := preload("res://scenes/hazards/QuakeWave.tscn")

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

@onready var visual: ColorRect = $Visual
var _sprite_art: Sprite2D
@onready var trim: ColorRect = $Trim
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel
@onready var telegraph: ColorRect = $Telegraph


func _ready() -> void:
	_sprite_art = ArtKit.skin_boss_visual(visual, "bassquake")
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("weak_to_freeze_sample")
	visual.color = Color(0.72, 0.48, 0.22, 1.0)
	_sync_sprite_art(Color(0.72, 0.48, 0.22, 1.0))
	if trim:
		trim.color = Color(0.95, 0.75, 0.3, 0.9)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "BASSQUAKE"
	if telegraph:
		telegraph.visible = false
	_refresh_hp_bar()
	set_physics_process(true)
	_active = false


func activate() -> void:
	if GameState and GameState.has_method("begin_boss_fight_track"):
		GameState.begin_boss_fight_track()
	_active = true
	if AudioManager and AudioManager.has_method("play_boss_intro"):
		AudioManager.play_boss_intro()
	_beat = 0.35
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
			State.TELEGRAPH:
				_tick_telegraph(delta)
			State.STOMP:
				_tick_stomp(delta)
			State.JUMP:
				_tick_jump(delta)
			State.DEAD:
				pass

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 380.0)
	else:
		if _state != State.JUMP and _state != State.STOMP:
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
	match _phase % 3:
		0, 1:
			_start_telegraph()
		2:
			_start_jump()
	_phase += 1


func _start_telegraph() -> void:
	_state = State.TELEGRAPH
	_telegraph_t = TELEGRAPH if hp > HP_MAX / 2 else TELEGRAPH * 0.7
	velocity.x = 0.0
	if telegraph:
		telegraph.visible = true
		telegraph.color = Color(0.95, 0.55, 0.15, 0.55)


func _tick_telegraph(delta: float) -> void:
	_telegraph_t -= delta
	if telegraph:
		telegraph.color.a = 0.35 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.025))
	if _telegraph_t <= 0.0:
		_do_stomp()


func _do_stomp() -> void:
	_state = State.STOMP
	velocity.x = 0.0
	velocity.y = STOMP_V
	if telegraph:
		telegraph.visible = false


func _tick_stomp(_delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		_spawn_quake_waves()
		quake_pulse.emit(1.0 if hp <= HP_MAX / 2 else 0.7)
		velocity.x = 0.0
		_state = State.IDLE
		_beat = _beat_interval() * 0.45


func _start_jump() -> void:
	_state = State.JUMP
	_update_facing()
	velocity.y = JUMP_V
	velocity.x = float(_facing) * 85.0


func _tick_jump(_delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		_spawn_quake_waves()
		quake_pulse.emit(0.55)
		velocity.x = 0.0
		_state = State.IDLE
		_beat = _beat_interval() * 0.4


func _spawn_quake_waves() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	var count := 2 if hp > HP_MAX / 2 else 3
	for i in count:
		var wave: Area2D = QuakeWaveScene.instantiate()
		parent_node.add_child(wave)
		wave.global_position = global_position + Vector2(0, -2)
		var dir := _facing if i % 2 == 0 else -_facing
		if i >= 2:
			dir = _facing
		var spd := 100.0 + float(i) * 25.0
		if wave.has_method("setup"):
			wave.setup(dir, spd, 3)


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
	_sync_sprite_art(Color(1, 1, 1, 1))
	await get_tree().create_timer(0.45).timeout
	queue_free()


func _refresh_hp_bar() -> void:
	if hp_bar_bg == null or hp_bar_fill == null:
		return
	var ratio := 0.0 if HP_MAX <= 0 else float(hp) / float(HP_MAX)
	hp_bar_fill.size.x = maxf(hp_bar_bg.size.x * ratio, 0.0)
	if ratio > 0.5:
		hp_bar_fill.color = Color(0.85, 0.55, 0.2, 1.0)
	else:
		hp_bar_fill.color = Color(0.95, 0.35, 0.2, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.72, 0.48, 0.22, 1.0)
	if hp <= HP_MAX / 2:
		base = Color(0.9, 0.4, 0.15, 1.0)
	if _state == State.TELEGRAPH:
		base = Color(0.95, 0.7, 0.25, 1.0)
	elif _state == State.STOMP:
		base = Color(0.55, 0.3, 0.12, 1.0)
	elif _state == State.JUMP:
		base = Color(0.8, 0.6, 0.3, 1.0)
	if _flash > 0.0:
		visual.color = Color(1, 1, 1, 1)
		_sync_sprite_art(Color(1, 1, 1, 1))
	else:
		visual.color = base
		_sync_sprite_art(base)
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

func _sync_sprite_art(col: Color) -> void:
	var spr := get_node_or_null("SpriteArt") as Sprite2D
	if spr == null:
		return
	# Attack/tell pose when not idle (IDLE==0 across bosses)
	var pose := 0 if int(_state) == 0 else 1
	ArtKit.set_boss_pose(spr, pose)
	# White/near-white = hit flash
	if col.r >= 0.95 and col.g >= 0.95 and col.b >= 0.95:
		spr.modulate = Color(2.2, 2.2, 2.2, 1.0)
	else:
		# Subtle tint from legacy color toward white sprite
		spr.modulate = Color(0.85 + col.r * 0.2, 0.85 + col.g * 0.2, 0.85 + col.b * 0.2, col.a)

