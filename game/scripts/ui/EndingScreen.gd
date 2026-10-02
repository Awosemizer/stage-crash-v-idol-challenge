extends Control
## Ending — texto distinto Miku / Teto → créditos.

const CREDITS := "res://scenes/ui/CreditsScreen.tscn"


func _ready() -> void:
	_build_ui()
	get_tree().create_timer(5.5).timeout.connect(_go_credits)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var accent := ColorRect.new()
	accent.color = Color(0.85, 0.35, 0.95, 0.9)
	accent.position = Vector2(0, 36)
	accent.size = Vector2(256, 2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "STAGE CLEAR"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.modulate = Color(0.95, 0.6, 1.0, 1.0)
	header.position = Vector2(0, 48)
	header.size = Vector2(256, 20)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var is_teto := GameState.is_teto() if GameState.has_method("is_teto") else false
	var body := Label.new()
	body.name = "Body"
	if is_teto:
		body.text = (
			"Kasane Teto corta el último acorde.\n"
			+ "SynthoCorp calla. El público —\n"
			+ "virtual o no — grita su nombre.\n\n"
			+ "«No soy un eco. Soy el bis.»"
		)
		body.modulate = Color(1.0, 0.55, 0.6, 1.0)
	else:
		body.text = (
			"Hatsune Miku apaga el núcleo.\n"
			+ "Las luces del escenario vuelven\n"
			+ "a ser solo luces. Ella sonríe.\n\n"
			+ "«El show continúa… con nosotras.»"
		)
		body.modulate = Color(0.45, 0.95, 1.0, 1.0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 7)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(24, 78)
	body.size = Vector2(208, 90)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	var btn := Button.new()
	btn.name = "ContinueButton"
	btn.text = "Créditos"
	btn.add_theme_font_size_override("font_size", 8)
	btn.position = Vector2(78, 180)
	btn.size = Vector2(100, 24)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.14, 0.08, 0.2, 0.95)
	bn.set_border_width_all(2)
	bn.border_color = Color(0.85, 0.35, 0.95)
	bn.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", bn)
	btn.pressed.connect(_go_credits)
	add_child(btn)


func _go_credits() -> void:
	get_tree().change_scene_to_file(CREDITS)
