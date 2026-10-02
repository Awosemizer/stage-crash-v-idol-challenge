class_name SpriteBurst
extends Node
## Plays a short region-frame burst then frees the target sprite.

var target: Sprite2D
var frame_w: int = 16
var frame_h: int = 16
var frames: int = 4
var fps: float = 16.0
var lifetime: float = 0.25
var _t := 0.0
var _frame := 0


func _process(delta: float) -> void:
	_t += delta
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	_frame = mini(frames - 1, int(_t * fps))
	target.region_rect = Rect2(_frame * frame_w, 0, frame_w, frame_h)
	target.modulate.a = clampf(1.0 - (_t / maxf(lifetime, 0.01)), 0.0, 1.0)
	if _t >= lifetime:
		target.queue_free()
		queue_free()
