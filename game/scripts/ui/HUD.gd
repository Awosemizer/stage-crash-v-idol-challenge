extends CanvasLayer
## In-game HUD — portrait, HP (28), energy tanks, weapon, armor stubs, pause.
## Layer 50 (below TouchControls @ 100). Spanish UI strings. 256×224 friendly.

signal pause_toggled(paused_now: bool)

const MAX_ENERGY_TANKS := 4
const ARMOR_SLOTS := 3
const SAFE := 4.0
const PORTRAIT_SIZE := 16.0
const HP_BAR_W := 56.0
const HP_BAR_H := 6.0
const TANK_SIZE := 6.0
const ARMOR_SIZE := 10.0
const PAUSE_BTN := 14.0

@export var weapon_name: String = "Buster"
@export var energy_tanks: int = 0  # 0–4 owned; icons empty until filled later
@export var portrait_color: Color = Color(0.2, 0.9, 0.95, 1.0)  # Miku cyan

var _root: Control
var _portrait: ColorRect
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_label: Label
var _weapon_label: Label
var _tank_icons: Array[ColorRect] = []
var _armor_slots: Array[ColorRect] = []
var _pause_btn: Panel
var _pause_panel: Panel
var _pause_title: Label
var _resume_btn: Button

var _player: Node = null
var _hp := 28
var _max_hp := 28
var _is_paused := false
var _weapon_ammo := -1
var _weapon_max_ammo := -1
var _weapon_id := "buster"
var _weakness_label: Label = null


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_portrait_from_state()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_hp_bar()
	_refresh_tanks()
	_refresh_weapon()
	_refresh_armor()
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_signal("armor_changed"):
		if not gs.armor_changed.is_connected(_on_armor_changed):
			gs.armor_changed.connect(_on_armor_changed)
	if gs != null and gs.has_signal("energy_tanks_changed"):
		if not gs.energy_tanks_changed.is_connected(_on_energy_tanks_changed):
			gs.energy_tanks_changed.connect(_on_energy_tanks_changed)
	sync_energy_tanks_from_state()
	call_deferred("refresh_weakness_hint")
	# Auto-bind if player already in tree
	call_deferred("_try_auto_bind")


func _apply_portrait_from_state() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("get_portrait_color"):
		portrait_color = gs.get_portrait_color()


func set_portrait_color(col: Color) -> void:
	portrait_color = col
	if _portrait:
		_portrait.color = col


func bind_player(player: Node) -> void:
	if _player != null and _player.has_signal("hp_changed"):
		if _player.hp_changed.is_connected(_on_player_hp_changed):
			_player.hp_changed.disconnect(_on_player_hp_changed)
	if _player != null and _player.has_signal("weapon_changed"):
		if _player.weapon_changed.is_connected(_on_player_weapon_changed):
			_player.weapon_changed.disconnect(_on_player_weapon_changed)
	_player = player
	if _player == null:
		return
	if "hp" in _player:
		_hp = int(_player.hp)
	if "max_hp" in _player:
		_max_hp = int(_player.max_hp)
	if _player.has_signal("hp_changed"):
		if not _player.hp_changed.is_connected(_on_player_hp_changed):
			_player.hp_changed.connect(_on_player_hp_changed)
	if _player.has_signal("weapon_changed"):
		if not _player.weapon_changed.is_connected(_on_player_weapon_changed):
			_player.weapon_changed.connect(_on_player_weapon_changed)
	# Sync current weapon if API present
	if _player.has_method("get_current_weapon"):
		var w: Dictionary = _player.get_current_weapon()
		_on_player_weapon_changed(
			str(w.get("id", "buster")),
			str(w.get("name", "Buster")),
			int(w.get("ammo", -1)),
			int(w.get("max_ammo", -1))
		)
	if _player.has_method("get_body_color"):
		set_portrait_color(_player.get_body_color())
	else:
		_apply_portrait_from_state()
		if _portrait:
			_portrait.color = portrait_color
	_refresh_hp_bar()


func set_weapon_name(name: String) -> void:
	weapon_name = name
	_refresh_weapon()


func set_weapon_ammo(ammo: int, max_ammo: int = -1) -> void:
	_weapon_ammo = ammo
	_weapon_max_ammo = max_ammo
	_refresh_weapon()


func set_energy_tanks(count: int) -> void:
	energy_tanks = clampi(count, 0, MAX_ENERGY_TANKS)
	_refresh_tanks()


func sync_energy_tanks_from_state() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("get_energy_tanks"):
		set_energy_tanks(int(gs.get_energy_tanks()))


func _on_energy_tanks_changed(count: int) -> void:
	set_energy_tanks(count)


func _try_auto_bind() -> void:
	if _player != null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group("player")
	if nodes.size() > 0:
		bind_player(nodes[0])


func _on_player_hp_changed(current: int, maximum: int) -> void:
	_hp = current
	_max_hp = maximum
	_refresh_hp_bar()


func _on_player_weapon_changed(weapon_id: String, display_name: String, ammo: int, max_ammo: int) -> void:
	_weapon_id = weapon_id
	weapon_name = display_name
	_weapon_ammo = ammo
	_weapon_max_ammo = max_ammo
	_refresh_weapon()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)

	# --- Top-left cluster ---
	_portrait = ColorRect.new()
	_portrait.name = "Portrait"
	_portrait.color = portrait_color
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portrait)

	_hp_bg = ColorRect.new()
	_hp_bg.name = "HpBg"
	_hp_bg.color = Color(0.08, 0.08, 0.12, 0.85)
	_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hp_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.name = "HpFill"
	_hp_fill.color = Color(0.25, 0.95, 0.55, 1.0)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bg.add_child(_hp_fill)

	_hp_label = Label.new()
	_hp_label.name = "HpLabel"
	_hp_label.add_theme_font_size_override("font_size", 7)
	_hp_label.modulate = Color(1, 1, 1, 0.9)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hp_label)

	_weapon_label = Label.new()
	_weapon_label.name = "WeaponLabel"
	_weapon_label.add_theme_font_size_override("font_size", 7)
	_weapon_label.modulate = Color(0.85, 0.95, 1.0, 0.95)
	_weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_weapon_label)

	_weakness_label = Label.new()
	_weakness_label.name = "WeaknessHint"
	_weakness_label.add_theme_font_size_override("font_size", 5)
	_weakness_label.modulate = Color(0.95, 0.7, 0.4, 0.9)
	_weakness_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weakness_label.visible = false
	_root.add_child(_weakness_label)

	for i in MAX_ENERGY_TANKS:
		var tank := ColorRect.new()
		tank.name = "EnergyTank%d" % i
		tank.color = Color(0.2, 0.22, 0.28, 0.7)  # empty stub
		tank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(tank)
		_tank_icons.append(tank)

	# --- Top-right: pause + armor ---
	_pause_btn = _make_panel(Color(0.2, 0.22, 0.3, 0.9))
	_pause_btn.name = "PauseBtn"
	_pause_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_btn.gui_input.connect(_on_pause_btn_gui_input)
	_root.add_child(_pause_btn)
	var pause_lbl := Label.new()
	pause_lbl.text = "II"
	pause_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_lbl.add_theme_font_size_override("font_size", 8)
	pause_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_btn.add_child(pause_lbl)

	for i in ARMOR_SLOTS:
		var slot := ColorRect.new()
		slot.name = "ArmorSlot%d" % i
		slot.color = Color(0.18, 0.2, 0.26, 0.75)  # empty rectangle stub
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Thin border feel via darker inset child
		var border := ColorRect.new()
		border.color = Color(0.45, 0.5, 0.6, 0.5)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(border)
		border.set_meta("is_border", true)
		_root.add_child(slot)
		_armor_slots.append(slot)

	# --- Pause panel (hidden) ---
	_pause_panel = _make_panel(Color(0.06, 0.05, 0.1, 0.92))
	_pause_panel.name = "PausePanel"
	_pause_panel.visible = false
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_pause_panel)

	_pause_title = Label.new()
	_pause_title.text = "PAUSA"
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_title.add_theme_font_size_override("font_size", 12)
	_pause_title.modulate = Color(0.4, 0.95, 1.0, 1.0)
	_pause_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_panel.add_child(_pause_title)

	_resume_btn = Button.new()
	_resume_btn.text = "Continuar"
	_resume_btn.add_theme_font_size_override("font_size", 8)
	_resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_btn.pressed.connect(_toggle_pause)
	_pause_panel.add_child(_resume_btn)


func _make_panel(col: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _layout() -> void:
	if _root == null:
		return
	var vp := get_viewport().get_visible_rect().size

	_portrait.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.position = Vector2(SAFE, SAFE)
	_portrait.color = portrait_color

	_hp_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bg.position = Vector2(SAFE + PORTRAIT_SIZE + 3.0, SAFE + 2.0)

	_hp_label.position = Vector2(_hp_bg.position.x, SAFE + HP_BAR_H + 3.0)
	_hp_label.size = Vector2(HP_BAR_W + 20.0, 10.0)

	_weapon_label.position = Vector2(SAFE, SAFE + PORTRAIT_SIZE + 2.0)
	_weapon_label.size = Vector2(120.0, 10.0)

	if _weakness_label:
		_weakness_label.position = Vector2(SAFE, SAFE + PORTRAIT_SIZE + 22.0)
		_weakness_label.size = Vector2(140.0, 10.0)

	var tank_y := SAFE + PORTRAIT_SIZE + 12.0
	for i in _tank_icons.size():
		_tank_icons[i].size = Vector2(TANK_SIZE, TANK_SIZE)
		_tank_icons[i].position = Vector2(SAFE + i * (TANK_SIZE + 2.0), tank_y)

	_pause_btn.size = Vector2(PAUSE_BTN, PAUSE_BTN)
	_pause_btn.position = Vector2(vp.x - PAUSE_BTN - SAFE, SAFE)

	var armor_y := SAFE + PAUSE_BTN + 3.0
	for i in _armor_slots.size():
		var slot := _armor_slots[i]
		slot.size = Vector2(ARMOR_SIZE, ARMOR_SIZE)
		slot.position = Vector2(vp.x - ARMOR_SIZE - SAFE - i * (ARMOR_SIZE + 2.0), armor_y)
		if slot.get_child_count() > 0:
			var border: ColorRect = slot.get_child(0)
			border.position = Vector2(1, 1)
			border.size = Vector2(ARMOR_SIZE - 2, ARMOR_SIZE - 2)
			border.color = Color(0.12, 0.14, 0.18, 0.9)

	# Centered pause panel
	var pw := 120.0
	var ph := 56.0
	_pause_panel.size = Vector2(pw, ph)
	_pause_panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	_pause_title.position = Vector2(0, 6)
	_pause_title.size = Vector2(pw, 16)
	_resume_btn.size = Vector2(72, 16)
	_resume_btn.position = Vector2((pw - 72) * 0.5, 30)

	_refresh_hp_bar()
	_refresh_armor()


func _refresh_hp_bar() -> void:
	if _hp_fill == null or _hp_bg == null:
		return
	var ratio := 0.0 if _max_hp <= 0 else clampf(float(_hp) / float(_max_hp), 0.0, 1.0)
	_hp_fill.position = Vector2(1, 1)
	_hp_fill.size = Vector2(maxf((_hp_bg.size.x - 2.0) * ratio, 0.0), maxf(_hp_bg.size.y - 2.0, 1.0))
	# Tint: green → yellow → red
	if ratio > 0.5:
		_hp_fill.color = Color(0.25, 0.95, 0.55, 1.0)
	elif ratio > 0.25:
		_hp_fill.color = Color(0.95, 0.85, 0.25, 1.0)
	else:
		_hp_fill.color = Color(0.95, 0.3, 0.35, 1.0)
	if _hp_label:
		_hp_label.text = "PV %d/%d" % [_hp, _max_hp]


func _refresh_tanks() -> void:
	for i in _tank_icons.size():
		# Empty outline style for now (0 filled); owned would be brighter later
		if i < energy_tanks:
			_tank_icons[i].color = Color(0.3, 0.85, 0.95, 0.95)
		else:
			_tank_icons[i].color = Color(0.2, 0.22, 0.28, 0.7)


func _refresh_weapon() -> void:
	if _weapon_label == null:
		return
	if _weapon_id != "buster" and _weapon_ammo >= 0:
		_weapon_label.text = "Arma: %s %d/%d" % [weapon_name, _weapon_ammo, maxi(_weapon_max_ammo, 0)]
		_weapon_label.modulate = Color(1.0, 0.7, 0.35, 0.95)
	else:
		_weapon_label.text = "Arma: %s" % weapon_name
		_weapon_label.modulate = Color(0.85, 0.95, 1.0, 0.95)


func _on_armor_changed(_set_id: String = "") -> void:
	_refresh_armor()
	refresh_weakness_hint()


func _refresh_armor() -> void:
	## Slots HUD: [0]=head [1]=torso [2]=legs — Stage Flight llena torso (índice 1).
	if _armor_slots.is_empty():
		return
	var mask: Array = [false, false, false]
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("get_armor_equipped_mask"):
		mask = gs.get_armor_equipped_mask("flight")
	var flight_col := Color(0.35, 0.85, 1.0, 0.95)
	if gs != null and gs.has_method("get_flight_armor_color"):
		flight_col = gs.get_flight_armor_color()
	for i in mini(_armor_slots.size(), 3):
		var filled := bool(mask[i]) if i < mask.size() else false
		var slot := _armor_slots[i]
		if filled:
			slot.color = flight_col.darkened(0.15)
			if slot.get_child_count() > 0:
				var inner: ColorRect = slot.get_child(0)
				inner.color = flight_col
		else:
			slot.color = Color(0.18, 0.2, 0.26, 0.75)
			if slot.get_child_count() > 0:
				var inner2: ColorRect = slot.get_child(0)
				inner2.color = Color(0.12, 0.14, 0.18, 0.9)


func get_armor_filled_count() -> int:
	## Para tests: cuántos slots HUD están "llenos".
	var n := 0
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("get_armor_owned_count"):
		return int(gs.get_armor_owned_count("flight"))
	return n


func _on_pause_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_toggle_pause()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if (event as InputEventMouseButton).pressed:
			_toggle_pause()
			get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	_pause_panel.visible = _is_paused
	var tree := get_tree()
	if tree:
		tree.paused = _is_paused
	print("HUD: pausa=%s" % str(_is_paused))
	pause_toggled.emit(_is_paused)


func _unhandled_input(event: InputEvent) -> void:
	# Escape / Start-like key stub (keyboard)
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE:
			_toggle_pause()
			get_viewport().set_input_as_handled()


func refresh_weakness_hint() -> void:
	## Encore Guard casco: muestra debilidad del jefe activo en escena.
	if _weakness_label == null:
		return
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	var has_helm := false
	if gs != null and gs.has_method("has_encore_head_equipped"):
		has_helm = bool(gs.has_encore_head_equipped())
	elif gs != null and gs.has_method("is_armor_equipped"):
		has_helm = bool(gs.is_armor_equipped("encore", "head"))
	if not has_helm:
		_weakness_label.visible = false
		_weakness_label.text = ""
		return
	var hint := _detect_boss_weakness()
	if hint == "":
		_weakness_label.text = "◆ Debilidad: —"
		_weakness_label.visible = true
	else:
		_weakness_label.text = "◆ Debilidad: %s" % hint
		_weakness_label.visible = true


func _detect_boss_weakness() -> String:
	var tree := get_tree()
	if tree == null:
		return ""
	var bosses := tree.get_nodes_in_group("bosses")
	if bosses.is_empty():
		return ""
	var b: Node = bosses[0]
	var map := {
		"weak_to_petal_chorus": "Petal Chorus",
		"weak_to_beat_blaze": "Beat Blaze",
		"weak_to_echo_gale": "Echo Gale",
		"weak_to_neon_arc": "Neon Arc",
		"weak_to_freeze_sample": "Freeze Sample",
		"weak_to_quake_drop": "Quake Drop",
		"weak_to_tempo_spike": "Tempo Spike",
		"weak_to_static_veil": "Static Veil",
	}
	for g in map.keys():
		if b.is_in_group(str(g)):
			return str(map[g])
	return ""
