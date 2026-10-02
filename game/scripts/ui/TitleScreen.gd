extends Control
## Pantalla de título — Stage Crash: V-Idol Challenge.
## Continuar / Nueva partida → selector de slots.

const SAVE_SELECT := "res://scenes/ui/SaveSelect.tscn"
const SELECT_SCENE := "res://scenes/ui/CharacterSelect.tscn"


func _ready() -> void:
	_build_ui()
	if AudioManager:
		AudioManager.play_bgm("title")


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

	var chrome_tex := ArtKit.panel_chrome_tex()
	if chrome_tex:
		var chrome := ArtKit.make_texture_rect(chrome_tex, Vector2(200, 56), Vector2(28, 10))
		chrome.name = "PanelChrome"
		chrome.modulate = Color(1, 1, 1, 0.55)
		add_child(chrome)

	var logo_tex := ArtKit.load_tex("res://assets/sprites/ui/synthocorp_mark.png")
	if logo_tex:
		var logo := ArtKit.make_texture_rect(logo_tex, Vector2(18, 18), Vector2(8, 6))
		logo.name = "SynthoMark"
		add_child(logo)

	var banner_tex := ArtKit.title_banner_tex()
	if banner_tex:
		var banner := ArtKit.make_texture_rect(banner_tex, Vector2(192, 28), Vector2(32, 88))
		banner.name = "TitleBanner"
		add_child(banner)
	var miku_p := ArtKit.char_portrait_tex(false)
	var teto_p := ArtKit.char_portrait_tex(true)
	if miku_p:
		var mp := ArtKit.make_texture_rect(miku_p, Vector2(28, 28), Vector2(8, 112))
		mp.name = "PortraitMiku"
		add_child(mp)
	if teto_p:
		var tp := ArtKit.make_texture_rect(teto_p, Vector2(28, 28), Vector2(220, 112))
		tp.name = "PortraitTeto"
		add_child(tp)

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

	var sparks := Control.new()
	sparks.name = "TitleSparkles"
	sparks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sparks)
	for i in 6:
		var d := ColorRect.new()
		d.size = Vector2(2, 2)
		d.position = Vector2(24 + i * 36, 100 + (i % 3) * 8)
		d.color = Color(0.7, 0.9, 1.0, 0.35 + 0.1 * (i % 3))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparks.add_child(d)

	var has_saves := GameState.any_slot_exists()

	var continue_btn := Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "Continuar"
	continue_btn.add_theme_font_size_override("font_size", 11)
	continue_btn.position = Vector2(68, 108)
	continue_btn.size = Vector2(120, 28)
	_style_button(continue_btn, Color(0.12, 0.4, 0.28, 0.95), Color(0.4, 0.95, 0.6, 1.0))
	continue_btn.disabled = not has_saves
	if not has_saves:
		continue_btn.modulate = Color(0.55, 0.55, 0.6, 1.0)
	continue_btn.pressed.connect(_on_continue_pressed)
	add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.name = "NewGameButton"
	new_btn.text = "Nueva partida"
	new_btn.add_theme_font_size_override("font_size", 11)
	new_btn.position = Vector2(68, 142)
	new_btn.size = Vector2(120, 28)
	_style_button(new_btn, Color(0.15, 0.55, 0.7, 0.95), Color(0.35, 0.9, 1.0, 1.0))
	new_btn.pressed.connect(_on_new_game_pressed)
	add_child(new_btn)

	# Alias legacy para validadores / atajos: PlayButton = Nueva partida
	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "Jugar"
	play_btn.visible = false
	play_btn.position = Vector2(0, 0)
	play_btn.size = Vector2(1, 1)
	play_btn.pressed.connect(_on_new_game_pressed)
	add_child(play_btn)

	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.20.0-proto · landscape+Beatfire"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 6)
	ver.modulate = Color(0.55, 0.6, 0.7, 0.7)
	ver.position = Vector2(0, 202)
	ver.size = Vector2(170, 10)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	var ach_btn := Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "Logros"
	ach_btn.add_theme_font_size_override("font_size", 9)
	ach_btn.position = Vector2(68, 176)
	ach_btn.size = Vector2(120, 22)
	_style_button(ach_btn, Color(0.22, 0.18, 0.08, 0.95), Color(1.0, 0.85, 0.3, 1.0))
	ach_btn.pressed.connect(_on_achievements_pressed)
	add_child(ach_btn)

	var mute_btn := Button.new()
	mute_btn.name = "MuteButton"
	mute_btn.add_theme_font_size_override("font_size", 7)
	mute_btn.position = Vector2(176, 202)
	mute_btn.size = Vector2(72, 16)
	_style_button(mute_btn, Color(0.16, 0.16, 0.22, 0.95), Color(0.65, 0.7, 0.8, 0.9))
	mute_btn.pressed.connect(_on_mute_pressed)
	add_child(mute_btn)
	_refresh_mute_label(mute_btn)

	# Center the 256-wide design cluster on wide landscape viewports
	get_viewport().size_changed.connect(_center_design_cluster)
	call_deferred("_center_design_cluster")


func _center_design_cluster() -> void:
	var vp := get_viewport().get_visible_rect().size
	var design_w := 256.0
	var ox := maxf((vp.x - design_w) * 0.5, 0.0)
	for child in get_children():
		if child is Control and child.name != "BG":
			# Shift from original 256-wide layout into centered cluster
			if child.has_meta("title_ox"):
				child.position.x = float(child.get_meta("title_base_x")) + ox
			else:
				child.set_meta("title_base_x", child.position.x)
				child.set_meta("title_ox", true)
				child.position.x = float(child.get_meta("title_base_x")) + ox
		if child.name in ["AccentBar", "AccentBar2", "BG"]:
			if child is ColorRect and child.name != "BG":
				child.position.x = 0
				child.size.x = vp.x
	# Full-width labels
	for n in ["Title", "Subtitle", "Tagline"]:
		var lbl := get_node_or_null(n) as Label
		if lbl:
			lbl.position.x = 0
			lbl.size.x = vp.x


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
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	disabled.border_color = Color(0.35, 0.35, 0.4, 0.7)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


func _on_continue_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.save_ui_mode = "continue"
	get_tree().change_scene_to_file(SAVE_SELECT)


func _on_new_game_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.save_ui_mode = "new"
	get_tree().change_scene_to_file(SAVE_SELECT)


func _on_play_pressed() -> void:
	## Compat: Jugar = Nueva partida
	_on_new_game_pressed()


func _refresh_mute_label(btn: Button = null) -> void:
	var b := btn
	if b == null:
		b = get_node_or_null("MuteButton") as Button
	if b == null:
		return
	var is_muted := AudioManager.is_muted() if AudioManager else false
	b.text = "Sonido: OFF" if is_muted else "Sonido: ON"


func _on_mute_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
		AudioManager.toggle_mute()
	_refresh_mute_label()


func _on_achievements_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	Engine.set_meta("achievements_return", "title")
	get_tree().change_scene_to_file("res://scenes/ui/AchievementsScreen.tscn")
