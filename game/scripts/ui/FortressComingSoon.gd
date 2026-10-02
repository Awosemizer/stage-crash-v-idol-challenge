extends Control
## Stub fortaleza CORE-9 — "Fortaleza en construcción". Preparado para el siguiente hito.

const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"


func _ready() -> void:
	_build_ui()


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
	accent.position = Vector2(0, 28)
	accent.size = Vector2(256, 2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "SYNTHOCORP · CORE-9"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 9)
	header.modulate = Color(0.9, 0.55, 1.0, 1.0)
	header.position = Vector2(0, 8)
	header.size = Vector2(256, 14)
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
	panel.size = Vector2(200, 100)
	panel.position = Vector2(28, 56)
	add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Fortaleza en construcción"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	title.modulate = Color(0.95, 0.85, 1.0, 1.0)
	title.position = Vector2(0, 16)
	title.size = Vector2(200, 18)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Los 8 Robot Masters caídos.\nPróximo hito: asalto CORE-9."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.75, 0.7, 0.9, 0.9)
	sub.position = Vector2(8, 40)
	sub.size = Vector2(184, 28)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)

	var back := Button.new()
	back.name = "ReturnButton"
	back.text = "Volver al selector"
	back.add_theme_font_size_override("font_size", 8)
	back.position = Vector2(58, 170)
	back.size = Vector2(140, 24)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.16, 0.1, 0.22, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.85, 0.3, 0.95, 1.0)
	bn.set_corner_radius_all(3)
	var bh := bn.duplicate()
	bh.bg_color = bn.bg_color.lightened(0.12)
	var bp := bn.duplicate()
	bp.bg_color = bn.bg_color.darkened(0.15)
	back.add_theme_stylebox_override("normal", bn)
	back.add_theme_stylebox_override("hover", bh)
	back.add_theme_stylebox_override("pressed", bp)
	back.add_theme_stylebox_override("focus", bh)
	back.pressed.connect(_on_return)
	add_child(back)


func _on_return() -> void:
	get_tree().change_scene_to_file(BOSS_SELECT)
