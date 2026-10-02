extends Control
## Selector 3×3 de jefes — cartelera SynthoCorp / concierto.
## Centro = CORE-9 (bloqueado hasta 8). Los 8 Robot Masters jugables.

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
## Layout:
##  Beatfire | Glitch Ice | Bassquake
##  Echo Wind | CORE-9 | Neon Volt
##  Metronome | Chorus Bloom | Static Shadow
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

const CELL_W := 72.0
const CELL_H := 52.0
const GRID_ORIGIN := Vector2(20, 42)
const CELL_GAP := 4.0


func _ready() -> void:
	# Autoguardado al volver al selector (GDD: 3 slots).
	if GameState.active_slot >= 0:
		GameState.autosave()
	_build_ui()
	if AudioManager:
		AudioManager.play_bgm("boss_select")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.04, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# SynthoCorp terminal chrome
	var top_bar := ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color(0.12, 0.1, 0.22, 1.0)
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(256, 28)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var accent := ColorRect.new()
	accent.name = "AccentCyan"
	accent.color = Color(0.25, 0.85, 0.95, 0.9)
	accent.position = Vector2(0, 28)
	accent.size = Vector2(256, 2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "SYNTHOCORP · CARTELERA"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 8)
	header.modulate = Color(0.45, 0.95, 1.0, 1.0)
	header.position = Vector2(0, 4)
	header.size = Vector2(256, 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var sub := Label.new()
	sub.name = "SubHeader"
	sub.text = "Selecciona un Robot Master"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.modulate = Color(0.8, 0.85, 0.95, 0.85)
	sub.position = Vector2(0, 15)
	sub.size = Vector2(256, 10)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	var grid := Control.new()
	grid.name = "BossGrid"
	grid.position = GRID_ORIGIN
	grid.size = Vector2(CELL_W * 3 + CELL_GAP * 2, CELL_H * 3 + CELL_GAP * 2)
	add_child(grid)

	for i in BOSS_SLOTS.size():
		var data: Dictionary = BOSS_SLOTS[i]
		var col := i % 3
		var row := int(i / 3)
		var cell := _make_boss_cell(data, i)
		cell.position = Vector2(col * (CELL_W + CELL_GAP), row * (CELL_H + CELL_GAP))
		grid.add_child(cell)

	var footer := Label.new()
	footer.name = "Footer"
	footer.text = "8 Robot Masters · CORE-9 tras vencerlos"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 6)
	footer.modulate = Color(0.6, 0.65, 0.75, 0.75)
	footer.position = Vector2(0, 192)
	footer.size = Vector2(256, 10)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 7)
	back.position = Vector2(4, 200)
	back.size = Vector2(40, 18)
	_style_btn(back, Color(0.18, 0.18, 0.26, 0.95), Color(0.55, 0.6, 0.7, 0.85))
	back.pressed.connect(_on_back)
	add_child(back)

	var ach_btn := Button.new()
	ach_btn.name = "AchievementsButton"
	ach_btn.text = "Logros"
	ach_btn.add_theme_font_size_override("font_size", 6)
	ach_btn.position = Vector2(46, 200)
	ach_btn.size = Vector2(40, 18)
	_style_btn(ach_btn, Color(0.22, 0.18, 0.08, 0.95), Color(1.0, 0.85, 0.3, 0.95))
	ach_btn.pressed.connect(_on_achievements)
	add_child(ach_btn)

	var diff_btn := Button.new()
	diff_btn.name = "DiffButton"
	diff_btn.add_theme_font_size_override("font_size", 6)
	diff_btn.position = Vector2(88, 200)
	diff_btn.size = Vector2(52, 18)
	_style_btn(diff_btn, Color(0.16, 0.12, 0.22, 0.95), Color(0.85, 0.55, 1.0, 0.9))
	diff_btn.pressed.connect(_on_diff_toggle)
	add_child(diff_btn)
	_refresh_diff_label(diff_btn)

	var char_lbl := Label.new()
	char_lbl.name = "CharLabel"
	var diff_tag := " [D]" if GameState.is_hard() else ""
	char_lbl.text = GameState.get_character_display_name() + diff_tag
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	char_lbl.add_theme_font_size_override("font_size", 6)
	char_lbl.modulate = GameState.get_portrait_color()
	char_lbl.position = Vector2(144, 200)
	char_lbl.size = Vector2(108, 10)
	char_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_lbl)


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
	root.size = Vector2(CELL_W, CELL_H)
	root.set_meta("boss_id", id)
	root.set_meta("slot_index", index)

	var btn := Button.new()
	btn.name = "SelectButton"
	btn.text = ""
	btn.size = Vector2(CELL_W, CELL_H)
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
		if id == "echo_wind":
			bg_col = Color(0.08, 0.16, 0.16, 0.95)
		elif id == "neon_volt":
			bg_col = Color(0.16, 0.14, 0.06, 0.95)
		elif id == "glitch_ice":
			bg_col = Color(0.08, 0.14, 0.2, 0.95)
		elif id == "chorus_bloom":
			bg_col = Color(0.16, 0.1, 0.14, 0.95)
		elif id == "bassquake":
			bg_col = Color(0.16, 0.12, 0.06, 0.95)
		elif id == "metronome":
			bg_col = Color(0.12, 0.12, 0.18, 0.95)
		elif id == "static_shadow":
			bg_col = Color(0.1, 0.08, 0.16, 0.95)
		else:
			bg_col = Color(0.18, 0.1, 0.08, 0.95)
		border_col = accent

	if defeated and not is_core:
		border_col = Color(0.35, 0.95, 0.45, 1.0)

	_style_btn(btn, bg_col, border_col)
	if greyed and not is_core:
		btn.disabled = true
		btn.modulate = Color(0.55, 0.55, 0.6, 1.0)
	elif locked_core:
		btn.disabled = true
		btn.modulate = Color(0.65, 0.55, 0.75, 1.0)
	else:
		btn.pressed.connect(_on_boss_pressed.bind(id))

	root.add_child(btn)

	# Portrait stub swatch
	var swatch := ColorRect.new()
	swatch.name = "Portrait"
	swatch.size = Vector2(18, 18)
	swatch.position = Vector2(4, 4)
	if greyed:
		swatch.color = Color(0.3, 0.3, 0.35, 0.9)
	else:
		swatch.color = accent
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = _short_name(boss_name)
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

	# Status line
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

	# Checkmark overlay (extra clear for defeated)
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

	# Secret armor pending stub (Stage Flight torso for Beatfire)
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


func _short_name(full: String) -> String:
	# Fit in tiny cell — keep GDD Spanish labels, wrap via autowrap.
	return full


func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 2
	normal.content_margin_right = 2
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.12)
	hover.border_color = border.lightened(0.15)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.15)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.1, 0.1, 0.14, 0.9)
	disabled.border_color = Color(0.3, 0.3, 0.35, 0.7)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


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
		AudioManager.play_sfx("ui_confirm")
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

