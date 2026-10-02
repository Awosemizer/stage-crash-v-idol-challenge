extends Control
## Pantalla de logros — lista ES desde GameState.

const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"

## Quién abrió la pantalla: "title" | "boss_select"
var return_to := "title"


func _ready() -> void:
	if Engine.has_meta("achievements_return"):
		return_to = str(Engine.get_meta("achievements_return"))
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var header := Label.new()
	header.name = "Header"
	header.text = "LOGROS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.modulate = Color(1.0, 0.85, 0.3, 1.0)
	header.position = Vector2(0, 4)
	header.size = Vector2(256, 16)
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
	count.add_theme_font_size_override("font_size", 7)
	count.modulate = Color(0.75, 0.8, 0.9, 0.9)
	count.position = Vector2(0, 20)
	count.size = Vector2(256, 10)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.position = Vector2(8, 34)
	scroll.size = Vector2(240, 152)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "AchList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
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
	back.add_theme_font_size_override("font_size", 8)
	back.position = Vector2(8, 196)
	back.size = Vector2(56, 20)
	_style_btn(back, Color(0.18, 0.18, 0.26, 0.95), Color(0.55, 0.6, 0.7, 0.85))
	back.pressed.connect(_on_back)
	add_child(back)

	var pct := Label.new()
	pct.name = "PctLabel"
	pct.text = "%d%%" % int(round(100.0 * float(unlocked_n) / float(total)))
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_size_override("font_size", 8)
	pct.modulate = Color(1.0, 0.85, 0.35, 0.95)
	pct.position = Vector2(180, 198)
	pct.size = Vector2(68, 14)
	pct.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pct)


func _make_row(title: String, desc: String, got: bool) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(228, 28)
	root.size = Vector2(228, 28)

	var bg := ColorRect.new()
	bg.size = Vector2(228, 28)
	if got:
		bg.color = Color(0.12, 0.18, 0.12, 0.95)
	else:
		bg.color = Color(0.1, 0.1, 0.14, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var mark := Label.new()
	mark.text = "★" if got else "·"
	mark.add_theme_font_size_override("font_size", 10)
	mark.modulate = Color(1.0, 0.85, 0.3, 1.0) if got else Color(0.45, 0.45, 0.5, 0.8)
	mark.position = Vector2(4, 6)
	mark.size = Vector2(16, 16)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mark)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 8)
	t.modulate = Color(0.95, 0.98, 1.0, 1.0) if got else Color(0.55, 0.58, 0.65, 1.0)
	t.position = Vector2(22, 2)
	t.size = Vector2(200, 12)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t)

	var d := Label.new()
	d.text = desc
	d.add_theme_font_size_override("font_size", 6)
	d.modulate = Color(0.7, 0.85, 0.7, 0.95) if got else Color(0.45, 0.48, 0.55, 0.85)
	d.position = Vector2(22, 14)
	d.size = Vector2(200, 12)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(d)

	return root


func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_border_width_all(2)
	normal.border_color = border
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_stylebox_override("focus", hover)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if return_to == "boss_select":
		get_tree().change_scene_to_file(BOSS_SELECT)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)
