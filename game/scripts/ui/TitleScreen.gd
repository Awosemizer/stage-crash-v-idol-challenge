extends Control
## Pantalla de título — Stage Crash: V-Idol Challenge.
## Botón Jugar → selección de personaje.

const SELECT_SCENE := "res://scenes/ui/CharacterSelect.tscn"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.06, 0.05, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var accent := ColorRect.new()
	accent.name = "AccentBar"
	accent.color = Color(0.25, 0.85, 0.95, 0.85)
	accent.position = Vector2(0, 48)
	accent.size = Vector2(256, 3)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var accent2 := ColorRect.new()
	accent2.name = "AccentBar2"
	accent2.color = Color(0.92, 0.28, 0.35, 0.85)
	accent2.position = Vector2(0, 52)
	accent2.size = Vector2(256, 2)
	accent2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent2)

	var title := Label.new()
	title.name = "Title"
	title.text = "Stage Crash:"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(0.45, 0.95, 1.0, 1.0)
	title.position = Vector2(0, 18)
	title.size = Vector2(256, 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "V-Idol Challenge"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(1.0, 0.95, 0.98, 1.0)
	subtitle.position = Vector2(0, 58)
	subtitle.size = Vector2(256, 22)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var tag := Label.new()
	tag.name = "Tagline"
	tag.text = "Miku × Teto"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 8)
	tag.modulate = Color(0.75, 0.8, 0.9, 0.85)
	tag.position = Vector2(0, 82)
	tag.size = Vector2(256, 12)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "Jugar"
	play_btn.add_theme_font_size_override("font_size", 12)
	play_btn.position = Vector2(68, 130)
	play_btn.size = Vector2(120, 36)
	_style_button(play_btn, Color(0.15, 0.55, 0.7, 0.95), Color(0.35, 0.9, 1.0, 1.0))
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)

	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.3.0-proto · Android"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 6)
	ver.modulate = Color(0.55, 0.6, 0.7, 0.7)
	ver.position = Vector2(0, 200)
	ver.size = Vector2(256, 10)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)


func _style_button(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.15)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.2)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(SELECT_SCENE)
