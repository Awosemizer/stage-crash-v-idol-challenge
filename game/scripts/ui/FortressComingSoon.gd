extends Control
## Hub Fortaleza CORE-9 — entrada al asalto lineal (Lobby Neon → … → Ending).

const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const LOBBY := "res://scenes/levels/LevelFortressLobby.tscn"


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
	panel.size = Vector2(210, 110)
	panel.position = Vector2(23, 48)
	add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Fortaleza CORE-9"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.modulate = Color(0.95, 0.85, 1.0, 1.0)
	title.position = Vector2(0, 10)
	title.size = Vector2(210, 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Lobby Neon → Voice Archive\n→ Core Shaft → Heart of CORE-9"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 6)
	sub.modulate = Color(0.75, 0.7, 0.9, 0.9)
	sub.position = Vector2(8, 32)
	sub.size = Vector2(194, 36)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)

	var enter := Button.new()
	enter.name = "EnterButton"
	enter.text = "Entrar al asalto"
	enter.add_theme_font_size_override("font_size", 8)
	enter.position = Vector2(35, 78)
	enter.size = Vector2(140, 22)
	_style_btn(enter, Color(0.2, 0.1, 0.28, 0.95), Color(0.85, 0.3, 0.95))
	enter.pressed.connect(_on_enter)
	panel.add_child(enter)

	var back := Button.new()
	back.name = "ReturnButton"
	back.text = "Volver al selector"
	back.add_theme_font_size_override("font_size", 8)
	back.position = Vector2(58, 175)
	back.size = Vector2(140, 24)
	_style_btn(back, Color(0.16, 0.1, 0.22, 0.95), Color(0.85, 0.3, 0.95))
	back.pressed.connect(_on_return)
	add_child(back)


func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var bn := StyleBoxFlat.new()
	bn.bg_color = bg
	bn.set_border_width_all(2)
	bn.border_color = border
	bn.set_corner_radius_all(3)
	var bh := bn.duplicate()
	bh.bg_color = bg.lightened(0.12)
	var bp := bn.duplicate()
	bp.bg_color = bg.darkened(0.15)
	btn.add_theme_stylebox_override("normal", bn)
	btn.add_theme_stylebox_override("hover", bh)
	btn.add_theme_stylebox_override("pressed", bp)
	btn.add_theme_stylebox_override("focus", bh)


func _on_enter() -> void:
	print("Fortaleza: entrando Lobby Neon")
	get_tree().change_scene_to_file(LOBBY)


func _on_return() -> void:
	get_tree().change_scene_to_file(BOSS_SELECT)
