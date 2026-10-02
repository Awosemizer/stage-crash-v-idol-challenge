extends Area2D
## Onda Sonic Slash (Teto + brazos Stage Flight) — proyectil de corte a media distancia.
## GDD: daño 6.

const SPEED := 260.0
const DAMAGE := 6
const SIZE := Vector2(22, 10)
const COLOR := Color(1.0, 0.45, 0.55, 0.95)
const LIFETIME := 0.55

var damage := DAMAGE
var direction := 1
var _life := LIFETIME

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int) -> void:
	direction = 1 if dir >= 0 else -1
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
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta
	# Soft vertical wobble (wave look)
	position.y += sin(Time.get_ticks_msec() * 0.03 + position.x * 0.05) * 12.0 * delta
	_life -= delta
	if visual:
		var pulse := 0.75 + 0.25 * absf(sin(Time.get_ticks_msec() * 0.02))
		visual.color = Color(COLOR.r, COLOR.g, COLOR.b, pulse)
		visual.size = Vector2(SIZE.x + 4.0 * (1.0 - _life / LIFETIME), SIZE.y)
		visual.position = -visual.size * 0.5
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Node) -> void:
	_try_hit(area)


func _try_hit(target: Node) -> void:
	if target == null:
		return
	if target.is_in_group("player") or target.is_in_group("player_shots"):
		return
	if target is StaticBody2D and not target.is_in_group("enemies"):
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			var result = target.take_damage(damage)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false)
			if result == false:
				queue_free()
				return
		queue_free()
