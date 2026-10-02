extends CharacterBody2D
## Beatfire Man — jefe piloto (fuego + batería). HP 28, contacto 4.
## Patrones al beat: salto, bolas de fuego, ground pound con telegraph.
## Bajo 50% HP acelera el tempo.
## Debilidad opcional: Freeze Sample ×3 (weak_to_freeze_sample).

signal died
signal hp_changed(current: int, maximum: int)

const HP_MAX := 28
const CONTACT_DAMAGE := 4
const GRAVITY := 900.0
const JUMP_V := -260.0
const JUMP_H := 110.0
const POUND_V := 420.0
const BEAT_NORMAL := 0.78
const BEAT_RAGE := 0.58
const TELEGRAPH := 0.78
const HIT_FLASH := 0.12
const INVULN_ON_HIT := 0.45  # weak hits stay ×3 but can't melt the bar in one second

enum State { IDLE, JUMP, SHOOT, TELEGRAPH, POUND, DEAD }

const FireballScene := preload("res://scenes/combat/Fireball.tscn")

var hp := HP_MAX
var _state: State = State.IDLE
var _beat := 0.0
var _phase := 0  # pattern index in cycle
var _flash := 0.0
var _invuln := 0.0
var _telegraph_t := 0.0
var _alive := true
var _active := false
var _facing := -1
var _contact_grace := 0.0

@onready var visual: ColorRect = $Visual
var _sprite_art: Sprite2D
@onready var drum: ColorRect = $Drum
@onready var telegraph: ColorRect = $Telegraph
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	_sprite_art = ArtKit.skin_boss_visual(visual, "beatfire")
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("weak_to_freeze_sample")  # Freeze Sample ×3 (Glitch Ice)
	visual.color = Color(0.85, 0.25, 0.15, 1.0)
	_sync_sprite_art(Color(0.85, 0.25, 0.15, 1.0))
	if drum:
		drum.color = Color(0.35, 0.12, 0.1, 1.0)
	if telegraph:
		telegraph.visible = false
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "BEATFIRE MAN"
	_refresh_hp_bar()
	set_physics_process(true)
	# Idle until arena activates
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
	_contact_grace = maxf(_contact_grace - delta, 0.0)
	_update_facing()
	_apply_gravity(delta)

	if _active:
		match _state:
			State.IDLE:
				_tick_idle(delta)
			State.JUMP:
				pass  # airborne until land
			State.SHOOT:
				pass  # one-shot then idle
			State.TELEGRAPH:
				_tick_telegraph(delta)
			State.POUND:
				pass
			State.DEAD:
				pass

		if _state == State.JUMP and is_on_floor() and velocity.y >= 0.0:
			velocity.x = 0.0
			_state = State.IDLE
			_beat = _beat_interval() * 0.25
		elif _state == State.POUND and is_on_floor():
			velocity.x = 0.0
			_contact_grace = 0.16
			_spawn_pound_shock()
			_state = State.IDLE
			_beat = _beat_interval() * 0.4
			if telegraph:
				telegraph.visible = false

	move_and_slide()
	_refresh_look()
	_check_contact_overlap()


func _beat_interval() -> float:
	return BEAT_RAGE if hp <= HP_MAX / 2 else BEAT_NORMAL


func _tick_idle(delta: float) -> void:
	_beat -= delta
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if _beat > 0.0:
		return
	# Cycle: jump → shoot → telegraph/pound → repeat
	match _phase % 3:
		0:
			_do_jump()
		1:
			_do_shoot()
		2:
			_start_telegraph()
	_phase += 1


func _do_jump() -> void:
	_state = State.JUMP
	_update_facing()
	velocity.x = _facing * JUMP_H
	velocity.y = JUMP_V
	_beat = _beat_interval()


func _do_shoot() -> void:
	_state = State.SHOOT
	_update_facing()
	var count := 2
	var base := Vector2(float(_facing), 0.0)
	for i in count:
		var ang := deg_to_rad(-12.0 + i * 12.0)
		var dir := base.rotated(ang)
		_spawn_fireball(dir)
	_state = State.IDLE
	_beat = _beat_interval() * 0.85


func _start_telegraph() -> void:
	if AudioManager and AudioManager.has_method("play_telegraph"):
		AudioManager.play_telegraph()
	_state = State.TELEGRAPH
	_telegraph_t = TELEGRAPH if hp > HP_MAX / 2 else TELEGRAPH * 0.82
	if telegraph:
		telegraph.visible = true
		telegraph.color = Color(1.0, 0.35, 0.05, 0.72)
	velocity.x = 0.0


func _tick_telegraph(delta: float) -> void:
	_telegraph_t -= delta
	if telegraph:
		telegraph.color.a = 0.45 + 0.40 * absf(sin(Time.get_ticks_msec() * 0.018))
	if _telegraph_t <= 0.0:
		_do_pound()


func _do_pound() -> void:
	_state = State.POUND
	_contact_grace = 0.10
	velocity.x = 0.0
	velocity.y = POUND_V
	if telegraph:
		telegraph.visible = false


func _spawn_pound_shock() -> void:
	# Two low fireballs outward as shockwave
	_spawn_fireball(Vector2(-1, 0), 180.0)
	_spawn_fireball(Vector2(1, 0), 180.0)


func _spawn_fireball(dir: Vector2, spd: float = 140.0) -> void:
	var fb: Area2D = FireballScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(fb)
	fb.global_position = global_position + Vector2(_facing * 22.0, -16.0)
	if fb.has_method("setup"):
		fb.setup(dir, spd)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 480.0)


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
	# Brief flash then free
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
		hp_bar_fill.color = Color(0.95, 0.45, 0.15, 1.0)
	else:
		hp_bar_fill.color = Color(1.0, 0.2, 0.15, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.85, 0.25, 0.15, 1.0)
	if hp <= HP_MAX / 2:
		base = Color(1.0, 0.15, 0.1, 1.0)
	if _state == State.TELEGRAPH:
		base = Color(1.0, 0.55, 0.1, 1.0)
	elif _state == State.POUND:
		base = Color(0.7, 0.1, 0.05, 1.0)
	if _flash > 0.0:
		visual.color = Color(1, 1, 1, 1)
		_sync_sprite_art(Color(1, 1, 1, 1))
	else:
		visual.color = base
		_sync_sprite_art(base)
	# Face direction via slight offset
	if visual:
		visual.position.x = -12.0 if _facing > 0 else -10.0


func _on_contact_body(body: Node) -> void:
	_hurt_player(body)


func _check_contact_overlap() -> void:
	if not _alive or contact == null:
		return
	for b in contact.get_overlapping_bodies():
		_hurt_player(b)


func _hurt_player(body: Node) -> void:
	if _contact_grace > 0.0:
		return
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

