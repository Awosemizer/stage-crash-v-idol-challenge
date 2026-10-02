extends Area2D
## Perdigón lento del Met-Beat. No hiere en el frame de aparición.

const DAMAGE := 2
const SPEED := 72.0
const ARM := 0.22
const LIFE := 1.15

var damage := DAMAGE
var velocity := Vector2.ZERO
var _life := LIFE
var _arm := ARM

func setup(dir: int) -> void:
	var d := 1 if dir >= 0 else -1
	velocity = Vector2(float(d) * SPEED, 0.0)


func _ready() -> void:
	add_to_group("enemy_shots")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6, 6)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	var vis := ColorRect.new()
	vis.size = Vector2(6, 6)
	vis.position = Vector2(-3, -3)
	vis.color = Color(1.0, 0.82, 0.25, 0.95)
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vis)
	ArtKit.skin_projectile(vis, "res://assets/sprites/fx/met_pellet.png")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_arm = maxf(_arm - delta, 0.0)
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _arm > 0.0:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
