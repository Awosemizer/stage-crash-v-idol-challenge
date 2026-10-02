extends CharacterBody2D
## Refrain Unit — mid-boss Lobby Neon. Copia un patrón simple del jugador
## (disparo horizontal o dash corto). HP 18.

signal died
signal hp_changed(current: int, maximum: int)

const HP_MAX := 18
const CONTACT_DAMAGE := 2
const GRAVITY := 700.0
const BEAT := 1.0
const HIT_FLASH := 0.1
const INVULN_ON_HIT := 0.07

enum State { IDLE, COPY_SHOT, COPY_DASH, DEAD }

const FireballScene := preload("res://scenes/combat/Fireball.tscn")

var hp := HP_MAX
var _state: State = State.IDLE
var _beat := 0.0
var _flash := 0.0
var _invuln := 0.0
var _alive := true
var _active := false
var _facing := -1
var _dash_t := 0.0
var _copy_mode := 0  # 0=shot, 1=dash — picks once on activate

@onready var visual: ColorRect = $Visual
var _sprite_art: Sprite2D
@onready var trim: ColorRect = $Trim
@onready var contact: Area2D = $ContactArea
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarFill
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	_sprite_art = ArtKit.skin_boss_visual(visual, "refrain")
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("midboss")
	if visual:
		visual.color = Color(0.95, 0.35, 0.85, 1.0)
		_sync_sprite_art(Color(0.95, 0.35, 0.85, 1.0))
	if trim:
		trim.color = Color(0.4, 0.9, 1.0, 0.85)
	if contact:
		contact.body_entered.connect(_on_contact_body)
	if name_label:
		name_label.text = "REFRAIN UNIT"
	_refresh_hp_bar()
	_active = false


func activate() -> void:
	if GameState and GameState.has_method("begin_boss_fight_track"):
		GameState.begin_boss_fight_track()
	_active = true
	if AudioManager and AudioManager.has_method("play_boss_intro"):
		AudioManager.play_boss_intro()
	_beat = 0.55
	_state = State.IDLE
	# Copy one simple pattern for the fight
	_copy_mode = 0 if (Time.get_ticks_msec() % 2 == 0) else 1
	print("RefrainUnit: copia patrón=", "DISPARO" if _copy_mode == 0 else "DASH")


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_flash = maxf(_flash - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_update_facing()
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 360.0)
	else:
		if _state != State.COPY_DASH:
			velocity.y = 0.0

	if _active:
		match _state:
			State.IDLE:
				_tick_idle(delta)
			State.COPY_SHOT:
				pass
			State.COPY_DASH:
				_tick_dash(delta)
			State.DEAD:
				pass

	move_and_slide()
	_refresh_look()
	_check_contact_overlap()


func _tick_idle(delta: float) -> void:
	_beat -= delta
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	if _beat > 0.0:
		return
	if _copy_mode == 0:
		_do_copy_shot()
	else:
		_start_dash()


func _do_copy_shot() -> void:
	_state = State.COPY_SHOT
	_update_facing()
	var count := 1 if hp > HP_MAX / 2 else 2
	for i in count:
		var ang := deg_to_rad(-8.0 + float(i) * 8.0)
		var dir := Vector2(float(_facing), 0.0).rotated(ang)
		_spawn_shot(dir)
	_state = State.IDLE
	_beat = BEAT if hp > HP_MAX / 2 else BEAT * 0.75


func _start_dash() -> void:
	_state = State.COPY_DASH
	_update_facing()
	_dash_t = 0.22
	velocity.x = float(_facing) * 110.0
	velocity.y = 0.0


func _tick_dash(delta: float) -> void:
	_dash_t -= delta
	if _dash_t <= 0.0:
		velocity.x = 0.0
		_state = State.IDLE
		_beat = BEAT * 1.0


func _spawn_shot(dir: Vector2) -> void:
	var fb: Area2D = FireballScene.instantiate()
	var parent_node := get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(fb)
	fb.global_position = global_position + Vector2(_facing * 10.0, -16.0)
	if fb.has_method("setup"):
		fb.setup(dir, 150.0)
	# Pink-tint copy
	if fb.has_node("Visual"):
		fb.get_node("Visual").color = Color(1.0, 0.4, 0.9, 1.0)


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
	if visual:
		visual.color = Color(1, 1, 1, 1)
		_sync_sprite_art(Color(1, 1, 1, 1))
	await get_tree().create_timer(0.4).timeout
	queue_free()


func _refresh_hp_bar() -> void:
	if hp_bar_bg == null or hp_bar_fill == null:
		return
	var ratio := 0.0 if HP_MAX <= 0 else float(hp) / float(HP_MAX)
	hp_bar_fill.size.x = maxf(hp_bar_bg.size.x * ratio, 0.0)
	hp_bar_fill.color = Color(0.95, 0.4, 0.85, 1.0) if ratio > 0.5 else Color(1.0, 0.25, 0.55, 1.0)


func _refresh_look() -> void:
	if visual == null:
		return
	var base := Color(0.95, 0.35, 0.85, 1.0)
	if _flash > 0.0:
		visual.color = Color(1, 1, 1, 1)
		_sync_sprite_art(Color(1, 1, 1, 1))
	else:
		visual.color = base
		_sync_sprite_art(base)


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

