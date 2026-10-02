extends Area2D
## Spike / lava contact hazard. Deals damage via group "hazards".
## Player also detects PhysicsBody hazards via slide collisions;
## this Area2D covers overlapping spikes.

@export var damage := 4

func _ready() -> void:
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif body.has_method("take_hit"):
		body.take_hit(damage)
