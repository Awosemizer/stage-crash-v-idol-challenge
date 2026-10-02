class_name ParallaxScroller
extends Node2D
## Scrolls far/mid layers against the active Camera2D.

var far_layer: Node2D
var mid_layer: Node2D
var level_width: float = 1280.0


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cx := cam.get_screen_center_position().x
	if far_layer:
		far_layer.position.x = -cx * 0.15
	if mid_layer:
		mid_layer.position.x = -cx * 0.35
