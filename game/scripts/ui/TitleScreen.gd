extends Control
## Pantalla de título — Stage Crash: V-Idol Challenge (v0.64, look 16-bit comercial).
## 1) Key art a pantalla completa + logo pixel en la banda superior + «PULSA PARA EMPEZAR».
## 2) Menú principal en una franja translúcida abajo: Continuar (si hay partida), Nueva partida,
##    Opciones, Logros. Mando / teclado / táctil con foco visible; fundidos entre pantallas.
## (Mantiene los nodos de v0.58: PixelLogo, Title, PortraitMiku, TitleBanner, PanelChrome,
##  menu_concert como respaldo, add_menu_frame / layout_menu_frame, SafeArea, tight.)

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const MenuKit := preload("res://scripts/ui/MenuKit.gd")
const SAVE_SELECT := "res://scenes/ui/SaveSelect.tscn"
const SELECT_SCENE := "res://scenes/ui/CharacterSelect.tscn"
const KEYART := "res://assets/sprites/ui/title_keyart.png"
const VERSION_TAG := "v0.65"

var _menu_open := false
var _blink: Tween = null


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	MenuKit.fade_in(self, 0.4)
	if AudioManager:
		AudioManager.play_bgm("title")
	# Volver desde otra pantalla del menú: entra directo al menú principal.
	# (los créditos borran title_seen para que el «pulsa» vuelva a salir tras el final)
	if Engine.has_meta("title_seen") and Engine.get_meta("title_seen"):
		call_deferred("_open_menu", false)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.02, 0.01, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var art := MenuKit.add_fullscreen_art(self, KEYART, "KeyArt")
	if art == null:
		var concert := ArtKit.menu_backdrop("res://assets/sprites/ui/menu_concert.png")
		if concert:
			concert.name = "MenuBG"
			add_child(concert)
	ArtKit.add_menu_frame(self)  # velo/banda v0.58 — en v0.64 solo un degradado suave
	for n in ["MenuDim", "HeaderBand", "HeaderLineC", "HeaderLineP"]:
		var c := get_node_or_null(n) as CanvasItem
		if c:
			c.visible = false

	# Banda superior oscura para que el logo destaque sobre el cielo.
	var top_shade := ColorRect.new()
	top_shade.name = "TopShade"
	top_shade.color = Color(0.0, 0.0, 0.04, 0.35)
	top_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_shade)

	var banner_tex := ArtKit.title_banner_tex()
	var banner := ArtKit.make_texture_rect(banner_tex, Vector2(398, 60), Vector2.ZERO) if banner_tex else Control.new()
	banner.name = "TitleBanner"
	banner.visible = false
	add_child(banner)
	for who in ["Miku", "Teto"]:
		var pr := Control.new()  # la key art ya las muestra; nodo legado
		pr.name = "Portrait" + who
		pr.visible = false
		add_child(pr)
	var chrome := Control.new()  # PanelChrome legado (panel_chrome ya no se usa en el título)
	chrome.name = "PanelChrome"
	chrome.visible = false
	add_child(chrome)

	var logo_px := ArtKit.load_tex("res://assets/sprites/ui/logo_stage_crash.png")
	if logo_px:
		var logo_word := ArtKit.make_texture_rect(logo_px, Vector2(148, 85), Vector2.ZERO)
		logo_word.name = "PixelLogo"
		logo_word.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo_word.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(logo_word)

	# v0.65: logo nuevo (264×151, incluye «V-IDOL CHALLENGE»); el texto queda de respaldo.
	var title := MenuKit.label("STAGE CRASH", 30, MenuKit.COL_CYAN, 6)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.visible = logo_px == null
	add_child(title)

	var subtitle := MenuKit.label("V-IDOL CHALLENGE", 11, MenuKit.COL_PINK, 4)
	subtitle.name = "Subtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.visible = logo_px == null
	add_child(subtitle)

	var press := MenuKit.label("PULSA PARA EMPEZAR", 11, Color(1, 1, 1), 3)
	press.name = "PressStart"
	press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(press)

	var strip := ColorRect.new()
	strip.name = "MenuStrip"
	strip.color = Color(0.01, 0.0, 0.05, 0.72)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.visible = false
	add_child(strip)
	var strip_line := ColorRect.new()
	strip_line.name = "MenuStripLine"
	strip_line.color = Color(MenuKit.COL_PINK.r, MenuKit.COL_PINK.g, MenuKit.COL_PINK.b, 0.8)
	strip_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_line.visible = false
	add_child(strip_line)

	var has_saves := GameState.any_slot_exists()
	var defs := [
		["ContinueButton", "Continuar", MenuKit.COL_CYAN, _on_continue_pressed],
		["NewGameButton", "Nueva partida", MenuKit.COL_PINK, _on_new_game_pressed],
		["OptionsButton", "Opciones", MenuKit.COL_CYAN, _on_options_pressed],
		["AchievementsButton", "Logros", MenuKit.COL_PINK, _on_achievements_pressed],
	]
	for d in defs:
		var b := Button.new()
		b.name = d[0]
		b.text = d[1]
		MenuKit.style_button(b, d[2], 11)
		b.pressed.connect(d[3])
		b.visible = false
		add_child(b)
	var cont := get_node("ContinueButton") as Button
	cont.disabled = not has_saves
	cont.set_meta("hide_if_disabled", true)
	if not has_saves:
		cont.tooltip_text = "Aún no hay partidas"

	# Alias legacy para validadores / atajos: PlayButton = Nueva partida
	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "Jugar"
	play_btn.visible = false
	play_btn.size = Vector2(1, 1)
	play_btn.pressed.connect(_on_new_game_pressed)
	add_child(play_btn)

	# Opciones: sonido + dificultad
	var opt := Panel.new()
	opt.name = "OptionsPanel"
	opt.visible = false
	opt.add_theme_stylebox_override("panel", MenuKit.panel_box(MenuKit.COL_CYAN))
	add_child(opt)
	var opt_title := MenuKit.label("OPCIONES", 12, MenuKit.COL_CYAN, 3)
	opt_title.name = "OptionsTitle"
	opt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt.add_child(opt_title)
	var diff := Button.new()
	diff.name = "OptDiffButton"
	MenuKit.style_button(diff, MenuKit.COL_PINK, 11)
	diff.pressed.connect(_on_diff_pressed)
	opt.add_child(diff)
	var close := Button.new()
	close.name = "OptCloseButton"
	close.text = "Cerrar"
	MenuKit.style_button(close, MenuKit.COL_CYAN, 11)
	close.pressed.connect(_on_options_close)
	opt.add_child(close)

	var mute_btn := Button.new()
	mute_btn.name = "MuteButton"  # vive en el panel de opciones (hijo directo por compatibilidad)
	MenuKit.style_button(mute_btn, MenuKit.COL_CYAN, 11)
	mute_btn.pressed.connect(_on_mute_pressed)
	mute_btn.visible = false
	add_child(mute_btn)
	_refresh_mute_label(mute_btn)
	_refresh_diff_label()

	var ver := MenuKit.label(VERSION_TAG, 7, Color(0.75, 0.75, 0.9, 0.7), 2)
	ver.name = "Version"
	add_child(ver)
	var copy := MenuKit.label("© SYNTHOCORP · MIKU × TETO", 7, Color(0.75, 0.75, 0.9, 0.7), 2)
	copy.name = "Tagline"
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(copy)

	_blink = create_tween().set_loops()
	_blink.tween_property(press, "modulate:a", 0.15, 0.45)
	_blink.tween_property(press, "modulate:a", 1.0, 0.45)


func _layout() -> void:
	## Lienzo 398×224: logo arriba, «pulsa» al centro-bajo, franja de menú abajo.
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var tight := area.size.y < 190.0
	ArtKit.layout_menu_frame(self, area.position.y)
	var shade := get_node_or_null("TopShade") as Control
	if shade:
		shade.position = Vector2.ZERO
		shade.size = Vector2(vp.x, area.position.y + 70.0)
	var pl := get_node_or_null("PixelLogo") as Control
	var logo_h := 66.0 if tight else 76.0
	if pl and pl.visible:
		pl.size = Vector2(roundf(logo_h * 264.0 / 151.0), logo_h)
		pl.position = Vector2(roundf(area.position.x + (area.size.x - pl.size.x) * 0.5), area.position.y + 2.0)
	var title := get_node_or_null("Title") as Label
	if title:
		title.position = Vector2(area.position.x, area.position.y + 4.0)
		title.size = Vector2(area.size.x, 36)
		title.add_theme_font_size_override("font_size", 26 if tight else 30)
	var sub := get_node_or_null("Subtitle") as Label
	if sub:
		sub.position = Vector2(area.position.x, area.position.y + 38.0)
		sub.size = Vector2(area.size.x, 14)

	var strip_h := 40.0
	var strip_y := area.end.y - strip_h - 10.0
	var strip := get_node_or_null("MenuStrip") as Control
	if strip:
		strip.position = Vector2(0, strip_y)
		strip.size = Vector2(vp.x, vp.y - strip_y)
	var line := get_node_or_null("MenuStripLine") as Control
	if line:
		line.position = Vector2(0, strip_y)
		line.size = Vector2(vp.x, 1)
	var press := get_node_or_null("PressStart") as Label
	if press:
		press.position = Vector2(area.position.x, strip_y + 8.0)
		press.size = Vector2(area.size.x, 16)

	var shown: Array = []
	for n in ["ContinueButton", "NewGameButton", "OptionsButton", "AchievementsButton"]:
		var b := get_node_or_null(n) as Button
		if b == null:
			continue
		var ok := _menu_open and not (b.disabled and b.has_meta("hide_if_disabled"))
		b.visible = ok
		if ok:
			shown.append(b)
	var gap := 6.0
	var bw := minf(92.0, (area.size.x - gap * float(shown.size() - 1)) / maxf(shown.size(), 1.0))
	var bh := 26.0
	var total := bw * shown.size() + gap * (shown.size() - 1)
	var x := area.position.x + (area.size.x - total) * 0.5
	for b in shown:
		b.position = Vector2(x, strip_y + (strip_h - bh) * 0.5 + 2.0)
		b.size = Vector2(bw, bh)
		x += bw + gap

	var ver := get_node_or_null("Version") as Label
	if ver:
		ver.position = Vector2(area.position.x, area.end.y - 10.0)
		ver.size = Vector2(60, 10)
	var tag := get_node_or_null("Tagline") as Label
	if tag:
		tag.position = Vector2(area.end.x - 200.0, area.end.y - 10.0)
		tag.size = Vector2(200, 10)

	var opt := get_node_or_null("OptionsPanel") as Panel
	if opt:
		var pw := 200.0
		var ph := 112.0
		opt.size = Vector2(pw, ph)
		opt.position = Vector2(area.position.x + (area.size.x - pw) * 0.5, area.position.y + (area.size.y - ph) * 0.5)
		var t := opt.get_node("OptionsTitle") as Label
		t.position = Vector2(0, 6)
		t.size = Vector2(pw, 14)
		var mute := get_node_or_null("MuteButton") as Button
		if mute:
			mute.visible = opt.visible
			mute.size = Vector2(pw - 24.0, 24)
			mute.position = opt.position + Vector2(12, 24)
		var d := opt.get_node("OptDiffButton") as Button
		d.size = Vector2(pw - 24.0, 24)
		d.position = Vector2(12, 52)
		var c := opt.get_node("OptCloseButton") as Button
		c.size = Vector2(96, 24)
		c.position = Vector2((pw - 96.0) * 0.5, 82)


func _input(event: InputEvent) -> void:
	if _menu_open:
		if event.is_action_pressed("ui_cancel"):
			var opt := get_node_or_null("OptionsPanel") as Control
			if opt and opt.visible:
				_on_options_close()
				get_viewport().set_input_as_handled()
		return
	var go := false
	if event is InputEventScreenTouch and event.pressed:
		go = true
	elif event is InputEventMouseButton and event.pressed:
		go = true
	elif event is InputEventKey and event.pressed and not event.echo:
		go = true
	elif event is InputEventJoypadButton and event.pressed:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		_open_menu(true)


func _open_menu(with_sfx := true) -> void:
	if _menu_open:
		return
	_menu_open = true
	Engine.set_meta("title_seen", true)
	if with_sfx and AudioManager:
		AudioManager.play_sfx("ui_confirm")
	var press := get_node_or_null("PressStart") as CanvasItem
	if press:
		press.visible = false
	if _blink:
		_blink.kill()
	for n in ["MenuStrip", "MenuStripLine"]:
		var c := get_node_or_null(n) as CanvasItem
		if c:
			c.visible = true
	_layout()
	_focus_first()


func _focus_first() -> void:
	for n in ["ContinueButton", "NewGameButton"]:
		var b := get_node_or_null(n) as Button
		if b and b.visible and not b.disabled:
			b.grab_focus()
			return


func _on_continue_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.save_ui_mode = "continue"
	MenuKit.go(self, SAVE_SELECT)


func _on_new_game_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.save_ui_mode = "new"
	MenuKit.go(self, SAVE_SELECT)


func _on_play_pressed() -> void:
	_on_new_game_pressed()


func _on_options_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	var opt := get_node_or_null("OptionsPanel") as Control
	if opt:
		opt.visible = true
		_layout()
		(get_node("MuteButton") as Button).grab_focus()


func _on_options_close() -> void:
	var opt := get_node_or_null("OptionsPanel") as Control
	if opt:
		opt.visible = false
	var mute := get_node_or_null("MuteButton") as CanvasItem
	if mute:
		mute.visible = false
	var ob := get_node_or_null("OptionsButton") as Button
	if ob:
		ob.grab_focus()


func _refresh_mute_label(btn: Button = null) -> void:
	var b := btn
	if b == null:
		b = get_node_or_null("MuteButton") as Button
	if b == null:
		return
	var is_muted := AudioManager.is_muted() if AudioManager else false
	b.text = "Sonido: OFF" if is_muted else "Sonido: ON"


func _refresh_diff_label() -> void:
	var d := get_node_or_null("OptionsPanel/OptDiffButton") as Button
	if d:
		d.text = "Dificultad: DIFÍCIL" if GameState.is_hard() else "Dificultad: Normal"


func _on_diff_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.set_difficulty_hard(not GameState.is_hard())
	_refresh_diff_label()


func _on_mute_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
		AudioManager.toggle_mute()
	_refresh_mute_label()


func _on_achievements_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	Engine.set_meta("achievements_return", "title")
	MenuKit.go(self, "res://scenes/ui/AchievementsScreen.tscn")
