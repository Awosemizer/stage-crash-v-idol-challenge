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
	bg.color = Color(0.02, 0.02, 0.03, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var concert := ArtKit.menu_backdrop("res://assets/sprites/ui/menu_concert.png")
	if concert:
		concert.name = "MenuBG"
		add_child(concert)
	# v0.58: marco de concierto (velo + banda de cabecera) — el título ya no pisa los botones.
	ArtKit.add_menu_frame(self)

	# Logo pixel (cabecera); el layout lo coloca junto al SynthoMark.
	var logo_px := ArtKit.load_tex("res://assets/sprites/ui/logo_stage_crash.png")
	if logo_px:
		var logo_word := ArtKit.make_texture_rect(logo_px, Vector2(96, 20), Vector2.ZERO)
		logo_word.name = "PixelLogo"
		logo_word.modulate = Color(1, 1, 1, 0.9)
		add_child(logo_word)

	# Tira de luces del kit como fondo de la cabecera.
	var banner_tex := ArtKit.title_banner_tex()
	if banner_tex:
		var banner := ArtKit.make_texture_rect(banner_tex, Vector2(398, 60), Vector2(0, 0))
		banner.name = "TitleBanner"
		banner.modulate = Color(1, 1, 1, 0.45)
		add_child(banner)

	var logo_tex := ArtKit.load_tex("res://assets/sprites/ui/synthocorp_mark.png")
	if logo_tex:
		var logo := ArtKit.make_texture_rect(logo_tex, Vector2(18, 18), Vector2(0, 0))
		logo.name = "SynthoMark"
		add_child(logo)

	# Las dos V-Idols a los lados (sprite real del juego; retrato pixel si falta).
	for who in ["Miku", "Teto"]:
		var is_teto: bool = who == "Teto"
		var tex := ArtKit.load_tex("res://assets/sprites/player/%s_idle.png" % who.to_lower())
		if tex == null:
			tex = ArtKit.char_portrait_tex(is_teto)
		if tex:
			var pr := ArtKit.make_texture_rect(tex, Vector2(84, 84), Vector2(0, 0))
			pr.name = "Portrait" + who
			pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			pr.flip_h = is_teto
			add_child(pr)
			var spot := ColorRect.new()
			spot.name = "Spot" + who
			spot.color = (Color(0.25, 0.85, 0.95, 0.16) if not is_teto else Color(0.95, 0.3, 0.45, 0.16))
			spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(spot)
			move_child(spot, pr.get_index())

	var title := Label.new()
	title.name = "Title"
	title.text = "STAGE CRASH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(title, 22, Color(0.45, 0.95, 1.0, 1.0), 4)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "V-Idol Challenge"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(subtitle, 13, Color(1.0, 0.62, 0.82, 1.0), 3)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var tag := Label.new()
	tag.name = "Tagline"
	tag.text = "Miku × Teto · SynthoCorp"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 8)
	tag.modulate = Color(0.75, 0.8, 0.9, 0.85)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	# Marco del menú (chrome del kit) detrás de la columna de botones.
	var chrome_tex := ArtKit.panel_chrome_tex()
	if chrome_tex:
		var chrome := ArtKit.make_texture_rect(chrome_tex, Vector2(170, 130), Vector2(0, 0))
		chrome.name = "PanelChrome"
		chrome.modulate = Color(1, 1, 1, 0.85)
		add_child(chrome)

	var has_saves := GameState.any_slot_exists()

	var continue_btn := Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "Continuar"
	continue_btn.add_theme_font_size_override("font_size", 12)
	_SafeArea.style_button(continue_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	continue_btn.disabled = not has_saves
	if not has_saves:
		continue_btn.tooltip_text = "Aún no hay partidas"
	continue_btn.pressed.connect(_on_continue_pressed)
	add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.name = "NewGameButton"
	new_btn.text = "Nueva partida"
	new_btn.add_theme_font_size_override("font_size", 12)
	_SafeArea.style_button(new_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.95, 0.35, 0.72, 1.0), 2)
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
	_SafeArea.style_button(ach_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	ach_btn.pressed.connect(_on_achievements_pressed)
	add_child(ach_btn)

	var mute_btn := Button.new()
	mute_btn.name = "MuteButton"
	mute_btn.add_theme_font_size_override("font_size", 9)
	_SafeArea.style_button(mute_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.95, 0.35, 0.72, 1.0), 2)
	mute_btn.pressed.connect(_on_mute_pressed)
	add_child(mute_btn)
	_refresh_mute_label(mute_btn)

	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.59.0-proto · run"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ver.add_theme_font_size_override("font_size", 8)
	ver.modulate = Color(0.55, 0.6, 0.7, 0.75)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)


func _layout() -> void:
	## v0.58 landscape: cabecera (título) arriba, V-Idols a los lados, columna de botones al centro.
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var tight := area.size.y < 190.0
	var band_bottom := area.position.y + (44.0 if tight else 54.0)
	ArtKit.layout_menu_frame(self, band_bottom)

	var banner := get_node_or_null("TitleBanner") as Control
	if banner:
		banner.position = Vector2(0, 0)
		banner.size = Vector2(vp.x, band_bottom)
	var logo := get_node_or_null("SynthoMark") as Control
	if logo:
		logo.position = Vector2(area.position.x, area.position.y + 2.0)
	var pixel_logo := get_node_or_null("PixelLogo") as Control
	if pixel_logo:
		# Cabecera centrada bajo el título en tight; a la derecha del SynthoMark si hay espacio.
		var lw := 88.0 if tight else 110.0
		pixel_logo.size = Vector2(lw, 18.0 if tight else 22.0)
		pixel_logo.position = Vector2(area.position.x + (area.size.x - lw) * 0.5, area.position.y + (0.0 if tight else 2.0))
		pixel_logo.visible = tight  # en landscape amplio el título tipográfico basta; en tight el logo pixel ayuda

	var title := get_node_or_null("Title") as Label
	if title:
		title.position = Vector2(area.position.x, area.position.y - 2.0)
		title.size = Vector2(area.size.x, 28)
		title.add_theme_font_size_override("font_size", 18 if tight else 22)
	var subtitle := get_node_or_null("Subtitle") as Label
	if subtitle:
		subtitle.position = Vector2(area.position.x, area.position.y + (20.0 if tight else 25.0))
		subtitle.size = Vector2(area.size.x, 16)
	var tag := get_node_or_null("Tagline") as Label
	if tag:
		tag.visible = not tight
		tag.position = Vector2(area.position.x, area.position.y + 41.0)
		tag.size = Vector2(area.size.x, 11)

	# Columna de botones
	var btn_w := minf(156.0, area.size.x * 0.42)
	var gap := 6.0
	var stack_top := band_bottom + 12.0
	var foot := 24.0
	var avail := area.end.y - foot - 6.0 - stack_top
	var btn_h := clampf((avail - gap * 2.0) / 3.0, _SafeArea.MIN_BTN_H, 36.0)
	var bx := area.position.x + (area.size.x - btn_w) * 0.5
	var names := ["ContinueButton", "NewGameButton", "AchievementsButton"]
	for i in names.size():
		var b := get_node_or_null(names[i]) as Button
		if b:
			b.position = Vector2(bx, stack_top + float(i) * (btn_h + gap))
			b.size = Vector2(btn_w, btn_h)
			b.add_theme_font_size_override("font_size", 12 if btn_h >= 32.0 else 10)
	var chrome := get_node_or_null("PanelChrome") as Control
	if chrome:
		chrome.position = Vector2(bx - 8.0, stack_top - 6.0)
		chrome.size = Vector2(btn_w + 16.0, btn_h * 3.0 + gap * 2.0 + 12.0)

	# V-Idols a los lados de la columna
	var side_w := bx - 8.0 - area.position.x
	var ps := clampf(minf(side_w, area.end.y - stack_top - 4.0), 48.0, 96.0)
	for who in ["Miku", "Teto"]:
		var pr := get_node_or_null("Portrait" + who) as Control
		var spot := get_node_or_null("Spot" + who) as Control
		if pr == null:
			continue
		var px := area.position.x + (side_w - ps) * 0.5 if who == "Miku" else area.end.x - side_w + (side_w - ps) * 0.5
		pr.position = Vector2(px, stack_top + 2.0)
		pr.size = Vector2(ps, ps)
		pr.visible = side_w >= 44.0
		if spot:
			spot.position = Vector2(px + ps * 0.15, stack_top)
			spot.size = Vector2(ps * 0.7, area.end.y - foot - stack_top)
			spot.visible = pr.visible

	var mute := get_node_or_null("MuteButton") as Button
	if mute:
		mute.size = Vector2(92, foot)
		mute.position = Vector2(area.end.x - mute.size.x, area.end.y - foot)
		mute.add_theme_font_size_override("font_size", 9)
	var ver := get_node_or_null("Version") as Label
	if ver:
		ver.position = Vector2(area.position.x, area.end.y - 12.0)
		ver.size = Vector2(maxf(area.size.x - 100.0, 60.0), 12)
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
