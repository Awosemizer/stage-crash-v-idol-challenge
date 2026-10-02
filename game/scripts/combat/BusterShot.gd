extends Area2D
## Proyectil del Buster de Miku — niveles 1–3 (+ Nv4 stub con Stage Flight arms).

const SPEED_LV := {1: 280.0, 2: 300.0, 3: 320.0, 4: 340.0}
const DAMAGE_LV := {1: 1, 2: 2, 3: 4, 4: 8}  # DISENO: Nv3=4, Nv4 Flight=8
const SIZE_LV := {
	1: Vector2(6, 4),
	2: Vector2(10, 6),
	3: Vector2(14, 10),
	4: Vector2(16, 12),
}
const COLOR_LV := {
	1: Color(0.85, 0.95, 1.0, 1.0),
	2: Color(0.45, 0.85, 1.0, 1.0),
	3: Color(1.0, 0.95, 0.35, 1.0),
	4: Color(0.85, 0.45, 1.0, 1.0),
}
const LIFETIME := 1.6

var damage := 1
var direction := 1
var level := 1
var _life := LIFETIME
var _speed := 280.0

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(dir: int, charge_level: int) -> void:
	direction = 1 if dir >= 0 else -1
	level = clampi(charge_level, 1, 4)
	damage = DAMAGE_LV[level]
	_speed = SPEED_LV[level]
	# Visual/collision may not be ready yet if called before add_child
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
	var sz: Vector2 = SIZE_LV[level]
	visual.size = sz
	visual.position = -sz * 0.5
	visual.color = COLOR_LV[level]
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = sz


func _physics_process(delta: float) -> void:
	position.x += direction * _speed * delta
	_life -= delta
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
	# Mundo sólido (StaticBody plataformas): el disparo se detiene
	if target is StaticBody2D and not target.is_in_group("enemies"):
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			# Met cerrado puede devolver false / no consumir
			var result = target.take_damage(damage)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false)
			ArtKit.spawn_hit_spark(get_parent(), global_position, 0.9 + 0.15 * float(level))
			if result == false:
				# Rebotó en caparazón: destruir proyectil igual
				queue_free()
				return
		else:
			ArtKit.spawn_hit_spark(get_parent(), global_position)
		queue_free()
