extends Control
## Selector de 3 slots de guardado — Nueva partida / Continuar.

const CHAR_SELECT := "res://scenes/ui/CharacterSelect.tscn"
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"

const SLOT_W := 220.0
const SLOT_H := 42.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.06, 0.05, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var is_new := GameState.save_ui_mode != "continue"
	var header := Label.new()
	header.name = "Header"
	header.text = "Nueva partida" if is_new else "Continuar"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 11)
	header.modulate = Color(0.45, 0.95, 1.0, 1.0) if is_new else Color(0.55, 1.0, 0.65, 1.0)
	header.position = Vector2(0, 6)
	header.size = Vector2(256, 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Elige un slot (0–2)" if is_new else "Elige una partida guardada"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 6)
	hint.modulate = Color(0.7, 0.75, 0.85, 0.85)
	hint.position = Vector2(0, 22)
	hint.size = Vector2(256, 10)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	var list := Control.new()
	list.name = "SlotList"
	list.position = Vector2(18, 36)
	list.size = Vector2(SLOT_W, SLOT_H * 3 + 12)
	add_child(list)

	for i in GameState.SAVE_SLOT_COUNT:
		var cell := _make_slot_cell(i, is_new)
		cell.position = Vector2(0, i * (SLOT_H + 4))
		list.add_child(cell)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 7)
	back.position = Vector2(4, 200)
	back.size = Vector2(48, 18)
	_style_btn(back, Color(0.18, 0.18, 0.26, 0.95), Color(0.55, 0.6, 0.7, 0.85))
	back.pressed.connect(_on_back)
	add_child(back)


func _make_slot_cell(slot: int, is_new: bool) -> Control:
	var summary: Dictionary = GameState.get_slot_summary(slot)
	var exists: bool = bool(summary.get("exists", false))
	var empty: bool = bool(summary.get("empty", true))

	var root := Control.new()
	root.name = "Slot_%d" % slot
	root.size = Vector2(SLOT_W, SLOT_H)
	root.set_meta("slot", slot)

	var btn := Button.new()
	btn.name = "SlotButton"
	btn.text = ""
	btn.size = Vector2(SLOT_W, SLOT_H)
	btn.position = Vector2.ZERO
	btn.focus_mode = Control.FOCUS_ALL

	var bg_col: Color
	var border_col: Color
	if empty:
		bg_col = Color(0.1, 0.1, 0.16, 0.95)
		border_col = Color(0.4, 0.45, 0.55, 0.8)
	else:
		var char_id := str(summary.get("character", "miku"))
		if char_id == "teto":
			bg_col = Color(0.22, 0.08, 0.1, 0.95)
			border_col = Color(0.92, 0.35, 0.4, 1.0)
		else:
			bg_col = Color(0.08, 0.16, 0.2, 0.95)
			border_col = Color(0.3, 0.9, 1.0, 1.0)

	# Continuar: deshabilitar vacíos
	if not is_new and empty:
		btn.disabled = true
		bg_col = Color(0.08, 0.08, 0.1, 0.9)
		border_col = Color(0.28, 0.28, 0.32, 0.7)

	_style_btn(btn, bg_col, border_col)
	if not btn.disabled:
		btn.pressed.connect(_on_slot_pressed.bind(slot, is_new, exists))
	root.add_child(btn)

	var title := Label.new()
	title.name = "SlotTitle"
	title.text = "Slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 8)
	title.modulate = Color(0.95, 0.95, 1.0, 1.0)
	title.position = Vector2(8, 4)
	title.size = Vector2(80, 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(title)

	var detail := Label.new()
	detail.name = "SlotSummary"
	detail.add_theme_font_size_override("font_size", 6)
	detail.position = Vector2(8, 18)
	detail.size = Vector2(204, 20)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if empty:
		detail.text = "Vacío" if is_new else "Sin datos"
		detail.modulate = Color(0.6, 0.65, 0.75, 0.85)
	else:
		var bosses: int = int(summary.get("bosses_beaten", 0))
		var tanks: int = int(summary.get("energy_tanks", 0))
		var cname: String = str(summary.get("character_name", "?"))
		detail.text = "%s · %d/8 jefes · ET %d" % [cname, bosses, tanks]
		if is_new:
			detail.text += "  (sobrescribir)"
		detail.modulate = Color(0.85, 0.9, 0.95, 0.95)
	btn.add_child(detail)

	return root


func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.12)
	hover.border_color = border.lightened(0.15)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.15)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	disabled.border_color = Color(0.28, 0.28, 0.32, 0.7)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


func _on_slot_pressed(slot: int, is_new: bool, exists: bool) -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if is_new:
		if exists:
			GameState.delete_slot(slot)
		GameState.begin_new_game(slot)
		print("SaveSelect: nueva partida → slot %d" % slot)
		get_tree().change_scene_to_file(CHAR_SELECT)
	else:
		if not GameState.begin_continue(slot):
			print("SaveSelect: falló cargar slot %d" % slot)
			return
		print("SaveSelect: continuar slot %d" % slot)
		get_tree().change_scene_to_file(BOSS_SELECT)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file(TITLE_SCENE)
