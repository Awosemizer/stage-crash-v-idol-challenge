extends Area2D
## Petal Chorus — proyectil rosa (daño 1). Arma de Chorus Bloom.
## Cada 4 impactos exitosos cura +1 PV (DISENO).
## Debilidad: Metronome (weak_to_petal_chorus) ×3.

const SPEED := 200.0
const DAMAGE := 1
const SIZE := Vector2(10, 7)
const COLOR := Color(0.95, 0.45, 0.8, 1.0)
const LIFETIME := 1.85
const HEAL_EVERY := 4

var damage := DAMAGE
var direction := 1
var velocity := Vector2.ZERO
var _life := LIFETIME
var _t := 0.0

## Contador global de hits Petal Chorus (por partida / sesión de nivel).
static var hit_streak: int = 0

@onready var visual: ColorRect = $Visual
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
	ArtKit.skin_projectile(visual, "res://assets/sprites/fx/petal.png")
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision.shape = shape
	shape.size = SIZE


func _physics_process(delta: float) -> void:
	_t += delta
	position += velocity * delta
	# Soft petal wobble
	position.y += sin(_t * 14.0) * 20.0 * delta
	if visual:
		visual.color.a = 0.75 + 0.25 * absf(sin(_t * 16.0))
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
	if (target is StaticBody2D or target is AnimatableBody2D) and not target.is_in_group("enemies"):
		queue_free()
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			var dmg := damage
			if target.is_in_group("weak_to_petal_chorus"):
				dmg = damage * 3
			var result = target.take_damage(dmg)
			if GameState and GameState.has_method("notify_enemy_hit"):
				GameState.notify_enemy_hit(target, result != false, dmg > damage)
			if result == false:
				queue_free()
				return
			_on_successful_hit()
		queue_free()


func _on_successful_hit() -> void:
	hit_streak += 1
	if hit_streak < HEAL_EVERY:
		return
	hit_streak = 0
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node = players[0]
	if p.has_method("heal"):
		p.heal(1)
	elif "hp" in p and "max_hp" in p:
		p.hp = mini(int(p.hp) + 1, int(p.max_hp))
		if p.has_signal("hp_changed"):
			p.hp_changed.emit(p.hp, p.max_hp)
