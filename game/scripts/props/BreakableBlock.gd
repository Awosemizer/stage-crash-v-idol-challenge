extends StaticBody2D
## Soft wall / ceiling tile — se rompe con disparos del jugador (Buster / Beat Blaze / sable).
## group: breakable

signal broken

@export var max_hp := 1
@export var block_color := Color(0.42, 0.22, 0.28, 1.0)

var hp := 1
var _alive := true

@onready var visual: ColorRect = $Visual
@onready var crack: ColorRect = $Crack
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemies")  # so saber / shots that check enemies can hit
	hp = max_hp
	if visual:
		visual.visible = false
		var spr := ArtKit.make_tile_sprite(ArtKit.theme_from_color(block_color), 1)
		spr.name = "SpriteArt"
		spr.position = Vector2.ZERO
		add_child(spr)
		move_child(spr, 0)
	if crack:
		crack.visible = false


func take_damage(amount: int) -> bool:
	if not _alive:
		return false
	hp = maxi(hp - maxi(amount, 1), 0)
	if crack:
		crack.visible = true
		crack.color = Color(1.0, 0.9, 0.5, 0.55)
	if hp <= 0:
		_break()
		return true
	return true


func _break() -> void:
	if not _alive:
		return
	_alive = false
	broken.emit()
	print("BreakableBlock: roto en ", global_position)
	# Disable collision immediately, fade visual
	if collision:
		collision.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	if visual:
		visual.color = Color(block_color.r, block_color.g, block_color.b, 0.25)
	queue_free()
