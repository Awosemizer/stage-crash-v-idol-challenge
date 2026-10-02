extends Control
## Ending — texto distinto Miku / Teto → créditos.
## Landscape SafeArea; Créditos button tappable.

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")
const CREDITS := "res://scenes/ui/CreditsScreen.tscn"


func _ready() -> void:
	if GameState and GameState.has_method("on_ending_reached"):
		GameState.on_ending_reached()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	if AudioManager:
		AudioManager.play_victory()
	get_tree().create_timer(5.5).timeout.connect(_go_credits)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.04, 0.02, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	var is_teto := GameState.is_teto() if GameState.has_method("is_teto") else false
	var body := Label.new()
	body.name = "Body"
	if is_teto:
		body.text = (
			"Kasane Teto corta el último acorde.\n"
			+ "SynthoCorp calla. El público —\n"
			+ "virtual o no — grita su nombre.\n\n"
			+ "«No soy un eco. Soy el bis.»"
		)
		body.modulate = Color(1.0, 0.55, 0.6, 1.0)
	else:
		body.text = (
			"Hatsune Miku apaga el núcleo.\n"
			+ "Las luces del escenario vuelven\n"
			+ "a ser solo luces. Ella sonríe.\n\n"
			+ "«El show continúa… con nosotras.»"
		)
		body.modulate = Color(0.45, 0.95, 1.0, 1.0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 9)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	var btn := Button.new()
	btn.name = "ContinueButton"
	btn.text = "Créditos"
	btn.add_theme_font_size_override("font_size", 12)
	_SafeArea.style_button(btn, Color(0.14, 0.08, 0.2, 0.95), Color(0.85, 0.35, 0.95))
	btn.pressed.connect(_go_credits)
	add_child(btn)


func _layout() -> void:
	var area: Rect2 = _SafeArea.content_rect()
	var vp: Vector2 = _SafeArea.viewport_size()
	var accent := get_node_or_null("Accent") as ColorRect
	if accent:
		accent.position = Vector2(0, area.position.y + 28.0)
		accent.size = Vector2(vp.x, 2)
	var header := get_node_or_null("Header") as Label
	if header:
		header.position = Vector2(area.position.x, area.position.y + 36.0)
		header.size = Vector2(area.size.x, 22)
	var body := get_node_or_null("Body") as Label
	if body:
		body.position = Vector2(area.position.x + 24.0, area.position.y + 64.0)
		body.size = Vector2(area.size.x - 48.0, 90)
	var btn := get_node_or_null("ContinueButton") as Button
	if btn:
		var bh := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 40.0))
		btn.size = Vector2(160, bh)
		btn.position = Vector2(area.position.x + (area.size.x - 160.0) * 0.5, area.end.y - bh - 4.0)


func _go_credits() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file(CREDITS)
