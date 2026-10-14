extends Control
## Selección de personaje (v0.64): Miku y Teto grandes a izquierda/derecha con su foco de
## color, nombre, estilo de juego y botón Confirmar. Fondo: key art del título atenuada.
## Tocar una tarjeta la elige; tocarla otra vez (o Confirmar / aceptar en el mando) entra.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const MenuKit := preload("res://scripts/ui/MenuKit.gd")
const BOSS_SELECT_SCENE := "res://scenes/ui/BossSelect.tscn"
const KEYART := "res://assets/sprites/ui/title_keyart.png"
const STAGE_BG := "res://assets/sprites/ui/charselect_stage.png"
## v0.65: centro de los charcos de luz del escenario (lienzo 398×224): cian / rojo.
const POOL_MIKU := Vector2(113, 170)
const POOL_TETO := Vector2(286, 170)

var _picked := -1  # 0 Miku, 1 Teto


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	MenuKit.fade_in(self)
	_picked = 1 if (GameState and GameState.has_method("is_teto") and GameState.is_teto()) else 0
	call_deferred("_focus_pick")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.02, 0.01, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var stage := ArtKit.load_tex(STAGE_BG)
	if stage:
		# Fondo cubriendo (atenuado) + copia nítida 398×224 centrada: los charcos quedan bajo las idols.
		MenuKit.add_fullscreen_art(self, STAGE_BG, "MenuBG", 0.5)
		var st := TextureRect.new()
		st.name = "StageBG"
		st.texture = stage
		st.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(st)
	elif MenuKit.add_fullscreen_art(self, KEYART, "MenuBG", 0.62) == null:
		var concert := ArtKit.menu_backdrop("res://assets/sprites/ui/menu_concert.png")
		if concert:
			concert.name = "MenuBG"
			add_child(concert)
	ArtKit.add_menu_frame(self)
	var dim := get_node_or_null("MenuDim") as ColorRect
	if dim:
		dim.color = Color(0.01, 0.0, 0.04, 0.25)

	var header := MenuKit.label("ELIGE TU V-IDOL", 14, MenuKit.COL_GOLD, 3)
	header.name = "Header"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)
	var hint := MenuKit.label("Toca una idol y luego Confirmar", 8, Color(0.8, 0.82, 0.95, 0.85), 2)
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	_make_card(false)
	_make_card(true)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	MenuKit.style_button(back, MenuKit.COL_CYAN, 10)
	back.pressed.connect(_on_back)
	add_child(back)
	var diff_btn := Button.new()
	diff_btn.name = "DiffButton"
	MenuKit.style_button(diff_btn, MenuKit.COL_PINK, 10)
	diff_btn.pressed.connect(_on_diff_toggle)
	add_child(diff_btn)
	_refresh_diff_label(diff_btn)
	var ok := Button.new()
	ok.name = "ConfirmButton"
	ok.text = "Confirmar ▶"
	MenuKit.style_button(ok, MenuKit.COL_GOLD, 11)
	ok.pressed.connect(_on_confirm)
	add_child(ok)


func _make_card(is_teto: bool) -> void:
	var who := "Teto" if is_teto else "Miku"
	var accent: Color = Color(1.0, 0.3, 0.38) if is_teto else Color(0.3, 0.9, 1.0)
	var btn := Button.new()
	btn.name = who + "Button"
	btn.text = ""
	MenuKit.style_button(btn, accent, 10)
	var clear := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", clear)
	btn.add_theme_stylebox_override("hover", clear)
	btn.add_theme_stylebox_override("pressed", clear)
	btn.pressed.connect(_pick.bind(1 if is_teto else 0))
	btn.focus_entered.connect(_on_card_focus.bind(1 if is_teto else 0))
	add_child(btn)

	# Foco de escenario: degradado radial del color de la idol (hijo 0 = *Swatch por compatibilidad)
	var tex := _idle_frame(is_teto)
	var spr := TextureRect.new()
	spr.name = who + "Swatch"
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.flip_h = is_teto
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(spr)

	var g := Gradient.new()
	g.set_color(0, Color(accent.r, accent.g, accent.b, 0.55))
	g.set_color(1, Color(accent.r, accent.g, accent.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.85)
	gt.fill_to = Vector2(0.5, 0.35)
	gt.width = 64
	gt.height = 64
	var spot := TextureRect.new()
	spot.name = "Spot"
	spot.texture = gt
	spot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spot.stretch_mode = TextureRect.STRETCH_SCALE
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spot.show_behind_parent = false
	btn.add_child(spot)
	btn.move_child(spot, 1)
	btn.move_child(spr, 0)

	var name_lbl := MenuKit.label("KASANE TETO" if is_teto else "HATSUNE MIKU", 13, accent, 3)
	name_lbl.name = who + "Name"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(name_lbl)
	var sub := MenuKit.label(
		"Sable + combos · cuerpo a cuerpo" if is_teto else "Buster + carga · a distancia",
		8, Color(0.95, 0.95, 1.0, 0.95), 2)
	sub.name = who + "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(sub)


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
	var band_bottom := area.position.y + (24.0 if tight else 28.0)
	ArtKit.layout_menu_frame(self, band_bottom)
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 16)
	var hint := get_node_or_null("Hint") as Label
	if hint:
		hint.position = Vector2(area.position.x, area.position.y + 15.0)
		hint.size = Vector2(area.size.x, 10)
		hint.visible = not tight

	var fh := 26.0
	var fy := area.end.y - fh - 2.0
	var back := get_node_or_null("BackButton") as Button
	if back:
		back.size = Vector2(76, fh)
		back.position = Vector2(area.position.x, fy)
	var ok := get_node_or_null("ConfirmButton") as Button
	if ok:
		ok.size = Vector2(104, fh)
		ok.position = Vector2(area.end.x - 104.0, fy)
	var diff := get_node_or_null("DiffButton") as Button
	if diff:
		var dw := minf(150.0, area.size.x - 76.0 - 104.0 - 16.0)
		diff.size = Vector2(dw, fh)
		diff.position = Vector2(area.position.x + (area.size.x - dw) * 0.5, fy)

	var o := MenuKit.stage_origin(self)
	var stg := get_node_or_null("StageBG") as Control
	if stg:
		stg.position = o
		stg.size = MenuKit.STAGE
	var top := band_bottom + 2.0
	var h := fy - 4.0 - top
	var w := floorf(area.size.x * 0.5) - 4.0
	for i in 2:
		var b := get_node_or_null("TetoButton" if i == 1 else "MikuButton") as Button
		if b == null:
			continue
		b.position = Vector2(area.position.x + (0.0 if i == 0 else area.size.x - w), top)
		b.size = Vector2(w, h)
		_layout_char_card(b, w, h, "Teto" if i == 1 else "Miku")
		if stg:
			# Idol de pie sobre su charco: pies en el centro del charco.
			var pool: Vector2 = (POOL_TETO if i == 1 else POOL_MIKU) + o
			var spr := b.get_node_or_null(("Teto" if i == 1 else "Miku") + "Swatch") as Control
			if spr:
				spr.position = pool - b.position - Vector2(spr.size.x * 0.5, spr.size.y - 4.0)
			var spot := b.get_node_or_null("Spot") as Control
			if spot:
				spot.visible = false  # el charco del escenario ya es el foco
				spot.set_meta("pool", true)
			# nombre y estilo arriba de la tarjeta, la idol abajo sobre el charco
			var who2 := "Teto" if i == 1 else "Miku"
			var nl := b.get_node_or_null(who2 + "Name") as Control
			var sl := b.get_node_or_null(who2 + "Sub") as Control
			if nl:
				nl.position = Vector2(0, 4)
			if sl:
				sl.position = Vector2(0, 19)
	_refresh_pick()


func _layout_char_card(btn: Button, w: float, h: float, who: String) -> void:
	# Sprite real a escala 1/2 (253 px → 126) o 1/3 si no cabe: divisor entero = píxel limpio.
	var spr := btn.get_node_or_null(who + "Swatch") as Control
	var text_h := 30.0
	var avail := h - text_h
	var div := 2.0 if avail >= 126.0 and get_node_or_null("StageBG") == null else 3.0
	var ps := Vector2(270.0, 253.0) / div
	if spr:
		spr.size = ps
		spr.position = Vector2((w - ps.x) * 0.5, maxf(avail - ps.y, 0.0))
	var spot := btn.get_node_or_null("Spot") as Control
	if spot:
		spot.size = Vector2(minf(w, ps.x * 1.3), avail)
		spot.position = Vector2((w - spot.size.x) * 0.5, 0)
	var name_lbl := btn.get_node_or_null(who + "Name") as Label
	if name_lbl:
		name_lbl.position = Vector2(0, avail)
		name_lbl.size = Vector2(w, 16)
	var sub := btn.get_node_or_null(who + "Sub") as Label
	if sub:
		sub.position = Vector2(0, avail + 15.0)
		sub.size = Vector2(w, 12)


func _refresh_pick() -> void:
	for i in 2:
		var b := get_node_or_null("TetoButton" if i == 1 else "MikuButton") as Button
		if b == null:
			continue
		var on := i == _picked
		b.modulate = Color(1, 1, 1, 1) if on else Color(0.5, 0.5, 0.6, 1)
		var spot := b.get_node_or_null("Spot") as CanvasItem
		if spot:
			spot.visible = on and not spot.has_meta("pool")


func _focus_pick() -> void:
	var b := get_node_or_null("TetoButton" if _picked == 1 else "MikuButton") as Button
	if b:
		b.grab_focus()
	_refresh_pick()


func _on_card_focus(i: int) -> void:
	_picked = i
	_refresh_pick()


func _pick(i: int) -> void:
	if _picked == i and get_viewport().gui_get_focus_owner() == get_node_or_null("TetoButton" if i == 1 else "MikuButton"):
		_on_confirm()
		return
	_picked = i
	if AudioManager:
		AudioManager.play_sfx("menu_move")
	_focus_pick()


func _on_confirm() -> void:
	if _picked == 1:
		_on_teto()
	else:
		_on_miku()


func _on_miku() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.select_miku()
	MenuKit.go(self, BOSS_SELECT_SCENE)


func _on_teto() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.select_teto()
	MenuKit.go(self, BOSS_SELECT_SCENE)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	MenuKit.go(self, "res://scenes/ui/TitleScreen.tscn")


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
