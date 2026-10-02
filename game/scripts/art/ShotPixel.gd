extends Sprite2D
## Visual-only projectile / slash sprite. Follows a ColorRect's position,
## visibility, and alpha. Does not touch collision.

var source: ColorRect
var frame_w := 0
var frame_i := 0


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 2


func _process(_delta: float) -> void:
	if source == null or not is_instance_valid(source):
		return
	visible = source.visible
	position = source.position + source.size * 0.5
	var c := source.color
	# Amber windup used by several shots (1, 0.82, 0.3). Keep that read.
	var warn := c.r > 0.95 and c.g > 0.74 and c.g < 0.93 and c.b > 0.15 and c.b < 0.45
	if warn:
		modulate = c
	else:
		modulate = Color(1, 1, 1, c.a)
	if frame_w > 0 and texture:
		region_enabled = true
		var frames := maxi(1, int(texture.get_width() / frame_w))
		var f := clampi(frame_i, 0, frames - 1)
		region_rect = Rect2(f * frame_w, 0, frame_w, texture.get_height())
	# Hide the flat rect without zeroing child modulate (sprite is a sibling).
	source.self_modulate = Color(1, 1, 1, 0)
	var parent := source.get_parent()
	if parent:
		for extra_name in ["Tip", "Noise"]:
			var extra := parent.get_node_or_null(extra_name) as CanvasItem
			if extra and extra != source:
				extra.self_modulate = Color(1, 1, 1, 0)
