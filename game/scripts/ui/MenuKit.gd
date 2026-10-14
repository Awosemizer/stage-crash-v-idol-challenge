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


const KIT := "res://assets/sprites/ui/kit/"


static func kit_box(name: String, m: int, cl := 10, ct := 3) -> StyleBox:
	## v0.66: 9-slice del kit SNES (esquinas/remaches fijos, centro estirado).
	var path := KIT + name + ".png"
	if not ResourceLoader.exists(path):
		return _box(Color(0.03, 0.02, 0.08, 0.9), COL_CYAN, 1)
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = cl
	sb.content_margin_right = cl
	sb.content_margin_top = ct
	sb.content_margin_bottom = ct
	return sb


static func style_button(btn: Button, accent: Color, font_size := 11) -> void:
	## v0.66: placas metálicas con remaches (normal / seleccionado / desactivado).
	var n := kit_box("btn_normal", 8)
	var sel := kit_box("btn_selected", 8)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", sel)
	btn.add_theme_stylebox_override("focus", sel)
	btn.add_theme_stylebox_override("pressed", sel)
	btn.add_theme_stylebox_override("disabled", kit_box("btn_disabled", 8))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	btn.add_theme_color_override("font_focus_color", COL_GOLD)
	btn.add_theme_color_override("font_hover_color", COL_GOLD)
	btn.add_theme_color_override("font_pressed_color", COL_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.62, 0.7))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
	btn.add_theme_constant_override("outline_size", 3)
	btn.focus_mode = Control.FOCUS_ALL
	if not btn.focus_entered.is_connected(_focus_sfx):
		btn.focus_entered.connect(_focus_sfx)
	if btn.is_inside_tree():
		attach_cursor(btn.get_tree().root)
	elif not btn.tree_entered.is_connected(_attach_from.bind(btn)):
		btn.tree_entered.connect(_attach_from.bind(btn), CONNECT_ONE_SHOT)


static func _attach_from(btn: Control) -> void:
	if is_instance_valid(btn) and btn.is_inside_tree():
		attach_cursor(btn.get_tree().root)


static func attach_cursor(root: Window) -> void:
	## Cursor del kit que sigue al botón con foco (un solo nodo por ventana).
	if root == null or root.has_meta("menu_cursor"):
		return
	var path := KIT + "cursor.png"
	if not ResourceLoader.exists(path):
		return
	var layer := CanvasLayer.new()
	layer.name = "MenuCursorLayer"
	layer.layer = 120
	var cur := TextureRect.new()
	cur.name = "MenuCursor"
	cur.texture = load(path)
	cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur.visible = false
	layer.add_child(cur)
	root.set_meta("menu_cursor", true)
	root.add_child.call_deferred(layer)
	root.gui_focus_changed.connect(_on_focus.bind(cur))
	cur.set_process(true)
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	layer.add_child(t)
	t.timeout.connect(_track.bind(cur))


static func _on_focus(c: Control, cur: TextureRect) -> void:
	if is_instance_valid(cur):
		cur.set_meta("target", c)
		_track(cur)


static func _track(cur: TextureRect) -> void:
	if not is_instance_valid(cur):
		return
	var c = cur.get_meta("target") if cur.has_meta("target") else null
	if c == null or not is_instance_valid(c) or not (c is Button) or not c.is_visible_in_tree():
		cur.visible = false
		return
	var r: Rect2 = c.get_global_rect()
	var xf: Transform2D = c.get_viewport().get_canvas_transform() if c.get_viewport() else Transform2D()
	var bob := 1.0 if int(Time.get_ticks_msec() / 250) % 2 == 0 else 0.0
	cur.position = xf * Vector2(r.position.x - cur.size.x - 1 - bob, r.position.y + (r.size.y - cur.size.y) * 0.5)
	cur.visible = true


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


static func panel_box(accent: Color) -> StyleBox:
	## v0.66: marco de ventana del kit (pausa, game over, datos, opciones…).
	return kit_box("window", 18, 14, 12)


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
