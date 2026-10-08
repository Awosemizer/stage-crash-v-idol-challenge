extends Control
## Créditos con scroll / tap-to-advance → pantalla de título (v0.60; la partida queda guardada).

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"
const TITLE_SCENE := "res://scenes/ui/TitleScreen.tscn"

const CREDIT_LINES: PackedStringArray = [
	"Stage Crash: V-Idol Challenge",
	"Hecho con Godot 4.5",
	"",
	"Diseño / código",
	"Luis L + asistente Grok",
	"",
	"Hatsune Miku · Kasane Teto",
	"(personajes de sus creadores)",
	"",
	"Robot Masters · Fortaleza CORE-9",
	"Stage Flight · Encore Guard",
	"",
	"¡Gracias por jugar!",
	"",
	"— Fin —",
]

var _scroll := 0.0
var _busy := false
var _body: Label = null


func _ready() -> void:
	# Ensure CORE-9 stays marked when returning
	if GameState:
		if GameState.has_method("on_ending_reached"):
			# idempotent achievements
			pass
		if not GameState.is_boss_defeated(GameState.BOSS_CORE9):
			GameState.mark_boss_defeated(GameState.BOSS_CORE9)
		GameState.fortress_segment = 4
		if GameState.active_slot >= 0:
			GameState.autosave()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	set_process(true)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.03, 0.03, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.text = "CRÉDITOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(0.85, 0.9, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var clip := Control.new()
	clip.name = "Clip"
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)

	_body = Label.new()
	_body.name = "Body"
	_body.text = "\n".join(CREDIT_LINES)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 9)
	_body.modulate = Color(0.78, 0.82, 0.92, 0.98)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_body)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Toca para acelerar · botón para salir"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 6)
	hint.modulate = Color(0.6, 0.65, 0.75, 0.85)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	var btn := Button.new()
	btn.name = "ReturnButton"
	btn.text = "Volver al selector"
	btn.add_theme_font_size_override("font_size", 11)
	_SafeArea.style_button(btn, Color(0.12, 0.12, 0.18, 0.95), Color(0.55, 0.7, 0.95))
	btn.pressed.connect(_go_select)
	add_child(btn)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var title := get_node_or_null("Title") as Label
	if title:
		title.position = Vector2(area.position.x, area.position.y + 4.0)
		title.size = Vector2(area.size.x, 18)
	var bh := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 40.0))
	var btn := get_node_or_null("ReturnButton") as Button
	if btn:
		btn.size = Vector2(minf(220.0, area.size.x), bh)
		btn.position = Vector2(area.position.x + (area.size.x - btn.size.x) * 0.5, area.end.y - bh - 2.0)
	var hint := get_node_or_null("Hint") as Label
	if hint:
		hint.position = Vector2(area.position.x, area.end.y - bh - 16.0)
		hint.size = Vector2(area.size.x, 12)
	var clip := get_node_or_null("Clip") as Control
	if clip and _body:
		var top := area.position.y + 26.0
		var bottom := area.end.y - bh - 20.0
		clip.position = Vector2(area.position.x + 16.0, top)
		clip.size = Vector2(area.size.x - 32.0, maxf(bottom - top, 40.0))
		_body.size = Vector2(clip.size.x, 220.0)
		_body.position = Vector2(0, clip.size.y - _scroll)


func _process(delta: float) -> void:
	_scroll += 22.0 * delta
	var clip := get_node_or_null("Clip") as Control
	if clip and _body:
		_body.position = Vector2(0, clip.size.y - _scroll)
		# When scroll finishes, wait then return
		if _scroll > clip.size.y + _body.size.y + 20.0 and not _busy:
			_go_select()


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_scroll += 48.0
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_scroll += 48.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_go_select()
		get_viewport().set_input_as_handled()


func _go_select() -> void:
	if _busy:
		return
	_busy = true
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	if GameState and GameState.active_slot >= 0:
		GameState.autosave()
	get_tree().change_scene_to_file(TITLE_SCENE)
