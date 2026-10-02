extends RefCounted
## Maps DisplayServer safe area (notches / cutouts) into viewport coordinates
## for HUD and touch overlays. Works with canvas_items + expand stretch.
## Also provides shared landscape-phone UI layout helpers.

## Preferred primary touch target height (viewport px). Stick radius is 44.
const PREFERRED_BTN_H := 44.0
## Floor for any tappable control on phones.
const MIN_BTN_H := 28.0
## Secondary / footer buttons when vertical space is tight.
const MIN_BTN_H_SECONDARY := 22.0


static func insets_px() -> Vector4:
	## Returns Vector4(left, top, right, bottom) in viewport pixels.
	var vp := Engine.get_main_loop() as SceneTree
	if vp == null:
		return Vector4(12, 8, 12, 10)
	var viewport := vp.root.get_viewport() if vp.root else null
	if viewport == null:
		return Vector4(12, 8, 12, 10)
	var vis := viewport.get_visible_rect()
	var win_size := DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		return Vector4(12, 8, 12, 10)
	var safe := DisplayServer.get_display_safe_area()
	# Fallback when safe area equals full screen (desktop / no notch)
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4(12, 8, 12, 10)
	var sx := vis.size.x / float(win_size.x)
	var sy := vis.size.y / float(win_size.y)
	var left := maxf(safe.position.x * sx, 0.0)
	var top := maxf(safe.position.y * sy, 0.0)
	var right := maxf((win_size.x - safe.end.x) * sx, 0.0)
	var bottom := maxf((win_size.y - safe.end.y) * sy, 0.0)
	# Minimum padding so controls never hug the bezel on phones
	const MIN_L := 12.0
	const MIN_T := 8.0
	const MIN_R := 12.0
	const MIN_B := 10.0
	return Vector4(maxf(left, MIN_L), maxf(top, MIN_T), maxf(right, MIN_R), maxf(bottom, MIN_B))


static func content_rect() -> Rect2:
	var vp := Engine.get_main_loop() as SceneTree
	if vp == null or vp.root == null:
		return Rect2(0, 0, 398, 224)
	var vis := vp.root.get_viewport().get_visible_rect()
	var ins := insets_px()
	return Rect2(
		vis.position.x + ins.x,
		vis.position.y + ins.y,
		maxf(vis.size.x - ins.x - ins.z, 64.0),
		maxf(vis.size.y - ins.y - ins.w, 64.0)
	)


static func viewport_size() -> Vector2:
	var vp := Engine.get_main_loop() as SceneTree
	if vp == null or vp.root == null:
		return Vector2(398, 224)
	return vp.root.get_viewport().get_visible_rect().size


## Pick a touch-friendly button height. Prefer 44 when the column has room.
static func btn_h(available_column: float, count: int = 1, gap: float = 6.0, prefer_primary: bool = true) -> float:
	var n := maxi(count, 1)
	var budget := maxf(available_column - gap * float(n - 1), MIN_BTN_H)
	var each := budget / float(n)
	var floor_h := PREFERRED_BTN_H if prefer_primary else MIN_BTN_H_SECONDARY
	if prefer_primary:
		return clampf(each, MIN_BTN_H, PREFERRED_BTN_H)
	return clampf(each, MIN_BTN_H_SECONDARY, maxf(floor_h, MIN_BTN_H))


static func style_button(btn: Button, bg: Color, border: Color, radius: int = 4) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(radius)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.15)
	hover.border_color = border.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.2)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	disabled.border_color = Color(0.35, 0.35, 0.4, 0.7)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


## Center a fixed design-width cluster inside the safe content rect.
static func center_x(design_w: float, area: Rect2 = Rect2()) -> float:
	var a := area if area.size.x > 0.0 else content_rect()
	return a.position.x + maxf((a.size.x - design_w) * 0.5, 0.0)
