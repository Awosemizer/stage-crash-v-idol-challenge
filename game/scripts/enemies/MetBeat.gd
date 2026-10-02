extends Area2D
## Met-Beat — enemigo común de todas las etapas. Caparazón cerrado no duele
## ni recibe daño. Aviso ámbar ~0.28 s antes de abrir y disparar un perdigón.
## HP 2 (buster ×2 / sable ×1). Contacto 1 solo con el caparazón abierto.

const HP_MAX := 2
const CONTACT_DAMAGE := 1
const CLOSED_TIME := 1.15
const OPEN_TIME := 0.75
const OPEN_WARN := 0.28
const HIT_FLASH := 0.12
const SHOT_RANGE_X := 200.0
const SHOT_RANGE_Y := 56.0

const MetBeatShotScript := preload("res://scripts/enemies/MetBeatShot.gd")

signal died

var hp := HP_MAX
var _open := false
var _timer := 0.0
var _flash := 0.0
var _alive := true
var _stealth := false
var _warning := false
var _warn_t := 0.0
var _shot_pending := false

@onready var visual: Sprite2D = $Visual
@onready var eye: Sprite2D = $Eye
@onready var shell_hint: Sprite2D = $ShellHint


func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	# Arranca cerrado un instante para que no sea free kill al spawn
	_open = false
	_timer = CLOSED_TIME * 0.4
	_refresh_look()


func _process(delta: float) -> void:
	if not _alive:
		return
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
	if _warning:
		_warn_t -= delta
		_refresh_look()
		if _warn_t <= 0.0:
			_warning = false
			_open = true
			_timer = OPEN_TIME
			_shot_pending = true
			_refresh_look()
		return
	_timer -= delta
	if _timer <= 0.0:
		if _open:
			_open = false
			_shot_pending = false
			_timer = CLOSED_TIME
		else:
			_warning = true
			_warn_t = OPEN_WARN
		_refresh_look()
	elif _shot_pending and _open and _timer <= OPEN_TIME - 0.06:
		_shot_pending = false
		_try_shot()
	elif _flash > 0.0 or _warning:
		_refresh_look()


func _refresh_look() -> void:
	if visual == null:
		return
	var open_tex: Texture2D = load("res://assets/sprites/enemies/met_open.png") as Texture2D
	var closed_tex: Texture2D = load("res://assets/sprites/enemies/met_closed.png") as Texture2D
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = true
	visual.position = Vector2(0, -12)  # 24px sprite, feet at y=0
	if _open and not _warning:
		if open_tex:
			visual.texture = open_tex
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
		if eye:
			eye.visible = false
		if shell_hint:
			shell_hint.visible = false
	else:
		if closed_tex:
			visual.texture = closed_tex
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
		if eye:
			eye.visible = false
		if shell_hint:
			shell_hint.visible = false
	if _warning:
		var pulse := 0.65 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.02))
		visual.modulate = Color(1.5, 1.15, 0.35, 1.0)
		visual.scale = Vector2(1.0 + 0.12 * pulse, 1.0 + 0.12 * pulse)
	elif _flash > 0.0:
		visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
	if _stealth and not _warning:
		var a := 0.55 if _open else 0.12
		modulate = Color(1, 1, 1, a)
	elif _warning:
		modulate = Color(1, 1, 1, 0.95)
	else:
		modulate = Color(1, 1, 1, 1)


func is_open() -> bool:
	return _open and not _warning


func set_stealth(enabled: bool) -> void:
	## Invisible entre beats (Static Shadow): casi invisible cerrado, visible al abrir.
	_stealth = enabled
	_refresh_look()


func is_stealth() -> bool:
	return _stealth


func take_damage(amount: int) -> bool:
	## Devuelve true si el daño aplicó; false si rebotó en el caparazón.
	if not _alive:
		return false
	if not _open or _warning:
		# Flash breve de rebote
		_flash = HIT_FLASH * 0.5
		_refresh_look()
		return false
	hp = maxi(hp - amount, 0)
	_flash = HIT_FLASH
	if AudioManager:
		AudioManager.play_sfx("hit")
	_refresh_look()
	if hp <= 0:
		_die()
	return true


func _die() -> void:
	_alive = false
	died.emit()
	queue_free()


func _on_body_entered(body: Node) -> void:
	if not _alive:
		return
	if body == null or not body.is_in_group("player"):
		return
	# Caparazón cerrado: empuja visualmente, no quita vida.
	if not _open or _warning:
		_flash = HIT_FLASH
		_refresh_look()
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)


func _try_shot() -> void:
	if not _alive or _stealth or not _open:
		return
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return
	var p := players[0] as Node2D
	if p == null:
		return
	var delta := p.global_position - global_position
	if absf(delta.x) > SHOT_RANGE_X or absf(delta.y) > SHOT_RANGE_Y:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	var shot: Area2D = MetBeatShotScript.new()
	parent_node.add_child(shot)
	shot.global_position = global_position + Vector2(0, -10)
	if shot.has_method("setup"):
		shot.setup(1 if delta.x >= 0.0 else -1)
