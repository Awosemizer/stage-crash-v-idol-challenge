extends Control
## Selección de personaje — Miku (cian) / Teto (rojo).
## Landscape SafeArea; large tappable character cards.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const BOSS_SELECT_SCENE := "res://scenes/ui/BossSelect.tscn"


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


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
	ArtKit.add_menu_frame(self)

	var header := Label.new()
	header.name = "Header"
	header.text = "Elige tu V-Idol"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(header, 14, Color(0.45, 0.95, 1.0, 1.0), 3)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Miku: Buster y carga    ·    Teto: sable de cerca"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.7, 0.75, 0.85, 0.8)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	var miku_btn := Button.new()
	miku_btn.name = "MikuButton"
	miku_btn.text = ""
	miku_btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(miku_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	miku_btn.pressed.connect(_on_miku)
	add_child(miku_btn)

	var miku_tex := _idle_frame(false)
	var miku_swatch: Control
	if miku_tex:
		miku_swatch = ArtKit.make_texture_rect(miku_tex, Vector2(48, 48), Vector2(28, 6))
		(miku_swatch as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		miku_swatch.name = "MikuSwatch"
	else:
		miku_swatch = ColorRect.new()
		miku_swatch.name = "MikuSwatch"
		(miku_swatch as ColorRect).color = GameState.COLOR_MIKU
		miku_swatch.position = Vector2(32, 12)
		miku_swatch.size = Vector2(40, 40)
		miku_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_swatch)

	var miku_name := Label.new()
	miku_name.name = "MikuName"
	miku_name.text = "MIKU"
	miku_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miku_name.add_theme_font_size_override("font_size", 13)
	miku_name.modulate = Color(0.4, 0.95, 1.0, 1.0)
	miku_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_name)
	var miku_sub := Label.new()
	miku_sub.name = "MikuSub"
	miku_sub.text = "Buster + carga"
	miku_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miku_sub.add_theme_font_size_override("font_size", 10)
	miku_sub.modulate = Color(0.8, 0.95, 1.0, 0.9)
	miku_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miku_btn.add_child(miku_sub)

	var teto_btn := Button.new()
	teto_btn.name = "TetoButton"
	teto_btn.text = ""
	teto_btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(teto_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.95, 0.35, 0.72, 1.0), 2)
	teto_btn.pressed.connect(_on_teto)
	add_child(teto_btn)

	var teto_tex := _idle_frame(true)
	var teto_swatch: Control
	if teto_tex:
		teto_swatch = ArtKit.make_texture_rect(teto_tex, Vector2(48, 48), Vector2(28, 6))
		(teto_swatch as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		teto_swatch.name = "TetoSwatch"
	else:
		teto_swatch = ColorRect.new()
		teto_swatch.name = "TetoSwatch"
		(teto_swatch as ColorRect).color = GameState.COLOR_TETO
		teto_swatch.position = Vector2(32, 12)
		teto_swatch.size = Vector2(40, 40)
		teto_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_swatch)

	var teto_name := Label.new()
	teto_name.name = "TetoName"
	teto_name.text = "TETO"
	teto_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teto_name.add_theme_font_size_override("font_size", 13)
	teto_name.modulate = Color(1.0, 0.45, 0.5, 1.0)
	teto_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_name)
	var teto_sub := Label.new()
	teto_sub.name = "TetoSub"
	teto_sub.text = "Sable melee"
	teto_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teto_sub.add_theme_font_size_override("font_size", 10)
	teto_sub.modulate = Color(1.0, 0.8, 0.82, 0.9)
	teto_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teto_btn.add_child(teto_sub)

	var diff_btn := Button.new()
	diff_btn.name = "DiffButton"
	diff_btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(diff_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.95, 0.35, 0.72, 1.0), 2)
	diff_btn.pressed.connect(_on_diff_toggle)
	add_child(diff_btn)
	_refresh_diff_label(diff_btn)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(back, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	back.pressed.connect(_on_back)
	add_child(back)



func _idle_frame(is_teto: bool) -> Texture2D:
	var path := "res://assets/sprites/player/%s_idle.png" % ("teto" if is_teto else "miku")
	var tex := ArtKit.load_tex(path)
	if tex == null:
		return ArtKit.char_portrait_tex(is_teto)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, tex.get_width(), tex.get_height())
	return atlas


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var tight := area.size.y < 190.0
	var band_bottom := area.position.y + (36.0 if tight else 42.0)
	ArtKit.layout_menu_frame(self, band_bottom)
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 18)
	var hint := get_node_or_null("Hint") as Label
	if hint:
		hint.position = Vector2(area.position.x, area.position.y + 20.0)
		hint.size = Vector2(area.size.x, 14)
		hint.visible = not tight

	var footer_h := maxf(_SafeArea.MIN_BTN_H, 32.0)
	var back := get_node_or_null("BackButton") as Button
	var diff := get_node_or_null("DiffButton") as Button
	if back:
		back.size = Vector2(96, footer_h)
		back.position = Vector2(area.position.x, area.end.y - footer_h)
	if diff:
		var dw := minf(188.0, area.size.x * 0.46)
		diff.size = Vector2(dw, footer_h)
		var dx := area.position.x + (area.size.x - dw) * 0.5
		if back and dx < back.position.x + back.size.x + 8.0:
			dx = back.position.x + back.size.x + 8.0
		if dx + dw > area.end.x:
			dw = maxf(area.end.x - dx, 96.0)
			diff.size.x = dw
		diff.position = Vector2(dx, area.end.y - footer_h)

	var card_top := band_bottom + 6.0
	var card_bottom := area.end.y - footer_h - 10.0
	var card_h := maxf(card_bottom - card_top, 100.0)
	var gap := 12.0
	var card_w := floorf((area.size.x - gap) * 0.5)
	card_w = maxf(card_w, 120.0)

	var miku := get_node_or_null("MikuButton") as Button
	var teto := get_node_or_null("TetoButton") as Button
	if miku:
		miku.position = Vector2(area.position.x, card_top)
		miku.size = Vector2(card_w, card_h)
		_layout_char_card(miku, card_w, card_h, "Miku")
	if teto:
		teto.position = Vector2(area.end.x - card_w, card_top)
		teto.size = Vector2(card_w, card_h)
		_layout_char_card(teto, card_w, card_h, "Teto")


func _layout_char_card(btn: Button, w: float, h: float, _who: String) -> void:
	var swatch := btn.get_child(0) as Control
	if swatch and (swatch.name.ends_with("Swatch")):
		var ps := 64.0 if h >= 148.0 else 32.0
		swatch.size = Vector2(ps, ps)
		swatch.position = Vector2((w - ps) * 0.5, 6.0)
	var name_lbl := btn.get_node_or_null("MikuName") as Label
	if name_lbl == null:
		name_lbl = btn.get_node_or_null("TetoName") as Label
	if name_lbl:
		name_lbl.position = Vector2(0, h * 0.55)
		name_lbl.size = Vector2(w, 18)
	var sub := btn.get_node_or_null("MikuSub") as Label
	if sub == null:
		sub = btn.get_node_or_null("TetoSub") as Label
	if sub:
		sub.position = Vector2(0, h * 0.72)
		sub.size = Vector2(w, 16)


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


func _refresh_diff_label(btn: Button = null) -> void:
	var b := btn
	if b == null:
		b = get_node_or_null("DiffButton") as Button
	if b == null:
		return
	var hard := GameState.is_hard() if GameState else false
	b.text = "Dificultad: DIFÍCIL" if hard else "Dificultad: Normal"


func _on_diff_toggle() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if GameState:
		GameState.set_difficulty_hard(not GameState.is_hard())
	_refresh_diff_label()
