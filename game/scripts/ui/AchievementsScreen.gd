extends Control
## Pantalla de logros — lista ES desde GameState.
## Landscape SafeArea + scroll; Back ≥28–44px.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"

var return_to := "title"


func _ready() -> void:
	if Engine.has_meta("achievements_return"):
		return_to = str(Engine.get_meta("achievements_return"))
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	ArtKit.add_menu_frame(self)

	var header := Label.new()
	header.name = "Header"
	header.text = "LOGROS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ArtKit.style_title_label(header, 14, Color(1.0, 0.85, 0.3, 1.0), 3)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var unlocked_n := 0
	var defs: Array = []
	if GameState and GameState.has_method("get_achievement_defs"):
		defs = GameState.get_achievement_defs()
		for d in defs:
			if GameState.has_achievement(str(d.get("id", ""))):
				unlocked_n += 1
	var total := maxi(defs.size(), 1)

	var count := Label.new()
	count.name = "CountLabel"
	count.text = "%d / %d desbloqueados" % [unlocked_n, defs.size()]
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 8)
	count.modulate = Color(0.75, 0.8, 0.9, 0.9)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "AchList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for d in defs:
		var aid := str(d.get("id", ""))
		var title := str(d.get("title", aid))
		var desc := str(d.get("desc", ""))
		var got := GameState.has_achievement(aid) if GameState else false
		var row := _make_row(title, desc, got)
		list.add_child(row)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Volver"
	back.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(back, Color(0.04, 0.04, 0.06, 0.96), Color(0.35, 0.9, 1.0, 1.0), 2)
	back.pressed.connect(_on_back)
	add_child(back)

	var pct := Label.new()
	pct.name = "PctLabel"
	pct.text = "%d%%" % int(round(100.0 * float(unlocked_n) / float(total)))
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_size_override("font_size", 10)
	pct.modulate = Color(1.0, 0.85, 0.35, 0.95)
	pct.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pct)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var band_bottom := area.position.y + 36.0
	ArtKit.layout_menu_frame(self, band_bottom)
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 2.0)
		header.size = Vector2(area.size.x, 18)
	var count := get_node_or_null("CountLabel") as Label
	if count:
		count.position = Vector2(area.position.x, area.position.y + 20.0)
		count.size = Vector2(area.size.x, 12)

	var btn_h := maxf(_SafeArea.MIN_BTN_H, 32.0)
	var back := get_node_or_null("BackButton") as Button
	if back:
		back.size = Vector2(100, btn_h)
		back.position = Vector2(area.position.x, area.end.y - btn_h)
	var pct := get_node_or_null("PctLabel") as Label
	if pct:
		pct.position = Vector2(area.end.x - 72.0, area.end.y - btn_h + 6.0)
		pct.size = Vector2(68, 18)

	var scroll := get_node_or_null("Scroll") as ScrollContainer
	if scroll:
		scroll.position = Vector2(area.position.x, band_bottom + 4.0)
		scroll.size = Vector2(area.size.x, maxf(area.end.y - btn_h - 8.0 - scroll.position.y, 60.0))
		var list := scroll.get_node_or_null("AchList") as VBoxContainer
		if list:
			for row in list.get_children():
				if row is Control:
					var r := row as Control
					r.custom_minimum_size = Vector2(area.size.x - 8.0, 32)
					r.size.x = area.size.x - 8.0
					if r.get_child_count() > 0 and r.get_child(0) is ColorRect:
						(r.get_child(0) as ColorRect).size = Vector2(area.size.x - 8.0, 32)


func _make_row(title: String, desc: String, got: bool) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(280, 32)
	root.size = Vector2(280, 32)

	var bg := ColorRect.new()
	bg.size = Vector2(280, 32)
	if got:
		bg.color = Color(0.12, 0.18, 0.12, 0.95)
	else:
		bg.color = Color(0.1, 0.1, 0.14, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var mark := Label.new()
	mark.text = "★" if got else "·"
	mark.add_theme_font_size_override("font_size", 12)
	mark.modulate = Color(1.0, 0.85, 0.3, 1.0) if got else Color(0.45, 0.45, 0.5, 0.8)
	mark.position = Vector2(6, 6)
	mark.size = Vector2(18, 18)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mark)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 9)
	t.modulate = Color(0.95, 0.98, 1.0, 1.0) if got else Color(0.55, 0.58, 0.65, 1.0)
	t.position = Vector2(28, 2)
	t.size = Vector2(240, 14)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 7)
	d.modulate = Color(0.7, 0.85, 0.7, 0.95) if got else Color(0.45, 0.48, 0.55, 0.85)
	d.position = Vector2(28, 16)
	d.size = Vector2(240, 14)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(d)

	return root


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if return_to == "boss_select":
		get_tree().change_scene_to_file(BOSS_SELECT)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)
