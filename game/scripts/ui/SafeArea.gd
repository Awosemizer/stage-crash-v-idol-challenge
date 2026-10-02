extends RefCounted
## Maps DisplayServer safe area (notches / cutouts) into viewport coordinates
## for HUD and touch overlays. Works with canvas_items + expand stretch.

static func insets_px() -> Vector4:
	## Returns Vector4(left, top, right, bottom) in viewport pixels.
	var vp := Engine.get_main_loop() as SceneTree
	if vp == null:
		return Vector4(8, 6, 8, 8)
	var viewport := vp.root.get_viewport() if vp.root else null
	if viewport == null:
		return Vector4(8, 6, 8, 8)
	var vis := viewport.get_visible_rect()
	var win_size := DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		return Vector4(8, 6, 8, 8)
	var safe := DisplayServer.get_display_safe_area()
	# Fallback when safe area equals full screen (desktop / no notch)
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4(8, 6, 8, 8)
	var sx := vis.size.x / float(win_size.x)
	var sy := vis.size.y / float(win_size.y)
	var left := maxf(safe.position.x * sx, 0.0)
	var top := maxf(safe.position.y * sy, 0.0)
	var right := maxf((win_size.x - safe.end.x) * sx, 0.0)
	var bottom := maxf((win_size.y - safe.end.y) * sy, 0.0)
	# Minimum padding so controls never hug the bezel on phones
	const MIN_L := 10.0
	const MIN_T := 6.0
	const MIN_R := 10.0
	const MIN_B := 10.0
	return Vector4(maxf(left, MIN_L), maxf(top, MIN_T), maxf(right, MIN_R), maxf(bottom, MIN_B))


static func content_rect() -> Rect2:
	var vp := Engine.get_main_loop() as SceneTree
	if vp == null or vp.root == null:
		return Rect2(0, 0, 256, 224)
	var vis := vp.root.get_viewport().get_visible_rect()
	var ins := insets_px()
	return Rect2(
		vis.position.x + ins.x,
		vis.position.y + ins.y,
		maxf(vis.size.x - ins.x - ins.z, 64.0),
		maxf(vis.size.y - ins.y - ins.w, 64.0)
	)
