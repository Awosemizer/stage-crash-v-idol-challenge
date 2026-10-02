extends Control
## Hub Fortaleza CORE-9 — entrada al asalto lineal.
## Landscape SafeArea; Enter/Return ≥44px when space allows.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const LOBBY := "res://scenes/levels/LevelFortressLobby.tscn"


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.06, 0.04, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var accent := ColorRect.new()
	accent.name = "Accent"
	accent.color = Color(0.85, 0.3, 0.95, 0.9)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "SYNTHOCORP · CORE-9"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 11)
	header.modulate = Color(0.9, 0.55, 1.0, 1.0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var panel := Panel.new()
	panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.16, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.3, 0.95, 1.0)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Fortaleza CORE-9"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = Color(0.95, 0.85, 1.0, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Lobby Neon → Voice Archive\n→ Core Shaft → Heart of CORE-9"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 8)
	sub.modulate = Color(0.75, 0.7, 0.9, 0.9)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)

	var enter := Button.new()
	enter.name = "EnterButton"
	enter.text = "Entrar al asalto"
	enter.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(enter, Color(0.2, 0.1, 0.28, 0.95), Color(0.85, 0.3, 0.95))
	enter.pressed.connect(_on_enter)
	panel.add_child(enter)

	var back := Button.new()
	back.name = "ReturnButton"
	back.text = "Volver al selector"
	back.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(back, Color(0.16, 0.1, 0.22, 0.95), Color(0.85, 0.3, 0.95))
	back.pressed.connect(_on_return)
	add_child(back)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()

	var accent := get_node_or_null("Accent") as ColorRect
	if accent:
		accent.position = Vector2(0, area.position.y + 24.0)
		accent.size = Vector2(vp.x, 2)

	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 4.0)
		header.size = Vector2(area.size.x, 16)

	var btn_h := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 36.0))
	var back := get_node_or_null("ReturnButton") as Button
	if back:
		back.size = Vector2(minf(200.0, area.size.x), btn_h)
		back.position = Vector2(area.position.x + (area.size.x - back.size.x) * 0.5, area.end.y - btn_h)

	var panel := get_node_or_null("Panel") as Panel
	if panel == null:
		return
	var pw := minf(300.0, area.size.x)
	var ph := maxf(120.0, minf(150.0, area.size.y - 70.0))
	panel.size = Vector2(pw, ph)
	panel.position = Vector2(
		area.position.x + (area.size.x - pw) * 0.5,
		area.position.y + 32.0
	)

	var title := panel.get_node_or_null("Title") as Label
	if title:
		title.position = Vector2(0, 10)
		title.size = Vector2(pw, 18)
	var sub := panel.get_node_or_null("Subtitle") as Label
	if sub:
		sub.position = Vector2(12, 34)
		sub.size = Vector2(pw - 24.0, 40)
	var enter := panel.get_node_or_null("EnterButton") as Button
	if enter:
		var eh := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 40.0))
		enter.size = Vector2(minf(180.0, pw - 40.0), eh)
		enter.position = Vector2((pw - enter.size.x) * 0.5, ph - eh - 12.0)
		enter.add_theme_font_size_override("font_size", 11 if eh >= 36.0 else 9)


func _on_enter() -> void:
	print("Fortaleza: entrando Lobby Neon")
	get_tree().change_scene_to_file(LOBBY)


func _on_return() -> void:
	get_tree().change_scene_to_file(BOSS_SELECT)
