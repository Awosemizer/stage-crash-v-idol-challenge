extends Control
## Selección de personaje — Miku (cian) / Teto (rojo). Guarda en GameState.

const BOSS_SELECT_SCENE := "res://scenes/ui/BossSelect.tscn"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.07, 0.06, 0.11, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var header := Label.new()
	header.name = "Header"
	header.text = "Elige tu V-Idol"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.modulate = Color(0.95, 0.95, 1.0, 1.0)
	header.position = Vector2(0, 10)
	header.size = Vector2(256, 16)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Miku: Buster  ·  Teto: Sable"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 7)
	hint.modulate = Color(0.7, 0.75, 0.85, 0.8)
	hint.position = Vector2(0, 28)
	hint.size = Vector2(256, 10)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	# Miku button (left)
	var miku_btn := Button.new()
	miku_btn.name = "MikuButton"
	miku_btn.text = "MIKU\nBuster"
	miku_btn.add_theme_font_size_override("font_size", 11)
	miku_btn.position = Vector2(16, 56)
	miku_btn.size = Vector2(104, 120)
	_style_char_button(miku_btn, Color(0.08, 0.35, 0.45, 0.95), Color(0.25, 0.9, 0.98, 1.0))
	miku_btn.pressed.connect(_on_miku)
	add_child(miku_btn)

	var miku_swatch := ColorRect.new()
	miku_swatch.name = "MikuSwatch"
	miku_swatch.color = GameState.COLOR_MIKU
	miku_swatch.position = Vector2(48, 72)
	miku_swatch.size = Vector2(40, 40)
	miku_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Swatch sits above button visually but won't block if we put it as child
	miku_btn.add_child(miku_swatch)
	miku_swatch.position = Vector2(32, 12)
	# Rebuild button text layout: clear default and use labels
	miku_btn.text = ""
	var miku_name := Label.new()
	miku_name.text = "MIKU"
	miku_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miku_name.add_theme_font_size_override("font_size", 12)
	miku_name.modulate = Color(0.4, 0.95, 1.0, 1.0)
	miku_name.position = Vector2(0, 58)
	miku_name.size = Vector2(104, 16)
	miku_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_name)
	var miku_sub := Label.new()
	miku_sub.text = "Buster +"
	miku_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miku_sub.add_theme_font_size_override("font_size", 7)
	miku_sub.modulate = Color(0.8, 0.95, 1.0, 0.9)
	miku_sub.position = Vector2(0, 78)
	miku_sub.size = Vector2(104, 12)
	miku_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_sub)
	var miku_sub2 := Label.new()
	miku_sub2.text = "carga"
	miku_sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miku_sub2.add_theme_font_size_override("font_size", 7)
	miku_sub2.modulate = Color(0.75, 0.9, 1.0, 0.85)
	miku_sub2.position = Vector2(0, 90)
	miku_sub2.size = Vector2(104, 12)
	miku_sub2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_sub2)

	# Teto button (right)
	var teto_btn := Button.new()
	teto_btn.name = "TetoButton"
	teto_btn.text = ""
	teto_btn.add_theme_font_size_override("font_size", 11)
	teto_btn.position = Vector2(136, 56)
	teto_btn.size = Vector2(104, 120)
	_style_char_button(teto_btn, Color(0.4, 0.1, 0.15, 0.95), Color(0.95, 0.35, 0.4, 1.0))
	teto_btn.pressed.connect(_on_teto)
	add_child(teto_btn)

	var teto_swatch := ColorRect.new()
	teto_swatch.name = "TetoSwatch"
	teto_swatch.color = GameState.COLOR_TETO
	teto_swatch.position = Vector2(32, 12)
	teto_swatch.size = Vector2(40, 40)
	teto_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_swatch)

	var teto_name := Label.new()
	teto_name.text = "TETO"
	teto_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teto_name.add_theme_font_size_override("font_size", 12)
	teto_name.modulate = Color(1.0, 0.45, 0.5, 1.0)
	teto_name.position = Vector2(0, 58)
	teto_name.size = Vector2(104, 16)
	teto_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_name)
	var teto_sub := Label.new()
	teto_sub.text = "Sable"
	teto_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teto_sub.add_theme_font_size_override("font_size", 7)
	teto_sub.modulate = Color(1.0, 0.8, 0.82, 0.9)
	teto_sub.position = Vector2(0, 78)
	teto_sub.size = Vector2(104, 12)
	teto_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_sub)
	var teto_sub2 := Label.new()
	teto_sub2.text = "cuerpo a cuerpo"
	teto_sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teto_sub2.add_theme_font_size_override("font_size", 6)
	teto_sub2.modulate = Color(0.95, 0.75, 0.78, 0.85)
	teto_sub2.position = Vector2(0, 90)
	teto_sub2.size = Vector2(104, 12)
	teto_sub2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_sub2)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 8)
	back.position = Vector2(8, 196)
	back.size = Vector2(56, 20)
	_style_char_button(back, Color(0.2, 0.2, 0.28, 0.9), Color(0.6, 0.65, 0.75, 0.8))
	back.pressed.connect(_on_back)
	add_child(back)


func _style_char_button(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.12)
	hover.border_color = border.lightened(0.2)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.15)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)


func _on_miku() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.select_miku()
	get_tree().change_scene_to_file(BOSS_SELECT_SCENE)


func _on_teto() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.select_teto()
	get_tree().change_scene_to_file(BOSS_SELECT_SCENE)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
