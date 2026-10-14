extends Control
## Selector 3×3 de jefes — cartelera SynthoCorp / concierto.
## Layout responsive: SafeArea + cells sized to fit 16:9 / 20:9 landscape.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const MenuKit := preload("res://scripts/ui/MenuKit.gd")
const WALL := "res://assets/sprites/ui/bossselect_wall.png"
## v0.64: marcos de neón del muro de monitores (coords del lienzo 398×224), fila por fila.
const FRAME_RECTS: Array = [
	Rect2(56, 48, 78, 38), Rect2(155, 48, 88, 38), Rect2(264, 48, 78, 38),
	Rect2(56, 99, 78, 39), Rect2(146, 92, 107, 52), Rect2(264, 99, 78, 39),
	Rect2(56, 152, 78, 38), Rect2(155, 152, 88, 38), Rect2(264, 152, 78, 38),
]
const STAGE_NAMES := {
	"beatfire": "ESTADIO EN LLAMAS", "glitch_ice": "ESTUDIO GLITCH", "bassquake": "SUBWOOFER INDUSTRIAL",
	"echo_wind": "TORRES DEL ECO", "neon_volt": "CLUB NEÓN", "metronome": "FÁBRICA DE RELOJES",
	"chorus_bloom": "INVERNADERO SYNTHO", "static_shadow": "BACKSTAGE · RUIDO BLANCO", "core9": "FORTALEZA CORE-9",
}
## Arma que les hace ×3 (grupos weak_to_* de cada jefe).
const WEAKNESS := {
	"beatfire": ["freeze_sample", "Freeze Sample"], "glitch_ice": ["quake_drop", "Quake Drop"],
	"bassquake": ["echo_gale", "Echo Gale"], "echo_wind": ["neon_arc", "Neon Arc"],
	"neon_volt": ["tempo_spike", "Tempo Spike"], "metronome": ["petal_chorus", "Petal Chorus"],
	"chorus_bloom": ["static_veil", "Static Veil"], "static_shadow": ["beat_blaze", "Beat Blaze"],
}
var _selected := ""
var _intro: CanvasLayer = null

const LEVEL_BEATFIRE := "res://scenes/levels/Level01.tscn"
const LEVEL_ECHO_WIND := "res://scenes/levels/LevelEchoWind.tscn"
const LEVEL_NEON_VOLT := "res://scenes/levels/LevelNeonVolt.tscn"
const LEVEL_GLITCH_ICE := "res://scenes/levels/LevelGlitchIce.tscn"
const LEVEL_CHORUS_BLOOM := "res://scenes/levels/LevelChorusBloom.tscn"
const LEVEL_BASSQUAKE := "res://scenes/levels/LevelBassquake.tscn"
const LEVEL_METRONOME := "res://scenes/levels/LevelMetronome.tscn"
const LEVEL_STATIC_SHADOW := "res://scenes/levels/LevelStaticShadow.tscn"
const FORTRESS_SCENE := "res://scenes/ui/FortressComingSoon.tscn"
const CHAR_SELECT := "res://scenes/ui/CharacterSelect.tscn"
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"

## Grid positions (row-major 0..8). Center index 4 = CORE-9.
const BOSS_SLOTS: Array = [
	{"id": "beatfire", "name": "Beatfire Man", "playable": true, "accent": Color(1.0, 0.45, 0.15)},
	{"id": "glitch_ice", "name": "Glitch Ice", "playable": true, "accent": Color(0.45, 0.85, 1.0)},
	{"id": "bassquake", "name": "Bassquake", "playable": true, "accent": Color(0.75, 0.55, 0.25)},
	{"id": "echo_wind", "name": "Echo Wind", "playable": true, "accent": Color(0.55, 0.95, 0.75)},
	{"id": "core9", "name": "CORE-9", "playable": false, "is_core": true, "accent": Color(0.85, 0.3, 0.95)},
	{"id": "neon_volt", "name": "Neon Volt", "playable": true, "accent": Color(0.95, 0.95, 0.35)},
	{"id": "metronome", "name": "Metronome", "playable": true, "accent": Color(0.7, 0.75, 0.85)},
	{"id": "chorus_bloom", "name": "Chorus Bloom", "playable": true, "accent": Color(0.85, 0.45, 0.75)},
	{"id": "static_shadow", "name": "Static Shadow", "playable": true, "accent": Color(0.55, 0.45, 0.75)},
]

const CELL_GAP := 4.0
const HEADER_H := 30.0
const FOOTER_H := 36.0

var _cell_w := 72.0
var _cell_h := 52.0


func _ready() -> void:
	if GameState.active_slot >= 0:
		GameState.autosave()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	call_deferred("_initial_focus")
	MenuKit.fade_in(self)
	if AudioManager:
		AudioManager.play_bgm("boss_select")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.02, 0.02, 0.03, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# v0.64: muro de monitores (fondo cubriendo + copia nítida 398×224 centrada).
	if MenuKit.add_fullscreen_art(self, WALL, "MenuBG", 0.55) == null:
		var board := ArtKit.menu_backdrop("res://assets/sprites/ui/menu_billboard.png")
		if board:
			board.name = "MenuBG"
			add_child(board)
	var wall_tex := ArtKit.load_tex(WALL)
	if wall_tex:
		var wall := TextureRect.new()
		wall.name = "Wall"
		wall.texture = wall_tex
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(wall)
	# v0.58: mismo marco de concierto que el título (velo + banda).
	ArtKit.add_menu_frame(self)
	for n in ["MenuDim", "HeaderBand", "HeaderLineC", "HeaderLineP"]:
		var fc := get_node_or_null(n) as CanvasItem
		if fc:
			fc.visible = false

	var top_bar := ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color(0.12, 0.1, 0.22, 0.0)  # replaced by HeaderBand
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.visible = false
	add_child(top_bar)

	var hard_banner := ColorRect.new()
	hard_banner.name = "HardBanner"
	hard_banner.color = Color(0.55, 0.12, 0.18, 0.95)
	hard_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hard_banner.visible = GameState.is_hard()
	add_child(hard_banner)
	var hard_lbl := Label.new()
	hard_lbl.name = "HardBannerLabel"
	hard_lbl.text = "◆ MODO DIFÍCIL"
	hard_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hard_lbl.add_theme_font_size_override("font_size", 8)
	hard_lbl.modulate = Color(1.0, 0.75, 0.8, 1.0)
	hard_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hard_lbl.visible = GameState.is_hard()
	add_child(hard_lbl)

	var accent := ColorRect.new()
	accent.name = "AccentCyan"
	accent.color = Color(0.25, 0.85, 0.95, 0.9)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var accent2 := ColorRect.new()
	accent2.name = "AccentMagenta"
	accent2.color = Color(0.92, 0.28, 0.55, 0.75)
	accent2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent2)

	var mark := ArtKit.load_tex("res://assets/sprites/ui/synthocorp_mark.png")
	if mark:
		var logo := ArtKit.make_texture_rect(mark, Vector2(14, 14), Vector2(4, 6))
		logo.name = "SynthoMark"
		add_child(logo)

	var header := Label.new()
	header.name = "Header"
	header.text = "SYNTHOCORP · CARTELERA"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(header, 7, Color(0.55, 0.85, 1.0, 0.8), 2)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var sub := Label.new()
	sub.name = "SubHeader"
	sub.text = "Selecciona un Robot Master"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
	sub.add_theme_constant_override("outline_size", 2)
	sub.modulate = Color(0.85, 0.9, 1.0, 0.95)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	var bname := MenuKit.label("", 12, MenuKit.COL_GOLD, 3)
	bname.name = "BossName"
	bname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(bname)
	var bhint := MenuKit.label("", 8, Color(0.85, 0.9, 1.0), 2)
	bhint.name = "BossHint"
	bhint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(bhint)

	var grid := Control.new()
	grid.name = "BossGrid"
	add_child(grid)

	for i in BOSS_SLOTS.size():
		var data: Dictionary = BOSS_SLOTS[i]
		var cell := _make_boss_cell(data, i)
		grid.add_child(cell)

	var footer := Label.new()
	footer.name = "Footer"
	footer.text = (
		"CORE-9 VENCIDO · puedes repetir la fortaleza"
		if GameState.is_boss_defeated(GameState.BOSS_CORE9)
		else "8 Robot Masters · CORE-9 tras vencerlos"
	)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 8)
	footer.modulate = Color(0.6, 0.65, 0.75, 0.75)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 11)
	MenuKit.style_button(back, MenuKit.COL_CYAN, 10)
	back.pressed.connect(_on_back)
	add_child(back)

	var ach_btn := Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "Logros"
	ach_btn.add_theme_font_size_override("font_size", 11)
	MenuKit.style_button(ach_btn, MenuKit.COL_PINK, 10)
	ach_btn.pressed.connect(_on_achievements)
	add_child(ach_btn)

	var diff_btn := Button.new()
	diff_btn.name = "DiffButton"
	diff_btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(diff_btn, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	diff_btn.pressed.connect(_on_diff_toggle)
	add_child(diff_btn)
	_refresh_diff_label(diff_btn)

	var go_btn := Button.new()
	go_btn.name = "ConfirmButton"
	go_btn.text = "¡Entrar! ▶"
	MenuKit.style_button(go_btn, MenuKit.COL_GOLD, 10)
	go_btn.pressed.connect(_on_confirm)
	add_child(go_btn)

	var char_lbl := Label.new()
	char_lbl.name = "CharLabel"
	var diff_tag := " · DIFÍCIL" if GameState.is_hard() else ""
	char_lbl.text = GameState.get_character_display_name() + diff_tag
	if GameState.is_hard():
		char_lbl.modulate = Color(1.0, 0.55, 0.55, 1.0)
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	char_lbl.add_theme_font_size_override("font_size", 7)
	char_lbl.modulate = GameState.get_portrait_color()
	char_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_lbl.visible = false
	add_child(char_lbl)

	var datos := Button.new()
	datos.name = "DatosButton"
	datos.text = "Datos"
	datos.add_theme_font_size_override("font_size", 11)
	MenuKit.style_button(datos, MenuKit.COL_CYAN, 10)
	datos.pressed.connect(_toggle_datos)
	add_child(datos)

	var panel := Panel.new()
	panel.name = "DatosPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.05, 0.97)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.35, 0.9, 1.0, 0.95)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", MenuKit.panel_box(MenuKit.COL_CYAN))
	add_child(panel)
	var datos_body := Label.new()
	datos_body.name = "DatosBody"
	datos_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos_body.add_theme_font_size_override("font_size", 11)
	datos_body.modulate = Color(0.92, 0.95, 1.0, 1.0)
	datos_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(datos_body)
	var datos_close := Button.new()
	datos_close.name = "DatosClose"
	datos_close.text = "Cerrar"
	datos_close.add_theme_font_size_override("font_size", 12)
	MenuKit.style_button(datos_close, MenuKit.COL_PINK, 11)
	datos_close.pressed.connect(_toggle_datos)
	panel.add_child(datos_close)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var band_bottom := area.position.y + HEADER_H
	ArtKit.layout_menu_frame(self, band_bottom)

	var top_bar := get_node_or_null("TopBar") as ColorRect
	if top_bar:
		top_bar.visible = false
		top_bar.position = Vector2(0, 0)
		top_bar.size = Vector2(vp.x, band_bottom)
	var hard_banner := get_node_or_null("HardBanner") as ColorRect
	var hard_lbl := get_node_or_null("HardBannerLabel") as Label
	var hard_on := GameState.is_hard()
	if hard_banner:
		hard_banner.visible = hard_on
		hard_banner.position = Vector2(0, maxf(area.position.y - 2.0, 0.0))
		hard_banner.size = Vector2(vp.x, 12.0)
	if hard_lbl:
		hard_lbl.visible = hard_on
		hard_lbl.position = Vector2(area.position.x, maxf(area.position.y - 2.0, 0.0))
		hard_lbl.size = Vector2(area.size.x, 12.0)

	var accent := get_node_or_null("AccentCyan") as ColorRect
	if accent:
		accent.visible = false  # HeaderLineC from menu frame
	var accent2 := get_node_or_null("AccentMagenta") as ColorRect
	if accent2:
		accent2.visible = false  # HeaderLineP from menu frame

	var logo := get_node_or_null("SynthoMark") as Control
	if logo:
		logo.position = Vector2(area.position.x, area.position.y + 4.0)

	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 12)

	var sub := get_node_or_null("SubHeader") as Label
	if sub:
		sub.position = Vector2(area.position.x, area.position.y + 14.0)
		sub.size = Vector2(area.size.x, 10)

	# v0.64: lienzo 398×224 centrado; las celdas caen dentro de los marcos del muro.
	var o := MenuKit.stage_origin(self)
	var wall := get_node_or_null("Wall") as Control
	if wall:
		wall.position = o
		wall.size = MenuKit.STAGE
	if header:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.position = Vector2(o.x + 24.0, o.y)
		header.size = Vector2(140, 9)
	if sub:
		sub.visible = false
	var bn := get_node_or_null("BossName") as Label
	if bn:
		bn.position = Vector2(o.x + 8.0, o.y + 7.0)
		bn.size = Vector2(MenuKit.STAGE.x - 16.0, 14)
	var bh := get_node_or_null("BossHint") as Label
	if bh:
		bh.position = Vector2(o.x + 8.0, o.y + 20.0)
		bh.size = Vector2(MenuKit.STAGE.x - 16.0, 10)
	if logo:
		logo.position = o + Vector2(6, 7)

	# Fila inferior (banda de máquinas del muro): Volver · Logros · Dificultad · Datos · ¡Entrar!
	var btn_h := 20.0
	var footer_y := minf(o.y + 200.0, area.end.y - btn_h)
	var row := ["BackButton", "AchievementsButton", "DiffButton", "DatosButton", "ConfirmButton"]
	var widths := [62.0, 62.0, 96.0, 58.0, 76.0]
	var gap := 4.0
	var row_need := gap * 4.0
	for wv in widths:
		row_need += wv
	var row_scale := minf(1.0, (area.size.x) / row_need)
	var x := o.x + (MenuKit.STAGE.x - row_need * row_scale) * 0.5
	x = maxf(x, area.position.x)
	for i in row.size():
		var rb := get_node_or_null(row[i]) as Button
		if rb == null:
			continue
		rb.position = Vector2(x, footer_y)
		rb.size = Vector2(floorf(widths[i] * row_scale), btn_h)
		x += widths[i] * row_scale + gap
	var footer := get_node_or_null("Footer") as Label
	if footer:
		footer.visible = false
		footer.clip_text = true

	var grid := get_node_or_null("BossGrid") as Control
	if grid == null:
		return
	grid.position = o
	grid.size = MenuKit.STAGE
	for i in grid.get_child_count():
		var cell := grid.get_child(i) as Control
		if cell == null:
			continue
		var r: Rect2 = FRAME_RECTS[i]
		cell.position = r.position
		cell.size = r.size
		_relayout_cell(cell, r.size.x, r.size.y)
	_layout_datos_panel(area)


func _relayout_cell(root: Control, cw: float, ch: float) -> void:
	## v0.64: retrato 64×64 a ½ (32 px) a la izquierda del monitor, nombre a la derecha;
	## el centro muestra a la idol (o CORE-9) grande.
	var btn := root.get_node_or_null("SelectButton") as Button
	if btn == null:
		return
	btn.size = Vector2(cw, ch)
	btn.position = Vector2.ZERO
	var is_center := bool(root.get_meta("is_core", false))
	var portrait := btn.get_node_or_null("Portrait") as Control
	if portrait:
		if is_center:
			var ps := minf(ch - 4.0, 48.0)
			portrait.size = Vector2(ps, ps)
			portrait.position = Vector2(4, (ch - ps) * 0.5)
		else:
			portrait.size = Vector2(32, 32)
			portrait.position = Vector2(3, (ch - 32.0) * 0.5)
	var name_lbl := btn.get_node_or_null("NameLabel") as Label
	if name_lbl:
		var nx := (56.0 if is_center else 37.0)
		name_lbl.position = Vector2(nx, 3)
		name_lbl.size = Vector2(cw - nx - 1.0, ch - 4.0)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_constant_override("line_spacing", -2)
		name_lbl.add_theme_font_size_override("font_size", 8 if is_center else 7)
	var status := btn.get_node_or_null("StatusLabel") as Label
	if status:
		status.visible = is_center  # en los demás manda el sello ✓ / el foco
		var sx := (56.0 if is_center else 37.0)
		status.position = Vector2(sx, ch - 12.0)
		status.size = Vector2(cw - sx - 2.0, 10)
		status.add_theme_font_size_override("font_size", 7)
	var dimr := btn.get_node_or_null("DefeatDim") as Control
	if dimr:
		dimr.position = Vector2.ZERO
		dimr.size = Vector2(cw, ch)
	var check := btn.get_node_or_null("Checkmark") as Control
	if check:
		check.size = Vector2(18, 18)
		check.position = Vector2(20, ch - 20.0)  # sello sobre el retrato
	var secret := btn.get_node_or_null("SecretStub") as Label
	if secret:
		secret.position = Vector2(cw - 14.0, 1.0)
		secret.size = Vector2(12, 12)
		secret.add_theme_font_size_override("font_size", 9)
	var frame := btn.get_node_or_null("SelectFrame") as Control
	if frame:
		frame.visible = false


func _make_boss_cell(data: Dictionary, index: int) -> Control:
	var id: String = str(data.get("id", ""))
	var boss_name: String = str(data.get("name", "?"))
	var playable: bool = bool(data.get("playable", false))
	var is_core: bool = bool(data.get("is_core", false))
	var accent: Color = data.get("accent", Color(0.6, 0.6, 0.7))

	var defeated := false
	if id == "beatfire":
		defeated = GameState.is_beatfire_defeated()
	else:
		defeated = GameState.is_boss_defeated(id)

	var locked_core := is_core and not GameState.is_core9_unlocked()
	var greyed := (not playable) or locked_core

	var root := Control.new()
	root.name = "BossCell_%s" % id
	root.size = Vector2(_cell_w, _cell_h)
	root.set_meta("boss_id", id)
	root.set_meta("slot_index", index)

	var btn := Button.new()
	btn.name = "SelectButton"
	btn.text = ""
	btn.size = Vector2(_cell_w, _cell_h)
	btn.position = Vector2.ZERO
	btn.focus_mode = Control.FOCUS_ALL

	var bg_col: Color
	var border_col: Color
	bg_col = Color(0.03, 0.03, 0.05, 0.96)
	border_col = Color(0.95, 0.35, 0.72, 1.0) if (index % 2 == 1 or is_core) else Color(0.35, 0.9, 1.0, 1.0)
	if greyed and not is_core:
		border_col = Color(0.35, 0.35, 0.42, 0.55)
	elif locked_core:
		border_col = Color(0.55, 0.25, 0.45, 0.7)

	if defeated:
		border_col = Color(0.35, 0.95, 0.45, 1.0)

	# v0.64: el muro ya dibuja el marco; el botón solo muestra el foco (borde dorado).
	MenuKit.style_button(btn, border_col, 8)
	var clear := StyleBoxEmpty.new()
	for st in ["normal", "disabled"]:
		btn.add_theme_stylebox_override(st, clear)
	root.set_meta("is_core", is_core)
	btn.focus_entered.connect(_select.bind(id))
	if greyed and not is_core:
		btn.disabled = true
		btn.modulate = Color(0.55, 0.55, 0.6, 1.0)
	elif locked_core:
		btn.disabled = true
		btn.modulate = Color(0.65, 0.55, 0.75, 1.0)
	else:
		btn.pressed.connect(_on_cell_tap.bind(id))
	if locked_core:
		btn.disabled = false  # se puede enfocar para leer «BLOQUEADO»
		btn.pressed.connect(_on_cell_tap.bind(id))
		btn.modulate = Color(0.8, 0.75, 0.9, 1.0)

	root.add_child(btn)

	var ptex := ArtKit.boss_portrait_tex(id)
	if is_core and not GameState.is_core9_unlocked():
		# Centro: la idol elegida hasta vencer a los 8; luego CORE-9 / la fortaleza.
		var who := "teto" if GameState.get_character_id() == "teto" else "miku"
		var ct := ArtKit.load_tex("res://assets/sprites/ui/portrait_%s.png" % who)
		if ct:
			ptex = ct
	var swatch: Control
	if ptex:
		swatch = ArtKit.make_texture_rect(ptex, Vector2(22, 22), Vector2(3, 3))
		swatch.name = "Portrait"
		swatch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if greyed and not is_core:
			swatch.modulate = Color(0.45, 0.45, 0.5, 0.9)
	else:
		swatch = ColorRect.new()
		swatch.name = "Portrait"
		swatch.size = Vector2(18, 18)
		swatch.position = Vector2(4, 4)
		(swatch as ColorRect).color = Color(0.3, 0.3, 0.35, 0.9) if greyed else accent
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(swatch)

	var frame_tex := ArtKit.select_frame_tex()
	if frame_tex:
		var fr := ArtKit.make_texture_rect(frame_tex, Vector2(_cell_w, _cell_h), Vector2.ZERO)
		fr.name = "SelectFrame"
		fr.modulate = Color(1, 1, 1, 0.35 if greyed else 0.7)
		btn.add_child(fr)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = boss_name
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.position = Vector2(24, 4)
	name_lbl.size = Vector2(46, 20)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.text = boss_name if not (is_core and locked_core) else GameState.get_character_display_name()
	name_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
	name_lbl.add_theme_constant_override("outline_size", 2)
	if greyed:
		name_lbl.modulate = Color(0.55, 0.55, 0.6, 1.0)
	else:
		name_lbl.modulate = Color(0.98, 0.95, 0.9, 1.0)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	var status := Label.new()
	status.name = "StatusLabel"
	status.add_theme_font_size_override("font_size", 8)
	status.position = Vector2(4, 36)
	status.size = Vector2(64, 12)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_core:
		if defeated:
			status.text = "VENCIDO ✓"
			status.modulate = Color(0.55, 1.0, 0.65, 1.0)
		elif locked_core:
			status.text = "BLOQUEADO"
			status.modulate = Color(0.85, 0.55, 1.0, 0.9)
		else:
			status.text = "FORTALEZA"
			status.modulate = Color(0.6, 1.0, 0.7, 1.0)
	elif defeated:
		status.text = "VENCIDO ✓"
		status.modulate = Color(0.55, 1.0, 0.65, 1.0)
	elif playable:
		status.text = "ENTRAR"
		status.modulate = accent
	else:
		status.text = "BLOQUEADO"
		status.modulate = Color(0.6, 0.6, 0.65, 0.85)
	btn.add_child(status)

	if defeated:
		var dimr := ColorRect.new()
		dimr.name = "DefeatDim"
		dimr.color = Color(0.0, 0.0, 0.03, 0.6)
		dimr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(dimr)
		var check_bg := Panel.new()
		check_bg.name = "Checkmark"
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.12, 0.55, 0.22, 0.95)
		csb.set_border_width_all(1)
		csb.border_color = Color(0.55, 1.0, 0.65, 1.0)
		csb.set_corner_radius_all(3)
		check_bg.add_theme_stylebox_override("panel", csb)
		check_bg.position = Vector2(maxf(_cell_w - 20.0, 52.0), 2)
		check_bg.size = Vector2(16, 16)
		check_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(check_bg)
		var check := Label.new()
		check.name = "CheckGlyph"
		check.text = "✓"
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		check.add_theme_font_size_override("font_size", 15)
		check.modulate = Color(0.85, 1.0, 0.9, 1.0)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_bg.add_child(check)

	# Map blip for pending armor secrets — only with Stage Flight helmet (scanner)
	var flight_helm := false
	if GameState.has_method("has_flight_head_equipped"):
		flight_helm = bool(GameState.has_flight_head_equipped())
	elif GameState.has_method("has_armor_piece"):
		flight_helm = bool(GameState.has_armor_piece("flight", "head"))
	if playable and flight_helm and GameState.has_pending_armor_secret(id):
		var secret := Label.new()
		secret.name = "SecretStub"
		secret.text = "◆"
		secret.add_theme_font_size_override("font_size", 12)
		secret.modulate = Color(0.35, 0.95, 1.0, 1.0)
		secret.position = Vector2(maxf(_cell_w - 16.0, 52.0), maxf(_cell_h - 16.0, 34.0))
		secret.size = Vector2(14, 14)
		secret.tooltip_text = "Secreto detectado (casco Flight)"
		secret.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(secret)

	return root


func _layout_datos_panel(area: Rect2) -> void:
	var panel := get_node_or_null("DatosPanel") as Panel
	if panel == null:
		return
	var pw := minf(260.0, area.size.x * 0.72)
	var ph := minf(132.0, area.size.y * 0.62)
	panel.size = Vector2(pw, ph)
	panel.position = Vector2(
		area.position.x + (area.size.x - pw) * 0.5,
		area.position.y + (area.size.y - ph) * 0.42
	)
	var body := panel.get_node_or_null("DatosBody") as Label
	if body:
		body.position = Vector2(10, 8)
		body.size = Vector2(pw - 20.0, ph - 48.0)
		body.text = _datos_text()
	var close := panel.get_node_or_null("DatosClose") as Button
	if close:
		close.size = Vector2(minf(120.0, pw - 24.0), 32.0)
		close.position = Vector2((pw - close.size.x) * 0.5, ph - 38.0)


func _datos_text() -> String:
	var beaten := 0
	for id in ["beatfire", "glitch_ice", "bassquake", "echo_wind", "neon_volt", "metronome", "chorus_bloom", "static_shadow"]:
		if GameState.is_boss_defeated(id):
			beaten += 1
	var core := "sí" if GameState.is_boss_defeated(GameState.BOSS_CORE9) else "no"
	var tanks := int(GameState.get_energy_tanks()) if GameState.has_method("get_energy_tanks") else 0
	var weapons := 0
	if GameState.has_method("get_unlocked_weapons"):
		weapons = GameState.get_unlocked_weapons().size()
	var diff := "Difícil" if GameState.is_hard() else "Normal"
	var who := GameState.get_character_display_name()
	return "Personaje: %s\nJefes: %d/8   ·   CORE-9: %s\nTanques: %d   ·   Armas: %d\nDificultad: %s\n◆ = secreto de armadura (casco Flight)" % [who, beaten, core, tanks, weapons, diff]


func _toggle_datos() -> void:
	var panel := get_node_or_null("DatosPanel") as CanvasItem
	if panel == null:
		return
	panel.visible = not panel.visible
	if panel.visible:
		_layout()
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")


func _initial_focus() -> void:
	var grid := get_node_or_null("BossGrid")
	if grid == null:
		return
	for c in grid.get_children():
		var b := c.get_node_or_null("SelectButton") as Button
		if b and not b.disabled and not (c.has_meta("boss_id") and GameState.is_boss_defeated(str(c.get_meta("boss_id")))):
			b.grab_focus()
			return
	var first := grid.get_child(0).get_node_or_null("SelectButton") as Button
	if first:
		first.grab_focus()


func _slot_data(id: String) -> Dictionary:
	for d in BOSS_SLOTS:
		if str(d.get("id", "")) == id:
			return d
	return {}


func _select(id: String) -> void:
	## Cabecera: nombre del jefe + pista de debilidad (solo si ya tienes esa arma).
	_selected = id
	var header := get_node_or_null("BossName") as Label
	var sub := get_node_or_null("BossHint") as Label
	var d := _slot_data(id)
	if id == "core9":
		if header:
			header.text = "CORE-9" if GameState.is_core9_unlocked() else GameState.get_character_display_name().to_upper()
		if sub:
			sub.text = "Fortaleza abierta · ¡al asalto!" if GameState.is_core9_unlocked() else "Vence a los 8 Robot Masters para abrir la fortaleza"
		return
	if header:
		header.text = str(d.get("name", id)).to_upper() + "  ·  " + str(STAGE_NAMES.get(id, ""))
	if sub:
		var w: Array = WEAKNESS.get(id, [])
		var hint := "Debilidad: ???"
		if not w.is_empty() and GameState.has_weapon_unlocked(str(w[0])):
			hint = "Debilidad: " + str(w[1])
		if GameState.is_boss_defeated(id):
			hint = "VENCIDO ✓ · " + hint
		sub.text = hint


func _on_cell_tap(id: String) -> void:
	## 1.er toque elige (y enfoca), 2.º toque o «¡Entrar!» confirma.
	if _selected == id:
		_on_confirm()
		return
	var grid := get_node_or_null("BossGrid")
	var cell := grid.get_node_or_null("BossCell_%s" % id) if grid else null
	if cell:
		(cell.get_node("SelectButton") as Button).grab_focus()
	_select(id)


func _on_confirm() -> void:
	if _selected == "":
		return
	if _selected == "core9" and not GameState.is_core9_unlocked():
		if AudioManager:
			AudioManager.play_sfx("menu_move")
		return
	_on_boss_pressed(_selected)


func _on_boss_pressed(boss_id: String) -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if MenuKit.is_headless() or boss_id == "core9" or _intro != null:
		_launch(boss_id)
	else:
		_show_intro(boss_id)


func _show_intro(boss_id: String) -> void:
	## «Intro de jefe»: franja, retrato que entra deslizando, nombre y etapa (~1.5 s, toca para saltar).
	_intro = CanvasLayer.new()
	_intro.name = "BossIntro"
	_intro.layer = 110
	add_child(_intro)
	var vp := get_viewport_rect().size
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_intro.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0.03, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var d := _slot_data(boss_id)
	var accent: Color = d.get("accent", MenuKit.COL_PINK)
	var band := ColorRect.new()
	band.color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.95)
	band.position = Vector2(0, vp.y * 0.5 - 40.0)
	band.size = Vector2(vp.x, 80)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	for yy in [band.position.y, band.position.y + 79.0]:
		var ln := ColorRect.new()
		ln.color = accent
		ln.position = Vector2(0, yy)
		ln.size = Vector2(vp.x, 1)
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(ln)
	var ptex := ArtKit.boss_portrait_tex(boss_id)
	var por := TextureRect.new()
	por.texture = ptex
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.size = Vector2(64, 64)
	por.position = Vector2(-70, band.position.y + 8.0)
	root.add_child(por)
	var name_l := MenuKit.label(str(d.get("name", boss_id)).to_upper(), 18, Color(1, 1, 1), 4)
	name_l.position = Vector2(vp.x * 0.5 - 70.0, band.position.y + 16.0)
	name_l.size = Vector2(vp.x * 0.5 + 60.0, 24)
	name_l.modulate.a = 0.0
	root.add_child(name_l)
	var stage_l := MenuKit.label(str(STAGE_NAMES.get(boss_id, "")), 9, accent.lightened(0.4), 2)
	stage_l.position = Vector2(vp.x * 0.5 - 68.0, band.position.y + 44.0)
	stage_l.size = Vector2(vp.x * 0.5 + 60.0, 12)
	stage_l.modulate.a = 0.0
	root.add_child(stage_l)
	root.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventScreenTouch or ev is InputEventMouseButton) and ev.pressed:
			_launch(boss_id))
	var tw := create_tween()
	tw.tween_property(shade, "color:a", 0.7, 0.15)
	tw.tween_property(por, "position:x", vp.x * 0.5 - 150.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(name_l, "modulate:a", 1.0, 0.15)
	tw.tween_property(stage_l, "modulate:a", 1.0, 0.15)
	tw.tween_interval(0.85)
	tw.tween_callback(_launch.bind(boss_id))


func _unhandled_input(event: InputEvent) -> void:
	if _intro != null and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_launch(_selected if _selected != "" else "beatfire")


func _launch(boss_id: String) -> void:
	if has_meta("launching"):
		return
	set_meta("launching", true)
	if boss_id == "beatfire":
		print("BossSelect: entrando etapa Beatfire Man")
		get_tree().change_scene_to_file(LEVEL_BEATFIRE)
	elif boss_id == "echo_wind":
		print("BossSelect: entrando etapa Echo Wind")
		get_tree().change_scene_to_file(LEVEL_ECHO_WIND)
	elif boss_id == "neon_volt":
		print("BossSelect: entrando etapa Neon Volt")
		get_tree().change_scene_to_file(LEVEL_NEON_VOLT)
	elif boss_id == "glitch_ice":
		print("BossSelect: entrando etapa Glitch Ice")
		get_tree().change_scene_to_file(LEVEL_GLITCH_ICE)
	elif boss_id == "chorus_bloom":
		print("BossSelect: entrando etapa Chorus Bloom")
		get_tree().change_scene_to_file(LEVEL_CHORUS_BLOOM)
	elif boss_id == "bassquake":
		print("BossSelect: entrando etapa Bassquake")
		get_tree().change_scene_to_file(LEVEL_BASSQUAKE)
	elif boss_id == "metronome":
		print("BossSelect: entrando etapa Metronome")
		get_tree().change_scene_to_file(LEVEL_METRONOME)
	elif boss_id == "static_shadow":
		print("BossSelect: entrando etapa Static Shadow")
		get_tree().change_scene_to_file(LEVEL_STATIC_SHADOW)
	elif boss_id == "core9":
		if GameState.is_core9_unlocked():
			print("BossSelect: entrando Fortaleza CORE-9")
			get_tree().change_scene_to_file(FORTRESS_SCENE)
		else:
			print("BossSelect: CORE-9 aún bloqueado")
	else:
		print("BossSelect: %s — Pronto" % boss_id)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("menu_move")
	MenuKit.go(self, CHAR_SELECT)


func _refresh_diff_label(btn: Button = null) -> void:
	var b := btn
	if b == null:
		b = get_node_or_null("DiffButton") as Button
	if b == null:
		return
	if GameState.is_hard():
		b.text = "DIFÍCIL ●"
		MenuKit.style_button(b, MenuKit.COL_PINK, 10)
	else:
		b.text = "Normal"
		MenuKit.style_button(b, MenuKit.COL_CYAN, 10)
	var char_lbl = get_node_or_null("CharLabel") as Label
	if char_lbl:
		var diff_tag := " · DIFÍCIL" if GameState.is_hard() else ""
		char_lbl.text = GameState.get_character_display_name() + diff_tag
		char_lbl.modulate = Color(1.0, 0.55, 0.55, 1.0) if GameState.is_hard() else GameState.get_portrait_color()
	var hard_banner := get_node_or_null("HardBanner") as CanvasItem
	var hard_lbl := get_node_or_null("HardBannerLabel") as CanvasItem
	if hard_banner:
		hard_banner.visible = GameState.is_hard()
	if hard_lbl:
		hard_lbl.visible = GameState.is_hard()


func _on_diff_toggle() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	GameState.set_difficulty_hard(not GameState.is_hard())
	if GameState.active_slot >= 0:
		GameState.autosave()
	_refresh_diff_label()


func _on_achievements() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	Engine.set_meta("achievements_return", "boss_select")
	get_tree().change_scene_to_file("res://scenes/ui/AchievementsScreen.tscn")
