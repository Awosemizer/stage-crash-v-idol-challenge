extends Area2D
## Zona de estática / ruido blanco — daño periódico al jugador (ataques de Static Shadow).

const DAMAGE := 3
const TICK := 0.35
const LIFETIME := 2.2

var damage := DAMAGE
var lifetime := LIFETIME
var _tick := 0.15
var _life := LIFETIME
var _t := 0.0
var _arm := 0.0

@onready var visual: ColorRect = $Visual
@onready var flicker: ColorRect = $Flicker


func setup(life: float = LIFETIME, dmg: int = DAMAGE, arm: float = 0.0) -> void:
	lifetime = life
	_life = life
	damage = dmg
	_arm = maxf(arm, 0.0)


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("static_zones")
	body_entered.connect(_on_body_entered)
	if visual:
		visual.color = Color(0.85, 0.85, 0.95, 0.35)
	if flicker:
		flicker.color = Color(1.0, 1.0, 1.0, 0.2)


func _physics_process(delta: float) -> void:
	_t += delta
	_life -= delta
	_arm = maxf(_arm - delta, 0.0)
	_tick -= delta
	if visual:
		visual.color.a = 0.2 + 0.35 * absf(sin(_t * 28.0))
		visual.position.x = -visual.size.x * 0.5 + sin(_t * 55.0) * 1.5
	if flicker:
		flicker.visible = int(_t * 20.0) % 3 != 0
		flicker.color.a = 0.15 + 0.4 * absf(sin(_t * 60.0))
	if _life <= 0.0:
		queue_free()
		return
	if _arm <= 0.0 and _tick <= 0.0:
		_tick = TICK
		for b in get_overlapping_bodies():
			_hurt(b)


func _on_body_entered(body: Node) -> void:
	_hurt(body)


func _hurt(body: Node) -> void:
	if _arm > 0.0:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
