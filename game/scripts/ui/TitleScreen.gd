extends Control
## Pantalla de título — Stage Crash: V-Idol Challenge.
## Landscape-phone layout via SafeArea; primary buttons ≥44px when space allows.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const SAVE_SELECT := "res://scenes/ui/SaveSelect.tscn"
const SELECT_SCENE := "res://scenes/ui/CharacterSelect.tscn"

const DESIGN_W := 280.0


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
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
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var accent2 := ColorRect.new()
	accent2.name = "AccentBar2"
	accent2.color = Color(0.92, 0.28, 0.35, 0.85)
	accent2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent2)

	var chrome_tex := ArtKit.panel_chrome_tex()
	if chrome_tex:
		var chrome := ArtKit.make_texture_rect(chrome_tex, Vector2(220, 56), Vector2(0, 0))
		chrome.name = "PanelChrome"
		chrome.modulate = Color(1, 1, 1, 0.55)
		add_child(chrome)

	var logo_tex := ArtKit.load_tex("res://assets/sprites/ui/synthocorp_mark.png")
	if logo_tex:
		var logo := ArtKit.make_texture_rect(logo_tex, Vector2(18, 18), Vector2(0, 0))
		logo.name = "SynthoMark"
		add_child(logo)

	var banner_tex := ArtKit.title_banner_tex()
	if banner_tex:
		var banner := ArtKit.make_texture_rect(banner_tex, Vector2(200, 28), Vector2(0, 0))
		banner.name = "TitleBanner"
		add_child(banner)

	var miku_p := ArtKit.char_portrait_tex(false)
	var teto_p := ArtKit.char_portrait_tex(true)
	if miku_p:
		var mp := ArtKit.make_texture_rect(miku_p, Vector2(32, 32), Vector2(0, 0))
		mp.name = "PortraitMiku"
		add_child(mp)
	if teto_p:
		var tp := ArtKit.make_texture_rect(teto_p, Vector2(32, 32), Vector2(0, 0))
		tp.name = "PortraitTeto"
		add_child(tp)

	var title := Label.new()
	title.name = "Title"
	title.text = "Stage Crash:"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.45, 0.95, 1.0, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "V-Idol Challenge"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(1.0, 0.95, 0.98, 1.0)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var tag := Label.new()
	tag.name = "Tagline"
	tag.text = "Miku × Teto"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 9)
	tag.modulate = Color(0.75, 0.8, 0.9, 0.85)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	var has_saves := GameState.any_slot_exists()

	var continue_btn := Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "Continuar"
	continue_btn.add_theme_font_size_override("font_size", 12)
	_SafeArea.style_button(continue_btn, Color(0.12, 0.4, 0.28, 0.95), Color(0.4, 0.95, 0.6, 1.0))
	continue_btn.disabled = not has_saves
	if not has_saves:
		continue_btn.modulate = Color(0.55, 0.55, 0.6, 1.0)
	continue_btn.pressed.connect(_on_continue_pressed)
	add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.name = "NewGameButton"
	new_btn.text = "Nueva partida"
	new_btn.add_theme_font_size_override("font_size", 12)
	_SafeArea.style_button(new_btn, Color(0.15, 0.55, 0.7, 0.95), Color(0.35, 0.9, 1.0, 1.0))
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

	var ach_btn := Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "Logros"
	ach_btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(ach_btn, Color(0.22, 0.18, 0.08, 0.95), Color(1.0, 0.85, 0.3, 1.0))
	ach_btn.pressed.connect(_on_achievements_pressed)
	add_child(ach_btn)

	var mute_btn := Button.new()
	mute_btn.name = "MuteButton"
	mute_btn.add_theme_font_size_override("font_size", 9)
	_SafeArea.style_button(mute_btn, Color(0.16, 0.16, 0.22, 0.95), Color(0.65, 0.7, 0.8, 0.9))
	mute_btn.pressed.connect(_on_mute_pressed)
	add_child(mute_btn)
	_refresh_mute_label(mute_btn)

	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.29.0-proto · fortress/ending polish"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 7)
	ver.modulate = Color(0.55, 0.6, 0.7, 0.75)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var ox := _SafeArea.center_x(DESIGN_W, area)
	# Compact header when vertical space is tight (short phones / tall safe insets)
	var tight := area.size.y < 200.0
	var header_h := 78.0 if tight else 96.0

	var accent := get_node_or_null("AccentBar") as ColorRect
	if accent:
		accent.position = Vector2(0, area.position.y + (34.0 if tight else 42.0))
		accent.size = Vector2(vp.x, 3)
	var accent2 := get_node_or_null("AccentBar2") as ColorRect
	if accent2:
		accent2.position = Vector2(0, area.position.y + (38.0 if tight else 46.0))
		accent2.size = Vector2(vp.x, 2)

	var chrome := get_node_or_null("PanelChrome") as Control
	if chrome:
		chrome.visible = not tight
		chrome.position = Vector2(ox + 30, area.position.y + 6.0)
		chrome.size = Vector2(220, 56)

	var logo := get_node_or_null("SynthoMark") as Control
	if logo:
		logo.position = Vector2(area.position.x, area.position.y + 4.0)

	var title := get_node_or_null("Title") as Label
	if title:
		title.position = Vector2(area.position.x, area.position.y + (4.0 if tight else 8.0))
		title.size = Vector2(area.size.x, 20)
		title.add_theme_font_size_override("font_size", 14 if tight else 16)

	var subtitle := get_node_or_null("Subtitle") as Label
	if subtitle:
		subtitle.position = Vector2(area.position.x, area.position.y + (26.0 if tight else 52.0))
		subtitle.size = Vector2(area.size.x, 20)
		subtitle.add_theme_font_size_override("font_size", 15 if tight else 18)

	var tag := get_node_or_null("Tagline") as Label
	if tag:
		tag.position = Vector2(area.position.x, area.position.y + (48.0 if tight else 74.0))
		tag.size = Vector2(area.size.x, 12)

	var banner := get_node_or_null("TitleBanner") as Control
	if banner:
		# Hide banner on tight layouts so it never overlaps the button stack
		banner.visible = not tight
		banner.position = Vector2(ox + 40, area.position.y + 88.0)
		banner.size = Vector2(200, 24)

	var mp := get_node_or_null("PortraitMiku") as Control
	if mp:
		mp.visible = not tight
		mp.position = Vector2(area.position.x + 4.0, area.position.y + header_h)
	var tp := get_node_or_null("PortraitTeto") as Control
	if tp:
		tp.visible = not tight
		tp.position = Vector2(area.end.x - 36.0, area.position.y + header_h)

	# Primary stack: Continuar / Nueva / Logros — prefer 44px; reserve mute+version strip
	var btn_w := minf(160.0, area.size.x - 24.0)
	var stack_top := area.position.y + header_h
	var stack_bottom := area.end.y - 30.0
	var avail := maxf(stack_bottom - stack_top, 90.0)
	var btn_h := _SafeArea.btn_h(avail, 3, 6.0, true)
	var bx := area.position.x + (area.size.x - btn_w) * 0.5

	var continue_btn := get_node_or_null("ContinueButton") as Button
	var new_btn := get_node_or_null("NewGameButton") as Button
	var ach_btn := get_node_or_null("AchievementsButton") as Button
	if continue_btn:
		continue_btn.position = Vector2(bx, stack_top)
		continue_btn.size = Vector2(btn_w, btn_h)
		continue_btn.add_theme_font_size_override("font_size", 12 if btn_h >= 36.0 else 10)
	if new_btn:
		new_btn.position = Vector2(bx, stack_top + btn_h + 6.0)
		new_btn.size = Vector2(btn_w, btn_h)
		new_btn.add_theme_font_size_override("font_size", 12 if btn_h >= 36.0 else 10)
	if ach_btn:
		ach_btn.position = Vector2(bx, stack_top + (btn_h + 6.0) * 2.0)
		ach_btn.size = Vector2(btn_w, maxf(btn_h * 0.85, _SafeArea.MIN_BTN_H))
		ach_btn.add_theme_font_size_override("font_size", 11 if btn_h >= 36.0 else 9)

	var mute := get_node_or_null("MuteButton") as Button
	if mute:
		mute.size = Vector2(96, maxf(_SafeArea.MIN_BTN_H_SECONDARY, 22.0))
		mute.position = Vector2(area.end.x - mute.size.x, area.end.y - mute.size.y)

	var ver := get_node_or_null("Version") as Label
	if ver:
		# Keep clear of mute button (left side)
		ver.position = Vector2(area.position.x, area.end.y - 12.0)
		ver.size = Vector2(maxf(area.size.x - mute.size.x - 8.0, 60.0), 12)
		ver.clip_text = true


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
