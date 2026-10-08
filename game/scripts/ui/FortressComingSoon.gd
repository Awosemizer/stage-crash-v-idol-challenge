extends Control
## Hub Fortaleza CORE-9 — lista de etapas + progreso claro.
## Landscape SafeArea; Enter/Return tappable.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const LOBBY := "res://scenes/levels/LevelFortressLobby.tscn"
const ARCHIVE := "res://scenes/levels/LevelVoiceArchive.tscn"
const SHAFT := "res://scenes/levels/LevelCoreShaft.tscn"
const HEART := "res://scenes/levels/LevelHeartCore9.tscn"

## Linear assault stages (id, display, scene).
const STAGES: Array = [
	{"id": "lobby", "name": "1 · Lobby Neon", "desc": "Midboss: Refrain Unit", "scene": LOBBY},
	{"id": "archive", "name": "2 · Voice Archive", "desc": "Sellos vocales", "scene": ARCHIVE},
	{"id": "shaft", "name": "3 · Core Shaft", "desc": "Midboss: Overdub Titan", "scene": SHAFT},
	{"id": "heart", "name": "4 · Heart CORE-9", "desc": "Jefe final", "scene": HEART},
]


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	if AudioManager:
		AudioManager.play_stage_bgm("fortress")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.03, 0.09, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	ArtKit.add_menu_frame(self)

	var accent := ColorRect.new()
	accent.name = "Accent"
	accent.color = Color(0.85, 0.3, 0.95, 0.9)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "SYNTHOCORP · FORTALEZA CORE-9"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(header, 11, Color(0.9, 0.55, 1.0, 1.0), 2)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var progress := Label.new()
	progress.name = "ProgressLabel"
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 7)
	progress.modulate = Color(0.7, 0.85, 1.0, 0.9)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress)

	var list := VBoxContainer.new()
	list.name = "StageList"
	list.add_theme_constant_override("separation", 3)
	add_child(list)

	var cleared := _fortress_cleared_count()
	var core_done := GameState.is_boss_defeated(GameState.BOSS_CORE9) if GameState else false
	for i in STAGES.size():
		var data: Dictionary = STAGES[i]
		var row := _make_stage_row(data, i, cleared, core_done)
		list.add_child(row)

	var enter := Button.new()
	enter.name = "EnterButton"
	if core_done:
		enter.text = "Repetir asalto"
	else:
		enter.text = "Entrar al asalto"
	enter.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(enter, Color(0.04, 0.04, 0.06, 0.96), Color(0.95, 0.35, 0.72, 1.0), 2)
	enter.pressed.connect(_on_enter)
	add_child(enter)

	var back := Button.new()
	back.name = "ReturnButton"
	back.text = "Volver al selector"
	back.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(back, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	back.pressed.connect(_on_return)
	add_child(back)

	_refresh_progress_label()


func _fortress_cleared_count() -> int:
	## Best-effort from GameState flags (session + save).
	if GameState == null:
		return 0
	if GameState.has_method("get_fortress_progress"):
		return int(GameState.get_fortress_progress())
	# Fallback: only CORE-9 known
	if GameState.is_boss_defeated(GameState.BOSS_CORE9):
		return 4
	return 0


func _refresh_progress_label() -> void:
	var lbl := get_node_or_null("ProgressLabel") as Label
	if lbl == null:
		return
	var core_done := GameState.is_boss_defeated(GameState.BOSS_CORE9) if GameState else false
	var n := _fortress_cleared_count()
	if core_done:
		lbl.text = "Progreso: COMPLETADO · CORE-9 vencido"
		lbl.modulate = Color(0.55, 1.0, 0.7, 1.0)
	else:
		lbl.text = "Progreso asalto: %d / 4 etapas" % mini(n, 4)
		lbl.modulate = Color(0.7, 0.85, 1.0, 0.9)


func _make_stage_row(data: Dictionary, index: int, cleared: int, core_done: bool) -> Control:
	var row := Panel.new()
	row.name = "Stage_%s" % str(data.get("id", index))
	var sb := StyleBoxFlat.new()
	var done := core_done or index < cleared
	var current := (not core_done) and index == cleared
	if done:
		sb.bg_color = Color(0.08, 0.18, 0.12, 0.92)
		sb.border_color = Color(0.4, 0.95, 0.55, 0.95)
	elif current:
		sb.bg_color = Color(0.16, 0.08, 0.22, 0.95)
		sb.border_color = Color(0.95, 0.55, 1.0, 1.0)
	else:
		sb.bg_color = Color(0.08, 0.06, 0.12, 0.9)
		sb.border_color = Color(0.4, 0.35, 0.5, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size = Vector2(0, 28)

	var title := Label.new()
	title.name = "Title"
	title.text = str(data.get("name", "?"))
	title.add_theme_font_size_override("font_size", 8)
	title.modulate = Color(0.95, 0.9, 1.0, 1.0) if (done or current) else Color(0.55, 0.55, 0.65, 1.0)
	title.position = Vector2(8, 2)
	title.size = Vector2(200, 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)

	var desc := Label.new()
	desc.name = "Desc"
	var status := "✓ Hecho" if done else ("▶ Siguiente" if current else "Bloqueado")
	desc.text = "%s · %s" % [str(data.get("desc", "")), status]
	desc.add_theme_font_size_override("font_size", 6)
	if done:
		desc.modulate = Color(0.55, 1.0, 0.7, 0.95)
	elif current:
		desc.modulate = Color(1.0, 0.75, 1.0, 0.95)
	else:
		desc.modulate = Color(0.5, 0.5, 0.6, 0.8)
	desc.position = Vector2(8, 14)
	desc.size = Vector2(260, 12)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(desc)
	return row


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var band_bottom := area.position.y + 28.0
	ArtKit.layout_menu_frame(self, band_bottom)

	var accent := get_node_or_null("Accent") as ColorRect
	if accent:
		accent.visible = false

	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 14)

	var progress := get_node_or_null("ProgressLabel") as Label
	if progress:
		progress.position = Vector2(area.position.x, area.position.y + 16.0)
		progress.size = Vector2(area.size.x, 12)

	var btn_h := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 36.0))
	var enter := get_node_or_null("EnterButton") as Button
	var back := get_node_or_null("ReturnButton") as Button
	var gap := 4.0
	var back_y := area.end.y - btn_h
	var enter_y := back_y - btn_h - gap
	if enter:
		enter.size = Vector2(minf(220.0, area.size.x), btn_h)
		enter.position = Vector2(area.position.x + (area.size.x - enter.size.x) * 0.5, enter_y)
	if back:
		back.size = Vector2(minf(200.0, area.size.x), btn_h)
		back.position = Vector2(area.position.x + (area.size.x - back.size.x) * 0.5, back_y)

	var list := get_node_or_null("StageList") as VBoxContainer
	if list:
		var list_top := area.position.y + 30.0
		var list_bottom := enter_y - 6.0
		var lw := minf(320.0, area.size.x - 8.0)
		list.position = Vector2(area.position.x + (area.size.x - lw) * 0.5, list_top)
		list.size = Vector2(lw, maxf(list_bottom - list_top, 60.0))
		for child in list.get_children():
			if child is Control:
				(child as Control).custom_minimum_size = Vector2(lw, maxf(26.0, (list.size.y - 12.0) / 4.0))
				var title := child.get_node_or_null("Title") as Label
				var desc := child.get_node_or_null("Desc") as Label
				if title:
					title.size = Vector2(lw - 16.0, 12)
				if desc:
					desc.size = Vector2(lw - 16.0, 12)


func _on_enter() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	# Always start linear assault from Lobby (replay-friendly)
	if GameState and GameState.has_method("reset_fortress_run"):
		GameState.reset_fortress_run()
	print("Fortaleza: entrando Lobby Neon")
	get_tree().change_scene_to_file(LOBBY)


func _on_return() -> void:
	if AudioManager:
		AudioManager.play_sfx("menu_move")
	get_tree().change_scene_to_file(BOSS_SELECT)
