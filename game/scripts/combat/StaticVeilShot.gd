extends Area2D
## Static Veil — zona de ruido blanco (daño 3, coste 3, ammo 14). Arma de Static Shadow.
## Proyectil lento que deja un velo residual. Debilidad: weak_to_static_veil ×3.

const SPEED := 95.0
const DAMAGE := 3
const SIZE := Vector2(22, 18)
const COLOR := Color(0.75, 0.7, 0.9, 0.75)
const LIFETIME := 1.35
const TICK := 0.22

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0
var _tick := 0.0
var _hit_ids: Dictionary = {}

@onready var visual: ColorRect = $Visual
@onready var noise: ColorRect = $Noise
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
	velocity = Vector2(float(direction) * SPEED, 0.0)
	if is_node_ready():
		_apply_look()
	else:
		ready.connect(_apply_look, CONNECT_ONE_SHOT)


func _ready() -> void:
	add_to_group("player_shots")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_apply_look()


func _apply_look() -> void:
	if visual == null or collision == null:
		return
	visual.size = SIZE
	visual.position = -SIZE * 0.5
	visual.color = COLOR
	ArtKit.skin_projectile(visual, "res://assets/sprites/fx/static_veil.png")
	if noise:
		noise.size = SIZE * 0.7
		noise.position = -noise.size * 0.5
		noise.color = Color(0.95, 0.95, 1.0, 0.35)
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	_t += delta
	_tick -= delta
	position += velocity * delta
	# Soft expand / flicker (white noise feel)
	velocity.x = move_toward(velocity.x, float(direction) * 40.0, 80.0 * delta)
	if visual:
		var pulse := 0.55 + 0.35 * absf(sin(_t * 22.0))
		visual.color.a = pulse
		visual.size = SIZE + Vector2(4.0 * sin(_t * 10.0), 3.0 * cos(_t * 12.0))
		visual.position = -visual.size * 0.5
	if noise:
		noise.color.a = 0.2 + 0.4 * absf(sin(_t * 40.0 + 1.2))
		noise.position = Vector2(sin(_t * 50.0) * 2.0, cos(_t * 37.0) * 2.0) - noise.size * 0.5
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _tick <= 0.0:
		_tick = TICK
		_pulse_damage()


func _pulse_damage() -> void:
	for body in get_overlapping_bodies():
		_try_hit(body, false)
	for area in get_overlapping_areas():
		_try_hit(area, false)


func _on_body_entered(body: Node) -> void:
	_try_hit(body, true)


func _on_area_entered(area: Node) -> void:
	_try_hit(area, true)


func _try_hit(target: Node, free_on_wall: bool) -> void:
	if target == null:
		return
	if target.is_in_group("player") or target.is_in_group("player_shots"):
		return
	if (target is StaticBody2D or target is AnimatableBody2D) and not target.is_in_group("enemies"):
		if free_on_wall:
			queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if not target.has_method("take_damage"):
			return
		var id := target.get_instance_id()
		# One application per shot. Ticks are visual; damage is the table value (3 / 9).
		if _hit_ids.has(id):
			return
		_hit_ids[id] = true
		var dmg := damage
		if target.is_in_group("weak_to_static_veil"):
			dmg = damage * 3
		var result = target.take_damage(dmg)
		if GameState and GameState.has_method("notify_enemy_hit"):
			GameState.notify_enemy_hit(target, result != false, dmg > damage)
		if result == false:
			return
