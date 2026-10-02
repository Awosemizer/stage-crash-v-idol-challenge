extends Control
## Créditos stub → Boss Select.
## Landscape SafeArea; Return button tappable.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const BOSS_SELECT := "res://scenes/ui/BossSelect.tscn"


func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	get_tree().create_timer(6.0).timeout.connect(_go_select)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.03, 0.03, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.text = "CRÉDITOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(0.85, 0.9, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var body := Label.new()
	body.name = "Body"
	body.text = (
		"Stage Crash: V-Idol Challenge\n"
		+ "Prototipo Godot 4.5\n\n"
		+ "Diseño / código: Luis L +\n"
		+ "asistente Grok\n\n"
		+ "Hatsune Miku · Kasane Teto\n"
		+ "(personajes de sus creadores)\n\n"
		+ "¡Gracias por jugar!"
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 8)
	body.modulate = Color(0.75, 0.8, 0.9, 0.95)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

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
		title.position = Vector2(area.position.x, area.position.y + 16.0)
		title.size = Vector2(area.size.x, 20)
	var body := get_node_or_null("Body") as Label
	if body:
		body.position = Vector2(area.position.x + 24.0, area.position.y + 44.0)
		body.size = Vector2(area.size.x - 48.0, 120)
	var btn := get_node_or_null("ReturnButton") as Button
	if btn:
		var bh := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 40.0))
		btn.size = Vector2(minf(200.0, area.size.x), bh)
		btn.position = Vector2(area.position.x + (area.size.x - btn.size.x) * 0.5, area.end.y - bh - 4.0)


func _go_select() -> void:
	get_tree().change_scene_to_file(BOSS_SELECT)
