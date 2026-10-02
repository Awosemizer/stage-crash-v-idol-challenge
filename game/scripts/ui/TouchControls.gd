extends CanvasLayer
## Touch HUD overlay — virtual 8-dir stick + Jump / Attack / Slide + weapon prev/next.
## Presses the same InputMap actions Player.gd already reads
## (move_left/right/up/down, jump, attack, slide, weapon_prev, weapon_next).
## Also binds joypad (GDD: LB/RB=weapon, LT/RT=slide).
## Layout uses SafeArea insets so notches / bezels don't eat controls.
## Sized for phone landscape (16:9 / 20:9) with canvas_items + expand.

signal visibility_changed_for_pad(visible_now: bool)

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")

## When true, overlay stays up even if a joypad is connected.
@export var show_touch_always: bool = false
@export_range(0.2, 1.0, 0.05) var opacity: float = 0.50
@export_range(0.15, 0.6, 0.05) var stick_deadzone: float = 0.28

# Larger hit targets for thumbs on phone landscape
const STICK_R := 44.0
const KNOB_R := 16.0
const BTN_JUMP := 34.0
const BTN_ATTACK := 30.0
const BTN_SLIDE := 26.0
const BTN_WEAPON := 22.0
## Minimum clear gap between face-button hit rects (no overlap on thumbs).
const CLUSTER_GAP := 20.0
const SLIDE_GAP := 20.0
const WEAPON_GAP := 8.0
## Keep weapon switch clear of pause (28) + armor row (~15) + margin.
const WEAPON_TOP_CLEAR := 48.0

var _root: Control
var _stick_base: Panel
var _stick_knob: Panel
var _btn_jump: Panel
var _btn_attack: Panel
var _btn_slide: Panel
var _btn_wprev: Panel
var _btn_wnext: Panel
var _lbl_a: Label
var _lbl_b: Label
var _lbl_s: Label
var _lbl_wp: Label
var _lbl_wn: Label

var _stick_touch_idx := -1
var _stick_center := Vector2.ZERO
var _move_held := {"move_left": false, "move_right": false, "move_up": false, "move_down": false}
var _btn_touches: Dictionary = {}  # touch_index -> action name
var _stick_r := STICK_R


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		show_touch_always = true
	_setup_joypad_bindings()
	_build_ui()
	_apply_touch_settings_from_state()
	_apply_opacity()
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_signal("touch_settings_changed"):
		if not gs.touch_settings_changed.is_connected(_on_touch_settings_changed):
			gs.touch_settings_changed.connect(_on_touch_settings_changed)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_visibility()


func _exit_tree() -> void:
	_release_all_touch_actions()


func _setup_joypad_bindings() -> void:
	# GDD: A=jump · B/X=attack · LT/RT=slide · LB/RB=weapon · stick/D-pad=move
	# Drop legacy shoulder→slide bindings from older builds.
	_remove_joy_button("slide", JOY_BUTTON_LEFT_SHOULDER)
	_remove_joy_button("slide", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("attack", JOY_BUTTON_B)
	_add_joy_button("attack", JOY_BUTTON_X)
	# Shoulders = weapon switch (not slide)
	_add_joy_button("weapon_prev", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("weapon_next", JOY_BUTTON_RIGHT_SHOULDER)
	# Triggers = slide
	_add_joy_axis("slide", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_joy_axis("slide", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	# Stick click as extra slide ("L" in GDD)
	_add_joy_button("slide", JOY_BUTTON_LEFT_STICK)
	_add_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _add_joy_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _remove_joy_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			InputMap.action_erase_event(action, e)


func _add_joy_axis(action: StringName, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion:
			var m := e as InputEventJoypadMotion
			if m.axis == axis and is_equal_approx(m.axis_value, axis_value):
				return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	InputMap.action_add_event(action, ev)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_stick_base = _make_round_panel(Color(0.12, 0.16, 0.22, 1.0))
	_stick_base.name = "StickBase"
	_stick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_stick_base)

	_stick_knob = _make_round_panel(Color(0.35, 0.85, 0.95, 1.0))
	_stick_knob.name = "StickKnob"
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)

	_btn_jump = _make_round_panel(Color(0.2, 0.75, 0.45, 1.0))
	_btn_jump.name = "JumpBtn"
	_btn_jump.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_btn_jump)
	_lbl_a = _make_btn_label(_btn_jump, "JMP")

	_btn_attack = _make_round_panel(Color(0.9, 0.35, 0.4, 1.0))
	_btn_attack.name = "AttackBtn"
	_btn_attack.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_btn_attack)
	_lbl_b = _make_btn_label(_btn_attack, "ATK")

	_btn_slide = _make_round_panel(Color(0.55, 0.45, 0.85, 1.0))
	_btn_slide.name = "SlideBtn"
	_btn_slide.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_btn_slide)
	_lbl_s = _make_btn_label(_btn_slide, "DASH")

	# Weapon prev/next — small, upper-right (away from jump/attack cluster)
	_btn_wprev = _make_round_panel(Color(0.25, 0.55, 0.75, 1.0))
	_btn_wprev.name = "WeaponPrevBtn"
	_btn_wprev.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_btn_wprev)
	_lbl_wp = _make_btn_label(_btn_wprev, "<")

	_btn_wnext = _make_round_panel(Color(0.25, 0.55, 0.75, 1.0))
	_btn_wnext.name = "WeaponNextBtn"
	_btn_wnext.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_btn_wnext)
	_lbl_wn = _make_btn_label(_btn_wnext, ">")

	_stick_base.gui_input.connect(_on_stick_gui_input)
	_btn_jump.gui_input.connect(_on_button_gui_input.bind("jump", _btn_jump))
	_btn_attack.gui_input.connect(_on_button_gui_input.bind("attack", _btn_attack))
	_btn_slide.gui_input.connect(_on_button_gui_input.bind("slide", _btn_slide))
	_btn_wprev.gui_input.connect(_on_button_gui_input.bind("weapon_prev", _btn_wprev))
	_btn_wnext.gui_input.connect(_on_button_gui_input.bind("weapon_next", _btn_wnext))


func _make_round_panel(col: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 64
	sb.corner_radius_top_right = 64
	sb.corner_radius_bottom_left = 64
	sb.corner_radius_bottom_right = 64
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.28)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _make_btn_label(parent: Panel, text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.modulate = Color(1, 1, 1, 0.95)
	parent.add_child(lbl)
	return lbl



func _touch_size_scale() -> float:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("get_touch_size_scale"):
		return float(gs.get_touch_size_scale())
	return 1.0


func _apply_touch_settings_from_state() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null:
		if "touch_opacity" in gs:
			opacity = float(gs.touch_opacity)
	_apply_opacity()
	_layout()


func _on_touch_settings_changed() -> void:
	_apply_touch_settings_from_state()


func set_opacity(value: float) -> void:
	opacity = clampf(value, 0.2, 1.0)
	_apply_opacity()


func _apply_opacity() -> void:
	if _root:
		_root.modulate = Color(1, 1, 1, opacity)


func _layout() -> void:
	if _root == null:
		return
	var area: Rect2 = _SafeArea.content_rect()
	var left: float = area.position.x
	var top: float = area.position.y
	var right: float = area.end.x
	var bottom: float = area.end.y

	# Stick — bottom-left inside safe area (keeps mid-screen clear for play)
	var size_scale := _touch_size_scale()
	_stick_r = STICK_R * size_scale
	var stick_d := _stick_r * 2.0
	_stick_base.size = Vector2(stick_d, stick_d)
	_stick_base.position = Vector2(left, bottom - stick_d)
	_stick_center = _stick_base.position + Vector2(_stick_r, _stick_r)
	var knob_r := KNOB_R * size_scale
	_stick_knob.size = Vector2(knob_r * 2.0, knob_r * 2.0)
	_stick_knob.set_meta("knob_r", knob_r)
	_reset_knob()

	# Face buttons — bottom-right fan, NO overlapping hit rects (≥20px gaps).
	# Layout (phone landscape):
	#   [SL Slide]   [B Attack]   [A Jump]
	# Slide further left; Attack left of Jump; Jump in the corner.
	var j := BTN_JUMP * 2.0 * size_scale
	var a := BTN_ATTACK * 2.0 * size_scale
	var s := BTN_SLIDE * 2.0 * size_scale
	# Keep Attack/Dash separation at all touch sizes (S/M/L)
	var gap_cluster := maxf(CLUSTER_GAP, CLUSTER_GAP * size_scale)
	var gap_slide := maxf(SLIDE_GAP, SLIDE_GAP * size_scale)
	var attack_lift := 10.0 * size_scale
	_btn_jump.size = Vector2(j, j)
	_btn_jump.position = Vector2(right - j, bottom - j)

	# Attack — clearly left of Jump; raised so ATK/DASH don't share thumb band
	_btn_attack.size = Vector2(a, a)
	_btn_attack.position = Vector2(
		_btn_jump.position.x - a - gap_cluster,
		_btn_jump.position.y + (j - a) * 0.5 - attack_lift
	)

	# Slide — further left of Attack, bottom-aligned
	_btn_slide.size = Vector2(s, s)
	_btn_slide.position = Vector2(
		_btn_attack.position.x - s - gap_slide,
		bottom - s
	)
	# Safety: if Attack still intersects Slide vertically+horizontally, shove Attack up
	var ar := Rect2(_btn_attack.position, _btn_attack.size)
	var sr := Rect2(_btn_slide.position, _btn_slide.size)
	if ar.intersects(sr):
		_btn_attack.position.y = minf(_btn_attack.position.y, _btn_slide.position.y - a - 8.0)

	# Weapon prev/next — upper-right, clear of pause/armor and of face-button cluster
	var w := BTN_WEAPON * 2.0 * size_scale
	_btn_wnext.size = Vector2(w, w)
	_btn_wprev.size = Vector2(w, w)
	var weapon_y := top + WEAPON_TOP_CLEAR
	var cluster_top := minf(_btn_jump.position.y, minf(_btn_attack.position.y, _btn_slide.position.y))
	weapon_y = minf(weapon_y, cluster_top - w - 16.0)
	weapon_y = maxf(weapon_y, top)
	_btn_wnext.position = Vector2(right - w, weapon_y)
	_btn_wprev.position = Vector2(right - w * 2.0 - WEAPON_GAP, weapon_y)

	# Debug-assert: face buttons must not overlap (dev builds / VALIDATE)
	_assert_no_overlap(_btn_jump, _btn_attack, "Jump/Attack")
	_assert_no_overlap(_btn_attack, _btn_slide, "Attack/Slide")
	_assert_no_overlap(_btn_jump, _btn_slide, "Jump/Slide")
	_assert_no_overlap(_btn_wprev, _btn_jump, "WeaponPrev/Jump")
	_assert_no_overlap(_btn_wnext, _btn_jump, "WeaponNext/Jump")
	_assert_no_overlap(_btn_wprev, _btn_attack, "WeaponPrev/Attack")
	_assert_no_overlap(_btn_wnext, _btn_attack, "WeaponNext/Attack")

	# Keep labels readable
	if _lbl_a:
		_lbl_a.add_theme_font_size_override("font_size", 8)
	if _lbl_b:
		_lbl_b.add_theme_font_size_override("font_size", 8)
	if _lbl_s:
		_lbl_s.add_theme_font_size_override("font_size", 7)
	if _lbl_wp:
		_lbl_wp.add_theme_font_size_override("font_size", 12)
	if _lbl_wn:
		_lbl_wn.add_theme_font_size_override("font_size", 12)



func _panel_rect(p: Panel) -> Rect2:
	return Rect2(p.position, p.size)


func _assert_no_overlap(a: Panel, b: Panel, label: String) -> void:
	var ra := _panel_rect(a)
	var rb := _panel_rect(b)
	if ra.intersects(rb):
		push_warning("TouchControls overlap: %s  %s vs %s" % [label, ra, rb])


func _reset_knob() -> void:
	var kr := float(_stick_knob.get_meta("knob_r", KNOB_R)) if _stick_knob else KNOB_R
	_stick_knob.position = Vector2(_stick_r - kr, _stick_r - kr)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var has_pad := Input.get_connected_joypads().size() > 0
	var show_now := show_touch_always or not has_pad
	visible = show_now
	if not show_now:
		_release_all_touch_actions()
	visibility_changed_for_pad.emit(show_now)


func set_show_touch_always(value: bool) -> void:
	show_touch_always = value
	_refresh_visibility()


func _release_all_touch_actions() -> void:
	for action in _btn_touches.values():
		Input.action_release(str(action))
	_btn_touches.clear()
	_stick_touch_idx = -1
	_reset_knob()
	for a in _move_held.keys():
		if _move_held[a]:
			Input.action_release(a)
			_move_held[a] = false


func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_stick_touch_idx = st.index
			_update_stick_from_local(st.position)
		elif st.index == _stick_touch_idx:
			_stick_touch_idx = -1
			_set_move_actions(Vector2.ZERO)
			_reset_knob()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _stick_touch_idx:
			_update_stick_from_local(sd.position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_stick_touch_idx = 0
			_update_stick_from_local(mb.position)
		elif _stick_touch_idx == 0:
			_stick_touch_idx = -1
			_set_move_actions(Vector2.ZERO)
			_reset_knob()
	elif event is InputEventMouseMotion and _stick_touch_idx == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_stick_from_local((event as InputEventMouseMotion).position)


func _update_stick_from_local(local_pos: Vector2) -> void:
	var delta := local_pos - Vector2(_stick_r, _stick_r)
	var max_len := _stick_r - 4.0
	if delta.length() > max_len:
		delta = delta.normalized() * max_len
	var kr2 := float(_stick_knob.get_meta("knob_r", KNOB_R))
	_stick_knob.position = Vector2(_stick_r - kr2, _stick_r - kr2) + delta
	var strength := delta / max_len
	_set_move_actions(strength)


func _set_move_actions(v: Vector2) -> void:
	var want := {"move_left": false, "move_right": false, "move_up": false, "move_down": false}
	if v.length() >= stick_deadzone:
		var angle := snappedf(v.angle() / (PI * 0.25), 1.0) * (PI * 0.25)
		var dir := Vector2.from_angle(angle)
		if dir.x < -0.4:
			want["move_left"] = true
		elif dir.x > 0.4:
			want["move_right"] = true
		if dir.y < -0.4:
			want["move_up"] = true
		elif dir.y > 0.4:
			want["move_down"] = true

	for action in want.keys():
		var on: bool = want[action]
		if on and not _move_held[action]:
			Input.action_press(action)
			_move_held[action] = true
		elif not on and _move_held[action]:
			Input.action_release(action)
			_move_held[action] = false


func _on_button_gui_input(event: InputEvent, action: StringName, panel: Panel) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_btn_touches[st.index] = action
			Input.action_press(action)
			_flash_button(panel, true)
		else:
			if _btn_touches.get(st.index, "") == action or _btn_touches.has(st.index):
				_btn_touches.erase(st.index)
			Input.action_release(action)
			_flash_button(panel, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_btn_touches[-1] = action
			Input.action_press(action)
			_flash_button(panel, true)
		else:
			_btn_touches.erase(-1)
			Input.action_release(action)
			_flash_button(panel, false)
		get_viewport().set_input_as_handled()


func _flash_button(panel: Panel, down: bool) -> void:
	panel.modulate = Color(1.3, 1.3, 1.3, 1.0) if down else Color(1, 1, 1, 1)
