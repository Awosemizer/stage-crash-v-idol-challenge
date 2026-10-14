extends RefCounted
## v0.64 kit de menús "16-bit comercial": fondo a pantalla completa, botones con foco
## visible (mando/táctil), fundidos entre pantallas, texto con contorno.

const COL_CYAN := Color(0.35, 0.92, 1.0)
const COL_PINK := Color(1.0, 0.38, 0.72)
const COL_GOLD := Color(1.0, 0.86, 0.35)
const STAGE := Vector2(398, 224)


static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


static func stage_origin(ctrl: Control) -> Vector2:
	## Esquina del lienzo 398×224 centrado en el viewport (aspect "expand").
	var vp := ctrl.get_viewport_rect().size
	return ((vp - STAGE) * 0.5).floor().max(Vector2.ZERO)


static func add_fullscreen_art(parent: Control, path: String, node_name: String, dim: float = 0.0) -> TextureRect:
	var tex := ArtKit.load_tex(path)
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dim > 0.0:
		tr.modulate = Color(1.0 - dim, 1.0 - dim, 1.0 - dim, 1.0)
	parent.add_child(tr)
	return tr


static func _box(bg: Color, border: Color, bw: int, glow := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.set_corner_radius_all(0)  # esquinas rectas: look 16-bit
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	if glow:
		sb.shadow_color = Color(border.r, border.g, border.b, 0.45)
		sb.shadow_size = 3
	return sb


static func style_button(btn: Button, accent: Color, font_size := 11) -> void:
	## Normal: placa oscura con filo de color. Foco/hover: placa clara + borde dorado con brillo.
	btn.add_theme_stylebox_override("normal", _box(Color(0.03, 0.02, 0.08, 0.88), Color(accent.r, accent.g, accent.b, 0.85), 1))
	btn.add_theme_stylebox_override("hover", _box(Color(0.12, 0.08, 0.22, 0.95), COL_GOLD, 2, true))
	btn.add_theme_stylebox_override("focus", _box(Color(0.12, 0.08, 0.22, 0.0), COL_GOLD, 2, false))
	btn.add_theme_stylebox_override("pressed", _box(Color(0.25, 0.18, 0.05, 0.95), COL_GOLD, 2, true))
	btn.add_theme_stylebox_override("disabled", _box(Color(0.03, 0.03, 0.05, 0.7), Color(0.3, 0.3, 0.38, 0.6), 1))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	btn.add_theme_color_override("font_focus_color", COL_GOLD)
	btn.add_theme_color_override("font_hover_color", COL_GOLD)
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
	btn.add_theme_constant_override("outline_size", 3)
	btn.focus_mode = Control.FOCUS_ALL
	if not btn.focus_entered.is_connected(_focus_sfx):
		btn.focus_entered.connect(_focus_sfx)


static func _focus_sfx() -> void:
	if AudioManager and not is_headless():
		AudioManager.play_sfx("menu_move")


static func label(text: String, size: int, col: Color, outline := 3) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06, 1.0))
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func panel_box(accent: Color) -> StyleBoxFlat:
	## Marco común de paneles (pausa, arma obtenida, game over, datos…).
	var sb := _box(Color(0.03, 0.02, 0.08, 0.94), accent, 2, true)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func fade_in(parent: Node, secs := 0.25) -> void:
	if is_headless() or parent == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "FadeIn"
	layer.layer = 120
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 1)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	parent.add_child(layer)
	var tw := parent.create_tween()
	tw.tween_property(r, "color:a", 0.0, secs)
	tw.tween_callback(layer.queue_free)


static func go(from: Node, path: String, secs := 0.2) -> void:
	## Fundido a negro y cambio de escena (directo en headless: pruebas).
	var tree := from.get_tree()
	if tree == null:
		return
	if is_headless():
		tree.change_scene_to_file(path)
		return
	if from.get_node_or_null("FadeOut") != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "FadeOut"
	layer.layer = 121
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(r)
	from.add_child(layer)
	var tw := from.create_tween()
	tw.tween_property(r, "color:a", 1.0, secs)
	tw.tween_callback(func(): tree.change_scene_to_file(path))
