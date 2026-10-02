extends Control
## Créditos stub → Boss Select.

const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"


func _ready() -> void:
	_build_ui()
	get_tree().create_timer(6.0).timeout.connect(_go_select)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.text = "CRÉDITOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(0.85, 0.9, 1.0)
	title.position = Vector2(0, 28)
	title.size = Vector2(256, 18)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var body := Label.new()
	body.name = "Body"
	body.text = (
		"Stage Crash: V-Idol Challenge\n"
		+ "Prototipo Godot 4.5\n\n"
		+ "Diseño / código: Luis L +\n"
		+ "asistente Grok\n\n"
		+ "Hatsune Miku · Kasane Teto\n"
		+ "(personajes de sus creadores)\n\n"
		+ "¡Gracias por jugar!"
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 6)
	body.modulate = Color(0.75, 0.8, 0.9, 0.95)
	body.position = Vector2(24, 54)
	body.size = Vector2(208, 120)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	var btn := Button.new()
	btn.name = "ReturnButton"
	btn.text = "Volver al selector"
	btn.add_theme_font_size_override("font_size", 8)
	btn.position = Vector2(58, 185)
	btn.size = Vector2(140, 24)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.55, 0.7, 0.95)
	bn.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", bn)
	btn.pressed.connect(_go_select)
	add_child(btn)


func _go_select() -> void:
	get_tree().change_scene_to_file(BOSS_SELECT)
