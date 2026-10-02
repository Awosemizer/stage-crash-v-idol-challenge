extends Control
## Selector de 3 slots de guardado — Nueva partida / Continuar.
## Landscape SafeArea layout; slot rows ≥44px when space allows.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const CHAR_SELECT := "res://scenes/ui/CharacterSelect.tscn"
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"

var _slot_w := 280.0
var _slot_h := 44.0


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.06, 0.05, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var concert := ArtKit.menu_backdrop("res://assets/sprites/ui/menu_concert.png")
	if concert:
		concert.name = "MenuBG"
		add_child(concert)

	var is_new := GameState.save_ui_mode != "continue"
	var header := Label.new()
	header.name = "Header"
	header.text = "Nueva partida" if is_new else "Continuar"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.modulate = Color(0.45, 0.95, 1.0, 1.0) if is_new else Color(0.55, 1.0, 0.65, 1.0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Si el slot tiene datos, se reemplaza" if is_new else "Elige una partida guardada"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.7, 0.75, 0.85, 0.85)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	var list := Control.new()
	list.name = "SlotList"
	add_child(list)

	for i in GameState.SAVE_SLOT_COUNT:
		var cell := _make_slot_cell(i, is_new)
		list.add_child(cell)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(back, Color(0.18, 0.18, 0.26, 0.95), Color(0.55, 0.6, 0.7, 0.85))
	back.pressed.connect(_on_back)
	add_child(back)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 18)
	var hint := get_node_or_null("Hint") as Label
	if hint:
		hint.position = Vector2(area.position.x, area.position.y + 22.0)
		hint.size = Vector2(area.size.x, 12)

	var btn_h := maxf(_SafeArea.MIN_BTN_H, 36.0)
	var back := get_node_or_null("BackButton") as Button
	if back:
		back.size = Vector2(96, btn_h)
		back.position = Vector2(area.position.x, area.end.y - btn_h)

	var list_top := area.position.y + 38.0
	var list_bottom := area.end.y - btn_h - 8.0
	var list_h := maxf(list_bottom - list_top, 120.0)
	_slot_h = _SafeArea.btn_h(list_h, 3, 6.0, true)
	_slot_w = minf(area.size.x, 320.0)

	var list := get_node_or_null("SlotList") as Control
	if list == null:
		return
	list.size = Vector2(_slot_w, _slot_h * 3.0 + 12.0)
	list.position = Vector2(
		area.position.x + maxf((area.size.x - _slot_w) * 0.5, 0.0),
		list_top
	)
	for i in list.get_child_count():
		var cell := list.get_child(i) as Control
		if cell == null:
			continue
		cell.position = Vector2(0, i * (_slot_h + 6.0))
		cell.size = Vector2(_slot_w, _slot_h)
		var btn := cell.get_node_or_null("SlotButton") as Button
		if btn:
			btn.size = Vector2(_slot_w, _slot_h)
			var title := btn.get_node_or_null("SlotTitle") as Label
			if title:
				title.position = Vector2(10, 6)
				title.size = Vector2(_slot_w - 20, 14)
				title.add_theme_font_size_override("font_size", 12 if _slot_h >= 40.0 else 10)
			var detail := btn.get_node_or_null("SlotSummary") as Label
			if detail:
				detail.position = Vector2(10, maxf(_slot_h * 0.45, 18.0))
				detail.size = Vector2(_slot_w - 20, maxf(_slot_h * 0.45, 16.0))
				detail.add_theme_font_size_override("font_size", 10 if _slot_h >= 40.0 else 8)


func _make_slot_cell(slot: int, is_new: bool) -> Control:
	var summary: Dictionary = GameState.get_slot_summary(slot)
	var exists: bool = bool(summary.get("exists", false))
	var empty: bool = bool(summary.get("empty", true))

	var root := Control.new()
	root.name = "Slot_%d" % slot
	root.size = Vector2(_slot_w, _slot_h)
	root.set_meta("slot", slot)

	var btn := Button.new()
	btn.name = "SlotButton"
	btn.text = ""
	btn.size = Vector2(_slot_w, _slot_h)
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

	if not is_new and empty:
		btn.disabled = true
		bg_col = Color(0.08, 0.08, 0.1, 0.9)
		border_col = Color(0.28, 0.28, 0.32, 0.7)

	_SafeArea.style_button(btn, bg_col, border_col, 4)
	if not btn.disabled:
		btn.pressed.connect(_on_slot_pressed.bind(slot, is_new, exists))
	root.add_child(btn)

	var title := Label.new()
	title.name = "SlotTitle"
	title.text = "Slot %d" % (slot + 1)
	title.add_theme_font_size_override("font_size", 11)
	title.modulate = Color(0.95, 0.95, 1.0, 1.0)
	title.position = Vector2(8, 4)
	title.size = Vector2(80, 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(title)

	var detail := Label.new()
	detail.name = "SlotSummary"
	detail.add_theme_font_size_override("font_size", 9)
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
		var diff_s := str(summary.get("difficulty", "normal"))
		var diff_tag := "Difícil" if diff_s == "hard" else "Normal"
		detail.text = "%s · %d/8 · ET %d · %s" % [cname, bosses, tanks, diff_tag]
		if is_new:
			detail.text += " · se reemplaza"
		detail.modulate = Color(0.85, 0.9, 0.95, 0.95)
	btn.add_child(detail)

	return root


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
