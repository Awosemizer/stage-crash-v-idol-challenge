extends Control
## Selector 3×3 de jefes — cartelera SynthoCorp / concierto.
## Layout responsive: SafeArea + cells sized to fit 16:9 / 20:9 landscape.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")

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
	if AudioManager:
		AudioManager.play_bgm("boss_select")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.04, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var top_bar := ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color(0.12, 0.1, 0.22, 1.0)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

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
	header.add_theme_font_size_override("font_size", 9)
	header.modulate = Color(0.45, 0.95, 1.0, 1.0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var sub := Label.new()
	sub.name = "SubHeader"
	sub.text = "Selecciona un Robot Master"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.8, 0.85, 0.95, 0.85)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	var grid := Control.new()
	grid.name = "BossGrid"
	add_child(grid)

	for i in BOSS_SLOTS.size():
		var data: Dictionary = BOSS_SLOTS[i]
		var cell := _make_boss_cell(data, i)
		grid.add_child(cell)

	var footer := Label.new()
	footer.name = "Footer"
	footer.text = "8 Robot Masters · CORE-9 tras vencerlos"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 6)
	footer.modulate = Color(0.6, 0.65, 0.75, 0.75)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 8)
	_SafeArea.style_button(back, Color(0.18, 0.18, 0.26, 0.95), Color(0.55, 0.6, 0.7, 0.85))
	back.pressed.connect(_on_back)
	add_child(back)

	var ach_btn := Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "Logros"
	ach_btn.add_theme_font_size_override("font_size", 8)
	_SafeArea.style_button(ach_btn, Color(0.22, 0.18, 0.08, 0.95), Color(1.0, 0.85, 0.3, 0.95))
	ach_btn.pressed.connect(_on_achievements)
	add_child(ach_btn)

	var diff_btn := Button.new()
	diff_btn.name = "DiffButton"
	diff_btn.add_theme_font_size_override("font_size", 8)
	_SafeArea.style_button(diff_btn, Color(0.16, 0.12, 0.22, 0.95), Color(0.85, 0.55, 1.0, 0.9))
	diff_btn.pressed.connect(_on_diff_toggle)
	add_child(diff_btn)
	_refresh_diff_label(diff_btn)

	var char_lbl := Label.new()
	char_lbl.name = "CharLabel"
	var diff_tag := " [D]" if GameState.is_hard() else ""
	char_lbl.text = GameState.get_character_display_name() + diff_tag
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	char_lbl.add_theme_font_size_override("font_size", 7)
	char_lbl.modulate = GameState.get_portrait_color()
	char_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_lbl)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()

	var top_bar := get_node_or_null("TopBar") as ColorRect
	if top_bar:
		top_bar.position = Vector2(0, 0)
		top_bar.size = Vector2(vp.x, area.position.y + HEADER_H - 2.0)

	var accent := get_node_or_null("AccentCyan") as ColorRect
	if accent:
		accent.position = Vector2(0, area.position.y + HEADER_H - 2.0)
		accent.size = Vector2(vp.x, 2)

	var accent2 := get_node_or_null("AccentMagenta") as ColorRect
	if accent2:
		accent2.position = Vector2(0, area.position.y + HEADER_H)
		accent2.size = Vector2(vp.x, 1)

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

	# Footer buttons sit at bottom of safe area — scale widths so they never clip
	var btn_h := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 30.0))
	var footer_y := area.end.y - btn_h
	var back := get_node_or_null("BackButton") as Button
	var ach := get_node_or_null("AchievementsButton") as Button
	var diff := get_node_or_null("DiffButton") as Button
	var char_lbl := get_node_or_null("CharLabel") as Label

	var gap := 4.0
	var back_w := 64.0
	var ach_w := 64.0
	var diff_w := 72.0
	var char_min := 48.0
	var row_need := back_w + ach_w + diff_w + char_min + gap * 3.0
	if row_need > area.size.x:
		var scale := area.size.x / row_need
		back_w = floorf(back_w * scale)
		ach_w = floorf(ach_w * scale)
		diff_w = floorf(diff_w * scale)
	if back:
		back.position = Vector2(area.position.x, footer_y)
		back.size = Vector2(back_w, btn_h)
	if ach:
		ach.position = Vector2(area.position.x + back_w + gap, footer_y)
		ach.size = Vector2(ach_w, btn_h)
	if diff:
		diff.position = Vector2(area.position.x + back_w + ach_w + gap * 2.0, footer_y)
		diff.size = Vector2(diff_w, btn_h)
	if char_lbl:
		var cx := area.position.x + back_w + ach_w + diff_w + gap * 3.0
		char_lbl.position = Vector2(cx, footer_y + maxf((btn_h - 14.0) * 0.5, 2.0))
		char_lbl.size = Vector2(maxf(area.end.x - cx, 8.0), 14)
		char_lbl.clip_text = true

	var footer := get_node_or_null("Footer") as Label
	if footer:
		footer.position = Vector2(area.position.x, footer_y - 11.0)
		footer.size = Vector2(area.size.x, 10)
		footer.clip_text = true

	# Grid fills remaining middle band — MUST fit 3×3 without clipping footer/header
	var grid_top := area.position.y + HEADER_H + 2.0
	var grid_bottom := footer_y - 12.0
	var grid_h := maxf(grid_bottom - grid_top, 84.0)
	var grid_w := area.size.x
	_cell_w = floorf((grid_w - CELL_GAP * 2.0) / 3.0)
	_cell_h = floorf((grid_h - CELL_GAP * 2.0) / 3.0)
	# Clamp to available space first (prevents overflow), then raise floor if room
	_cell_w = maxf(_cell_w, 1.0)
	_cell_h = maxf(_cell_h, 1.0)
	var need_h := _cell_h * 3.0 + CELL_GAP * 2.0
	if need_h > grid_h:
		_cell_h = maxf(floorf((grid_h - CELL_GAP * 2.0) / 3.0), 28.0)
	var need_w := _cell_w * 3.0 + CELL_GAP * 2.0
	if need_w > grid_w:
		_cell_w = maxf(floorf((grid_w - CELL_GAP * 2.0) / 3.0), 56.0)

	var grid := get_node_or_null("BossGrid") as Control
	if grid == null:
		return
	var total_w := _cell_w * 3.0 + CELL_GAP * 2.0
	var total_h := _cell_h * 3.0 + CELL_GAP * 2.0
	grid.size = Vector2(total_w, total_h)
	grid.position = Vector2(
		area.position.x + maxf((grid_w - total_w) * 0.5, 0.0),
		grid_top + maxf((grid_h - total_h) * 0.5, 0.0)
	)

	for i in grid.get_child_count():
		var cell := grid.get_child(i) as Control
		if cell == null:
			continue
		var col := i % 3
		var row := int(i / 3)
		cell.position = Vector2(col * (_cell_w + CELL_GAP), row * (_cell_h + CELL_GAP))
		cell.size = Vector2(_cell_w, _cell_h)
		_relayout_cell(cell, _cell_w, _cell_h)


func _relayout_cell(root: Control, cw: float, ch: float) -> void:
	var btn := root.get_node_or_null("SelectButton") as Button
	if btn == null:
		return
	btn.size = Vector2(cw, ch)
	btn.position = Vector2.ZERO
	var portrait := btn.get_node_or_null("Portrait") as Control
	if portrait:
		var ps := minf(22.0, ch * 0.42)
		portrait.size = Vector2(ps, ps)
		portrait.position = Vector2(4, 4)
	var name_lbl := btn.get_node_or_null("NameLabel") as Label
	if name_lbl:
		name_lbl.position = Vector2(28, 3)
		name_lbl.size = Vector2(maxf(cw - 32.0, 20.0), maxf(ch * 0.4, 16.0))
		name_lbl.add_theme_font_size_override("font_size", 7 if ch >= 44.0 else 6)
	var status := btn.get_node_or_null("StatusLabel") as Label
	if status:
		status.position = Vector2(4, ch - 14.0)
		status.size = Vector2(cw - 8.0, 12)
		status.add_theme_font_size_override("font_size", 6)
	var check := btn.get_node_or_null("Checkmark") as Label
	if check:
		check.position = Vector2(cw - 16.0, 2)
	var secret := btn.get_node_or_null("SecretStub") as Label
	if secret:
		secret.position = Vector2(cw - 16.0, ch - 16.0)
	var frame := btn.get_node_or_null("SelectFrame") as Control
	if frame:
		frame.size = Vector2(cw, ch)
		frame.position = Vector2.ZERO


func _make_boss_cell(data: Dictionary, index: int) -> Control:
	var id: String = str(data.get("id", ""))
	var boss_name: String = str(data.get("name", "?"))
	var playable: bool = bool(data.get("playable", false))
	var is_core: bool = bool(data.get("is_core", false))
	var accent: Color = data.get("accent", Color(0.6, 0.6, 0.7))

	var defeated := false
	if id == "beatfire":
		defeated = GameState.is_beatfire_defeated()
	elif id != "core9":
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
	if is_core:
		bg_col = Color(0.12, 0.06, 0.18, 0.95)
		border_col = accent.darkened(0.2) if locked_core else accent
	elif greyed:
		bg_col = Color(0.12, 0.12, 0.16, 0.92)
		border_col = Color(0.35, 0.35, 0.42, 0.7)
	else:
		match id:
			"echo_wind":
				bg_col = Color(0.08, 0.16, 0.16, 0.95)
			"neon_volt":
				bg_col = Color(0.16, 0.14, 0.06, 0.95)
			"glitch_ice":
				bg_col = Color(0.08, 0.14, 0.2, 0.95)
			"chorus_bloom":
				bg_col = Color(0.16, 0.1, 0.14, 0.95)
			"bassquake":
				bg_col = Color(0.16, 0.12, 0.06, 0.95)
			"metronome":
				bg_col = Color(0.12, 0.12, 0.18, 0.95)
			"static_shadow":
				bg_col = Color(0.1, 0.08, 0.16, 0.95)
			_:
				bg_col = Color(0.18, 0.1, 0.08, 0.95)
		border_col = accent

	if defeated and not is_core:
		border_col = Color(0.35, 0.95, 0.45, 1.0)

	_SafeArea.style_button(btn, bg_col, border_col, 3)
	if greyed and not is_core:
		btn.disabled = true
		btn.modulate = Color(0.55, 0.55, 0.6, 1.0)
	elif locked_core:
		btn.disabled = true
		btn.modulate = Color(0.65, 0.55, 0.75, 1.0)
	else:
		btn.pressed.connect(_on_boss_pressed.bind(id))

	root.add_child(btn)

	var ptex := ArtKit.boss_portrait_tex(id)
	var swatch: Control
	if ptex:
		swatch = ArtKit.make_texture_rect(ptex, Vector2(22, 22), Vector2(3, 3))
		swatch.name = "Portrait"
		if greyed:
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
	name_lbl.add_theme_font_size_override("font_size", 6)
	name_lbl.position = Vector2(24, 4)
	name_lbl.size = Vector2(46, 20)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if greyed:
		name_lbl.modulate = Color(0.55, 0.55, 0.6, 1.0)
	else:
		name_lbl.modulate = Color(0.98, 0.95, 0.9, 1.0)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	var status := Label.new()
	status.name = "StatusLabel"
	status.add_theme_font_size_override("font_size", 5)
	status.position = Vector2(4, 36)
	status.size = Vector2(64, 12)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_core:
		status.text = "BLOQUEADO" if locked_core else "FORTALEZA"
		status.modulate = Color(0.85, 0.55, 1.0, 0.9) if locked_core else Color(0.6, 1.0, 0.7, 1.0)
	elif defeated:
		status.text = "✓ VENCIDO"
		status.modulate = Color(0.45, 1.0, 0.55, 1.0)
	elif playable:
		status.text = "ENTRAR"
		status.modulate = accent
	else:
		status.text = "Pronto"
		status.modulate = Color(0.6, 0.6, 0.65, 0.85)
	btn.add_child(status)

	if defeated and not is_core:
		var check := Label.new()
		check.name = "Checkmark"
		check.text = "✓"
		check.add_theme_font_size_override("font_size", 10)
		check.modulate = Color(0.4, 1.0, 0.5, 1.0)
		check.position = Vector2(56, 2)
		check.size = Vector2(14, 14)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(check)

	if playable and GameState.has_pending_armor_secret(id):
		var secret := Label.new()
		secret.name = "SecretStub"
		secret.text = "◆"
		secret.add_theme_font_size_override("font_size", 7)
		secret.modulate = Color(0.4, 0.9, 1.0, 0.95)
		secret.position = Vector2(56, 34)
		secret.size = Vector2(12, 12)
		secret.tooltip_text = "Secreto de armadura pendiente"
		secret.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(secret)

	return root


func _on_boss_pressed(boss_id: String) -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
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
	get_tree().change_scene_to_file(CHAR_SELECT)


func _refresh_diff_label(btn: Button = null) -> void:
	var b := btn
	if b == null:
		b = get_node_or_null("DiffButton") as Button
	if b == null:
		return
	b.text = "Difícil" if GameState.is_hard() else "Normal"
	var char_lbl = get_node_or_null("CharLabel") as Label
	if char_lbl:
		var diff_tag := " [D]" if GameState.is_hard() else ""
		char_lbl.text = GameState.get_character_display_name() + diff_tag


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
