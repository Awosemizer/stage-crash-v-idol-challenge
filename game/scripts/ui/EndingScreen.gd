extends Control
## Ending — texto claro Miku / Teto, skip, tap-to-advance → créditos.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const CREDITS := "res://scenes/ui/CreditsScreen.tscn"

var _lines: PackedStringArray = PackedStringArray()
var _line_i := 0
var _busy := false
var _auto_timer: SceneTreeTimer = null


func _ready() -> void:
	if GameState and GameState.has_method("on_ending_reached"):
		GameState.on_ending_reached()
	_prepare_lines()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	if AudioManager:
		AudioManager.play_victory()
	_show_line(0)
	_arm_auto(4.0)


func _prepare_lines() -> void:
	var is_teto := GameState.is_teto() if GameState and GameState.has_method("is_teto") else false
	var char_name := "Kasane Teto" if is_teto else "Hatsune Miku"
	if is_teto:
		_lines = PackedStringArray([
			"STAGE CLEAR",
			"%s corta el último acorde." % char_name,
			"SynthoCorp calla. El público — virtual o no — grita su nombre.",
			"«No soy un eco. Soy el bis.»",
			"CORE-9 apagado. El escenario es suyo.",
		])
	else:
		_lines = PackedStringArray([
			"STAGE CLEAR",
			"%s apaga el núcleo." % char_name,
			"Las luces del escenario vuelven a ser solo luces. Ella sonríe.",
			"«El show continúa… con nosotras.»",
			"CORE-9 apagado. El concierto sigue.",
		])


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.04, 0.02, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	var accent := ColorRect.new()
	accent.name = "Accent"
	accent.color = Color(0.85, 0.35, 0.95, 0.9)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var header := Label.new()
	header.name = "Header"
	header.text = "STAGE CLEAR"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	header.modulate = Color(0.95, 0.6, 1.0, 1.0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	var char_lbl := Label.new()
	char_lbl.name = "CharLabel"
	var is_teto := GameState.is_teto() if GameState and GameState.has_method("is_teto") else false
	char_lbl.text = "Kasane Teto" if is_teto else "Hatsune Miku"
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_lbl.add_theme_font_size_override("font_size", 11)
	char_lbl.modulate = Color(1.0, 0.55, 0.6, 1.0) if is_teto else Color(0.45, 0.95, 1.0, 1.0)
	char_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_lbl)

	var body := Label.new()
	body.name = "Body"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 10)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.92, 0.9, 1.0, 1.0)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Toca para continuar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 7)
	hint.modulate = Color(0.7, 0.75, 0.85, 0.8)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	var skip := Button.new()
	skip.name = "SkipButton"
	skip.text = "Saltar →"
	skip.add_theme_font_size_override("font_size", 10)
	_SafeArea.style_button(skip, Color(0.14, 0.08, 0.2, 0.95), Color(0.85, 0.35, 0.95))
	skip.pressed.connect(_go_credits)
	add_child(skip)

	var nxt := Button.new()
	nxt.name = "NextButton"
	nxt.text = "Siguiente"
	nxt.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(nxt, Color(0.12, 0.1, 0.22, 0.95), Color(0.55, 0.85, 1.0))
	nxt.pressed.connect(_advance)
	add_child(nxt)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var accent := get_node_or_null("Accent") as ColorRect
	if accent:
		accent.position = Vector2(0, area.position.y + 26.0)
		accent.size = Vector2(vp.x, 2)
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 4.0)
		header.size = Vector2(area.size.x, 20)
	var char_lbl := get_node_or_null("CharLabel") as Label
	if char_lbl:
		char_lbl.position = Vector2(area.position.x, area.position.y + 28.0)
		char_lbl.size = Vector2(area.size.x, 16)
	var body := get_node_or_null("Body") as Label
	if body:
		body.position = Vector2(area.position.x + 20.0, area.position.y + 50.0)
		body.size = Vector2(area.size.x - 40.0, maxf(area.size.y - 110.0, 48.0))
	var hint := get_node_or_null("Hint") as Label
	var bh := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 36.0))
	var skip := get_node_or_null("SkipButton") as Button
	var nxt := get_node_or_null("NextButton") as Button
	var gap := 6.0
	var total_w := minf(area.size.x - 8.0, 280.0)
	var skip_w := floorf(total_w * 0.38)
	var next_w := total_w - skip_w - gap
	var row_x := area.position.x + (area.size.x - total_w) * 0.5
	var row_y := area.end.y - bh - 2.0
	if skip:
		skip.size = Vector2(skip_w, bh)
		skip.position = Vector2(row_x, row_y)
	if nxt:
		nxt.size = Vector2(next_w, bh)
		nxt.position = Vector2(row_x + skip_w + gap, row_y)
	if hint:
		hint.position = Vector2(area.position.x, row_y - 14.0)
		hint.size = Vector2(area.size.x, 12)


func _show_line(i: int) -> void:
	_line_i = clampi(i, 0, maxi(_lines.size() - 1, 0))
	var body := get_node_or_null("Body") as Label
	var header := get_node_or_null("Header") as Label
	if _lines.is_empty():
		return
	var text := _lines[_line_i]
	if _line_i == 0 and header:
		header.text = text
		if body:
			body.text = "…"
	else:
		if header:
			header.text = "STAGE CLEAR"
		if body:
			body.text = text
	var nxt := get_node_or_null("NextButton") as Button
	if nxt:
		nxt.text = "Créditos" if _line_i >= _lines.size() - 1 else "Siguiente"


func _advance() -> void:
	if _busy:
		return
	if _line_i >= _lines.size() - 1:
		_go_credits()
		return
	_show_line(_line_i + 1)
	_arm_auto(3.5)


func _arm_auto(sec: float) -> void:
	# Auto-advance; cancelled by manual tap
	var tree := get_tree()
	if tree == null:
		return
	var my_i := _line_i
	tree.create_timer(sec).timeout.connect(func () -> void:
		if not is_instance_valid(self):
			return
		if _line_i == my_i:
			_advance()
	)


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_advance()
		get_viewport().set_input_as_handled()


func _go_credits() -> void:
	if _busy:
		return
	_busy = true
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file(CREDITS)
