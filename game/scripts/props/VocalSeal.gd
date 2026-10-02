extends StaticBody2D
## Sello vocal — solo cede ante golpes fuertes (carga Nv2+, armas especiales, sable).
## Puzzle del Voice Archive.

signal broken

@export var min_damage := 2
@export var seal_color := Color(0.55, 0.75, 1.0, 1.0)

var _alive := true
var _weak_hits := 0

@onready var visual: ColorRect = $Visual
@onready var hint: Label = $Hint
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemies")
	add_to_group("vocal_seal")
	if visual:
		visual.color = seal_color
	if hint:
		hint.text = "SELLO\n(carga/arma)"


func take_damage(amount: int) -> bool:
	if not _alive:
		return false
	if AudioManager:
		AudioManager.play_sfx("hit", 1.1, -3.0)
	if amount < min_damage:
		# Accumulate weak hits — prevents softlock if charge unavailable
		_weak_hits += 1
		if visual:
			visual.color = Color(1.0, 1.0, 1.0, 0.9)
			get_tree().create_timer(0.08).timeout.connect(func () -> void:
				if is_instance_valid(visual) and _alive:
					visual.color = seal_color
			)
		if _weak_hits < 6:
			return false
		# 6 weak hits ≈ charge break
	_break()
	return true


func _break() -> void:
	if not _alive:
		return
	_alive = false
	broken.emit()
	print("VocalSeal: roto en ", global_position)
	if collision:
		collision.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	queue_free()
