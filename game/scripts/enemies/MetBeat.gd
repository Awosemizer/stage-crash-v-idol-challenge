extends Area2D
## Met-Beat — enemigo común estilo Met. Se cierra al ritmo del beat;
## vulnerable solo cuando abre el caparazón. HP 2, daño de contacto 2.

const HP_MAX := 2
const CONTACT_DAMAGE := 2
const CLOSED_TIME := 1.05
const OPEN_TIME := 0.75
const HIT_FLASH := 0.12

signal died

var hp := HP_MAX
var _open := false
var _timer := 0.0
var _flash := 0.0
var _alive := true
var _stealth := false

@onready var visual: ColorRect = $Visual
@onready var eye: ColorRect = $Eye
@onready var shell_hint: ColorRect = $ShellHint


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
	_timer -= delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
	if _timer <= 0.0:
		_open = not _open
		_timer = OPEN_TIME if _open else CLOSED_TIME
		_refresh_look()
	elif _flash > 0.0:
		_refresh_look()


func _refresh_look() -> void:
	if visual == null:
		return
	if _open:
		# Abierto: cuerpo rosa-rojo, ojo visible
		visual.color = Color(0.85, 0.35, 0.4, 1.0)
		if eye:
			eye.visible = true
			eye.color = Color(1.0, 0.95, 0.2, 1.0)
		if shell_hint:
			shell_hint.visible = false
	else:
		# Cerrado: caparazón metálico
		visual.color = Color(0.45, 0.5, 0.58, 1.0)
		if eye:
			eye.visible = false
		if shell_hint:
			shell_hint.visible = true
			shell_hint.color = Color(0.65, 0.7, 0.78, 1.0)
	if _flash > 0.0:
		visual.color = Color(1.0, 1.0, 1.0, 1.0)
	if _stealth:
		# Nearly invisible when closed; faint when open
		var a := 0.55 if _open else 0.12
		modulate = Color(1, 1, 1, a)
	else:
		modulate = Color(1, 1, 1, 1)


func is_open() -> bool:
	return _open


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
	if not _open:
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
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)
