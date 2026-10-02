extends CanvasLayer
## In-game HUD — portrait, HP (28), energy tanks, weapon, armor stubs, pause.
## Layer 50 (below TouchControls @ 100). Spanish UI strings.
## Layout uses SafeArea for phone landscape notches / bezels.

signal pause_toggled(paused_now: bool)

const _SafeArea := preload("res://scripts/ui/SafeArea.gd")

const MAX_ENERGY_TANKS := 4
const ARMOR_SLOTS := 3
const PORTRAIT_SIZE := 18.0
const HP_BAR_W := 72.0
const HP_BAR_H := 8.0
const TANK_SIZE := 7.0
const ARMOR_SIZE := 12.0
const PAUSE_BTN := 28.0
## Keep HUD cluster above touch stick / buttons (bottom ~90px reserved).
const TOUCH_RESERVE_BOTTOM := 90.0

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
var _quit_btn: Button

var _player: Node = null
var _hp := 28
var _max_hp := 28
var _is_paused := false
var _weapon_ammo := -1
var _weapon_max_ammo := -1
var _weapon_id := "buster"
var _weakness_label: Label = null
var _weapon_strip: HFlowContainer = null
var _weapon_strip_title: Label = null
var _weapon_strip_btns: Array = []
var _ammo_flash := 0.0
var _touch_size_btn: Button = null
var _touch_op_btn: Button = null
var _boss_hp_root: Control = null
var _boss_hp_bg: ColorRect = null
var _boss_hp_fill: ColorRect = null
var _boss_hp_label: Label = null
var _boss_bound: Node = null
var _boss_poll_t := 0.0


func _process(delta: float) -> void:
	if _ammo_flash > 0.0:
		_ammo_flash = maxf(_ammo_flash - delta, 0.0)
		_refresh_weapon()
	_boss_poll_t -= delta
	if _boss_poll_t <= 0.0:
		_boss_poll_t = 0.35
		_try_bind_boss()


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
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
	call_deferred("_try_bind_boss")


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
	if _weapon_id != "buster" and _weapon_ammo == 0:
		flash_ammo_empty()


func flash_ammo_empty() -> void:
	## Red blink when special weapon ammo is empty.
	_ammo_flash = 0.55
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
	if _weapon_id != "buster" and _weapon_ammo == 0:
		flash_ammo_empty()


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
	_hp_label.add_theme_font_size_override("font_size", 9)
	_hp_label.modulate = Color(1, 1, 1, 0.9)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hp_label)

	_weapon_label = Label.new()
	_weapon_label.name = "WeaponLabel"
	_weapon_label.add_theme_font_size_override("font_size", 9)
	_weapon_label.modulate = Color(0.85, 0.95, 1.0, 0.95)
	_weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_weapon_label)

	_weakness_label = Label.new()
	_weakness_label.name = "WeaknessHint"
	_weakness_label.add_theme_font_size_override("font_size", 7)
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
	pause_lbl.add_theme_font_size_override("font_size", 11)
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
	_pause_title.add_theme_font_size_override("font_size", 14)
	_pause_title.modulate = Color(0.4, 0.95, 1.0, 1.0)
	_pause_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_panel.add_child(_pause_title)

	_resume_btn = Button.new()
	_resume_btn.name = "ResumeButton"
	_resume_btn.text = "Continuar"
	_resume_btn.add_theme_font_size_override("font_size", 12)
	_resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_btn.pressed.connect(_toggle_pause)
	_pause_panel.add_child(_resume_btn)

	_quit_btn = Button.new()
	_quit_btn.name = "QuitButton"
	_quit_btn.text = "Salir al selector"
	_quit_btn.add_theme_font_size_override("font_size", 11)
	_quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_quit_btn.pressed.connect(_quit_to_boss_select)
	_pause_panel.add_child(_quit_btn)

	_weapon_strip_title = Label.new()
	_weapon_strip_title.name = "WeaponStripTitle"
	_weapon_strip_title.text = "Armas"
	_weapon_strip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_strip_title.add_theme_font_size_override("font_size", 10)
	_weapon_strip_title.modulate = Color(0.75, 0.9, 1.0, 0.95)
	_weapon_strip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_panel.add_child(_weapon_strip_title)

	_weapon_strip = HFlowContainer.new()
	_weapon_strip.name = "WeaponStrip"
	_weapon_strip.process_mode = Node.PROCESS_MODE_ALWAYS
	_weapon_strip.add_theme_constant_override("h_separation", 4)
	_weapon_strip.add_theme_constant_override("v_separation", 4)
	_pause_panel.add_child(_weapon_strip)

	_touch_size_btn = Button.new()
	_touch_size_btn.name = "TouchSizeBtn"
	_touch_size_btn.add_theme_font_size_override("font_size", 9)
	_touch_size_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_size_btn.focus_mode = Control.FOCUS_NONE
	_touch_size_btn.pressed.connect(_on_touch_size_pressed)
	_pause_panel.add_child(_touch_size_btn)

	_touch_op_btn = Button.new()
	_touch_op_btn.name = "TouchOpacityBtn"
	_touch_op_btn.add_theme_font_size_override("font_size", 9)
	_touch_op_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_op_btn.focus_mode = Control.FOCUS_NONE
	_touch_op_btn.pressed.connect(_on_touch_opacity_pressed)
	_pause_panel.add_child(_touch_op_btn)

	# --- Boss HP bar (top center, screen-space) ---
	_boss_hp_root = Control.new()
	_boss_hp_root.name = "BossHpRoot"
	_boss_hp_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hp_root.visible = false
	_root.add_child(_boss_hp_root)
	var boss_title := Label.new()
	boss_title.name = "BossHpTitle"
	boss_title.text = "JEFE"
	boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title.add_theme_font_size_override("font_size", 7)
	boss_title.modulate = Color(1.0, 0.75, 0.45, 0.95)
	boss_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hp_root.add_child(boss_title)
	_boss_hp_bg = ColorRect.new()
	_boss_hp_bg.name = "BossHpBg"
	_boss_hp_bg.color = Color(0.08, 0.06, 0.1, 0.9)
	_boss_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hp_root.add_child(_boss_hp_bg)
	_boss_hp_fill = ColorRect.new()
	_boss_hp_fill.name = "BossHpFill"
	_boss_hp_fill.color = Color(0.95, 0.4, 0.25, 1.0)
	_boss_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hp_bg.add_child(_boss_hp_fill)
	_boss_hp_label = Label.new()
	_boss_hp_label.name = "BossHpLabel"
	_boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp_label.add_theme_font_size_override("font_size", 7)
	_boss_hp_label.modulate = Color(1, 1, 1, 0.9)
	_boss_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_hp_root.add_child(_boss_hp_label)


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
	var area: Rect2 = _SafeArea.content_rect()
	var left: float = area.position.x
	var top: float = area.position.y
	var right: float = area.end.x
	var bottom: float = area.end.y
	var vp: Vector2 = get_viewport().get_visible_rect().size

	_portrait.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.position = Vector2(left, top)
	_portrait.color = portrait_color

	_hp_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bg.position = Vector2(left + PORTRAIT_SIZE + 3.0, top + 2.0)

	_hp_label.position = Vector2(_hp_bg.position.x, top + HP_BAR_H + 3.0)
	_hp_label.size = Vector2(HP_BAR_W + 20.0, 10.0)

	_weapon_label.position = Vector2(left, top + PORTRAIT_SIZE + 2.0)
	_weapon_label.size = Vector2(140.0, 10.0)

	if _weakness_label:
		_weakness_label.position = Vector2(left, top + PORTRAIT_SIZE + 22.0)
		_weakness_label.size = Vector2(160.0, 10.0)

	var tank_y: float = top + PORTRAIT_SIZE + 12.0
	for i in _tank_icons.size():
		_tank_icons[i].size = Vector2(TANK_SIZE, TANK_SIZE)
		_tank_icons[i].position = Vector2(left + i * (TANK_SIZE + 2.0), tank_y)

	_pause_btn.size = Vector2(PAUSE_BTN, PAUSE_BTN)
	_pause_btn.position = Vector2(right - PAUSE_BTN, top)

	var armor_y: float = top + PAUSE_BTN + 3.0
	for i in _armor_slots.size():
		var slot := _armor_slots[i]
		slot.size = Vector2(ARMOR_SIZE, ARMOR_SIZE)
		slot.position = Vector2(right - ARMOR_SIZE - i * (ARMOR_SIZE + 2.0), armor_y)
		if slot.get_child_count() > 0:
			var border: ColorRect = slot.get_child(0)
			border.position = Vector2(1, 1)
			border.size = Vector2(ARMOR_SIZE - 2, ARMOR_SIZE - 2)
			border.color = Color(0.12, 0.14, 0.18, 0.9)

	# Keep HUD top cluster out of thumb zone (touch stick/buttons bottom)
	# Weapon / tanks already under portrait; ensure they stay above mid-screen.
	var max_hud_bottom := maxf(vp.y - TOUCH_RESERVE_BOTTOM, top + 48.0)
	if _weapon_label and _weapon_label.position.y + 12.0 > max_hud_bottom:
		_weapon_label.position.y = max_hud_bottom - 24.0
	if _weakness_label and _weakness_label.position.y + 10.0 > max_hud_bottom:
		_weakness_label.position.y = max_hud_bottom - 12.0

	# Centered pause panel — large touch targets + weapon strip + touch opts
	var pw := minf(300.0, area.size.x * 0.94)
	var btn_h := maxf(_SafeArea.MIN_BTN_H, minf(_SafeArea.PREFERRED_BTN_H, 36.0))
	var opt_h := maxf(22.0, btn_h * 0.72)
	var strip_h := 56.0
	var ph := 28.0 + btn_h * 2.0 + opt_h + 28.0 + strip_h + 16.0
	ph = minf(ph, area.size.y * 0.94)
	_pause_panel.size = Vector2(pw, ph)
	_pause_panel.position = Vector2(
		area.position.x + (area.size.x - pw) * 0.5,
		area.position.y + (area.size.y - ph) * 0.5
	)
	_pause_title.position = Vector2(0, 6)
	_pause_title.size = Vector2(pw, 18)
	var bw := minf(160.0, pw - 24.0)
	_resume_btn.size = Vector2(bw, btn_h)
	_resume_btn.position = Vector2((pw - bw) * 0.5, 26)
	if _quit_btn:
		_quit_btn.size = Vector2(bw, btn_h)
		_quit_btn.position = Vector2((pw - bw) * 0.5, 26 + btn_h + 6.0)
		# Style quit/resume for visibility
		var rn := StyleBoxFlat.new()
		rn.bg_color = Color(0.12, 0.35, 0.28, 0.95)
		rn.set_border_width_all(2)
		rn.border_color = Color(0.4, 0.95, 0.65)
		rn.set_corner_radius_all(4)
		_resume_btn.add_theme_stylebox_override("normal", rn)
		var qn := StyleBoxFlat.new()
		qn.bg_color = Color(0.22, 0.12, 0.16, 0.95)
		qn.set_border_width_all(2)
		qn.border_color = Color(0.95, 0.45, 0.5)
		qn.set_corner_radius_all(4)
		_quit_btn.add_theme_stylebox_override("normal", qn)
	var opt_top := 26 + btn_h * 2.0 + 10.0
	var half_w := (bw - 6.0) * 0.5
	if _touch_size_btn:
		_touch_size_btn.size = Vector2(half_w, opt_h)
		_touch_size_btn.position = Vector2((pw - bw) * 0.5, opt_top)
		_refresh_touch_opt_labels()
		_SafeArea.style_button(_touch_size_btn, Color(0.14, 0.16, 0.24, 0.95), Color(0.55, 0.75, 0.95, 0.9), 3)
	if _touch_op_btn:
		_touch_op_btn.size = Vector2(half_w, opt_h)
		_touch_op_btn.position = Vector2((pw - bw) * 0.5 + half_w + 6.0, opt_top)
		_SafeArea.style_button(_touch_op_btn, Color(0.14, 0.16, 0.24, 0.95), Color(0.55, 0.75, 0.95, 0.9), 3)
	var strip_top := opt_top + opt_h + 8.0
	if _weapon_strip_title:
		_weapon_strip_title.position = Vector2(8, strip_top)
		_weapon_strip_title.size = Vector2(pw - 16.0, 14)
	if _weapon_strip:
		_weapon_strip.position = Vector2(10, strip_top + 16.0)
		_weapon_strip.size = Vector2(pw - 20.0, maxf(ph - (strip_top + 20.0), 36.0))

	# Boss HP — top center of safe area (above playfield, clear of pause)
	if _boss_hp_root:
		var bar_w := minf(160.0, area.size.x * 0.42)
		var bar_h := 8.0
		_boss_hp_root.position = Vector2(area.position.x + (area.size.x - bar_w) * 0.5, top)
		_boss_hp_root.size = Vector2(bar_w, 28.0)
		var title_n := _boss_hp_root.get_node_or_null("BossHpTitle") as Label
		if title_n:
			title_n.position = Vector2(0, 0)
			title_n.size = Vector2(bar_w, 10)
		if _boss_hp_bg:
			_boss_hp_bg.position = Vector2(0, 12)
			_boss_hp_bg.size = Vector2(bar_w, bar_h)
		if _boss_hp_label:
			_boss_hp_label.position = Vector2(0, 12 + bar_h)
			_boss_hp_label.size = Vector2(bar_w, 10)
		_refresh_boss_hp_bar()

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



func flash_energy_tanks() -> void:
	## Brief highlight when an E-Tank is collected (clarity on phone HUD).
	sync_energy_tanks_from_state()
	for tank in _tank_icons:
		if tank == null:
			continue
		tank.modulate = Color(1.8, 1.8, 1.2, 1.0)
	var tree := get_tree()
	if tree:
		tree.create_timer(0.45).timeout.connect(func () -> void:
			for tank2 in _tank_icons:
				if tank2:
					tank2.modulate = Color(1, 1, 1, 1)
		)


func _refresh_tanks() -> void:
	for i in _tank_icons.size():
		# Empty outline style for now (0 filled); owned would be brighter later
		if i < energy_tanks:
			_tank_icons[i].color = Color(0.25, 0.95, 1.0, 1.0)
		else:
			_tank_icons[i].color = Color(0.18, 0.2, 0.26, 0.55)


func _refresh_weapon() -> void:
	if _weapon_label == null:
		return
	if _weapon_id != "buster" and _weapon_ammo >= 0:
		_weapon_label.text = "Arma: %s %d/%d" % [weapon_name, _weapon_ammo, maxi(_weapon_max_ammo, 0)]
		if _weapon_ammo <= 0:
			# Empty ammo — flash red/white
			var pulse := 1.0 if _ammo_flash <= 0.0 else (0.55 + 0.45 * absf(sin(_ammo_flash * 22.0)))
			_weapon_label.modulate = Color(1.0, 0.25 + 0.2 * pulse, 0.25, pulse)
			if _ammo_flash <= 0.0:
				_weapon_label.modulate = Color(1.0, 0.35, 0.35, 0.95)
		else:
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



func _quit_to_boss_select() -> void:
	if _is_paused:
		_is_paused = false
		_pause_panel.visible = false
		var tree := get_tree()
		if tree:
			tree.paused = false
	if AudioManager:
		AudioManager.set_paused_duck(false)
		AudioManager.play_sfx("ui_confirm")
	var gs2 := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs2 != null and gs2.has_method("clear_all_stage_checkpoints"):
		gs2.clear_all_stage_checkpoints()
	get_tree().change_scene_to_file("res://scenes/ui/BossSelect.tscn")


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	_pause_panel.visible = _is_paused
	var tree := get_tree()
	if tree:
		tree.paused = _is_paused
	print("HUD: pausa=%s" % str(_is_paused))
	if _is_paused:
		_rebuild_weapon_strip()
		_layout()
	if AudioManager:
		AudioManager.set_paused_duck(_is_paused)
		if _is_paused:
			AudioManager.play_sfx("ui_confirm")
	pause_toggled.emit(_is_paused)


func _unhandled_input(event: InputEvent) -> void:
	# Escape / Start-like key stub (keyboard)
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE:
			_toggle_pause()
			get_viewport().set_input_as_handled()


func _rebuild_weapon_strip() -> void:
	## Tap-to-select weapon grid on pause (GDD). Works while tree.paused.
	if _weapon_strip == null:
		return
	for c in _weapon_strip.get_children():
		c.queue_free()
	_weapon_strip_btns.clear()
	var weapons: Array = []
	if _player != null and _player.has_method("get_owned_weapons"):
		weapons = _player.get_owned_weapons()
	if weapons.is_empty():
		# Fallback: show current HUD weapon only
		weapons = [{"id": _weapon_id, "name": weapon_name, "ammo": _weapon_ammo, "max_ammo": _weapon_max_ammo}]
	var cur_id := _weapon_id
	if _player != null and _player.has_method("get_weapon_id"):
		cur_id = str(_player.get_weapon_id())
	for w in weapons:
		var wid := str(w.get("id", ""))
		var wname := str(w.get("name", wid))
		var short := _weapon_short_name(wid, wname)
		var btn := Button.new()
		btn.name = "Wpn_%s" % wid
		btn.text = short
		btn.custom_minimum_size = Vector2(60, 30)
		btn.add_theme_font_size_override("font_size", 9)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.focus_mode = Control.FOCUS_NONE
		var selected := wid == cur_id
		var bg := Color(0.15, 0.45, 0.55, 0.95) if selected else Color(0.14, 0.16, 0.22, 0.95)
		var bd := Color(0.45, 0.95, 1.0) if selected else Color(0.55, 0.6, 0.7)
		_SafeArea.style_button(btn, bg, bd, 3)
		btn.pressed.connect(_on_weapon_strip_pressed.bind(wid))
		_weapon_strip.add_child(btn)
		_weapon_strip_btns.append(btn)


func _weapon_short_name(wid: String, full: String) -> String:
	match wid:
		"buster":
			return "Buster"
		"saber":
			return "Sable"
		"beat_blaze":
			return "Blaze"
		"echo_gale":
			return "Gale"
		"neon_arc":
			return "Neon"
		"freeze_sample":
			return "Freeze"
		"petal_chorus":
			return "Petal"
		"quake_drop":
			return "Quake"
		"tempo_spike":
			return "Tempo"
		"static_veil":
			return "Veil"
		_:
			return full if full.length() <= 8 else full.substr(0, 7)


func _on_weapon_strip_pressed(weapon_id: String) -> void:
	if _player != null and _player.has_method("select_weapon"):
		_player.select_weapon(weapon_id)
	elif _player != null and _player.has_method("cycle_weapon"):
		# Fallback: cycle until match (should not be needed)
		pass
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	# Refresh highlight without closing pause
	_rebuild_weapon_strip()
	# Sync label immediately
	if _player != null and _player.has_method("get_current_weapon"):
		var w: Dictionary = _player.get_current_weapon()
		_on_player_weapon_changed(
			str(w.get("id", "buster")),
			str(w.get("name", "Buster")),
			int(w.get("ammo", -1)),
			int(w.get("max_ammo", -1))
		)


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


func _refresh_touch_opt_labels() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	var sz := "M"
	var op := 0.5
	if gs != null:
		if "touch_btn_size" in gs:
			sz = str(gs.touch_btn_size)
		if "touch_opacity" in gs:
			op = float(gs.touch_opacity)
	if _touch_size_btn:
		_touch_size_btn.text = "Táctil %s" % sz
	if _touch_op_btn:
		_touch_op_btn.text = "Opac %d%%" % int(round(op * 100.0))


func _on_touch_size_pressed() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("cycle_touch_btn_size"):
		gs.cycle_touch_btn_size()
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	_refresh_touch_opt_labels()


func _on_touch_opacity_pressed() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("cycle_touch_opacity"):
		gs.cycle_touch_opacity()
	if AudioManager:
		AudioManager.play_sfx("ui_confirm")
	_refresh_touch_opt_labels()

func _try_bind_boss() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var bosses := tree.get_nodes_in_group("bosses")
	var alive: Node = null
	for b in bosses:
		if b == null or not is_instance_valid(b):
			continue
		if "hp" in b and int(b.hp) <= 0:
			continue
		alive = b
		break
	if alive == _boss_bound:
		return
	_unbind_boss()
	if alive == null:
		if _boss_hp_root:
			_boss_hp_root.visible = false
		return
	_boss_bound = alive
	if _boss_bound.has_signal("hp_changed"):
		if not _boss_bound.hp_changed.is_connected(_on_boss_hp_changed):
			_boss_bound.hp_changed.connect(_on_boss_hp_changed)
	if _boss_bound.has_signal("died"):
		if not _boss_bound.died.is_connected(_on_boss_died):
			_boss_bound.died.connect(_on_boss_died)
	var title_n := _boss_hp_root.get_node_or_null("BossHpTitle") as Label if _boss_hp_root else null
	var nm := str(_boss_bound.name)
	if "display_name" in _boss_bound:
		nm = str(_boss_bound.display_name)
	elif _boss_bound.has_method("get_boss_display_name"):
		nm = str(_boss_bound.get_boss_display_name())
	else:
		# Friendly names from node name
		nm = nm.replace("Man", " Man").replace("Unit", " Unit")
	if title_n:
		title_n.text = nm.to_upper()
	if _boss_hp_root:
		_boss_hp_root.visible = true
	var cur := int(_boss_bound.hp) if "hp" in _boss_bound else 28
	var mx := 28
	var mx_v = _boss_bound.get("HP_MAX")
	if mx_v != null:
		mx = int(mx_v)
	elif "max_hp" in _boss_bound:
		mx = int(_boss_bound.max_hp)
	_on_boss_hp_changed(cur, mx)


func _unbind_boss() -> void:
	if _boss_bound != null and is_instance_valid(_boss_bound):
		if _boss_bound.has_signal("hp_changed") and _boss_bound.hp_changed.is_connected(_on_boss_hp_changed):
			_boss_bound.hp_changed.disconnect(_on_boss_hp_changed)
		if _boss_bound.has_signal("died") and _boss_bound.died.is_connected(_on_boss_died):
			_boss_bound.died.disconnect(_on_boss_died)
	_boss_bound = null


func _on_boss_hp_changed(current: int, maximum: int) -> void:
	if _boss_hp_root == null:
		return
	_boss_hp_root.visible = maximum > 0 and current >= 0
	_boss_hp_root.set_meta("hp", current)
	_boss_hp_root.set_meta("max_hp", maximum)
	_refresh_boss_hp_bar()
	if current <= 0:
		# Keep visible briefly at 0 then hide on next poll
		pass


func _on_boss_died() -> void:
	if _boss_hp_root:
		_boss_hp_root.set_meta("hp", 0)
		_refresh_boss_hp_bar()
	# Delay hide so player sees empty bar
	var tree := get_tree()
	if tree:
		tree.create_timer(0.8).timeout.connect(func () -> void:
			_unbind_boss()
			if _boss_hp_root:
				_boss_hp_root.visible = false
		)


func _refresh_boss_hp_bar() -> void:
	if _boss_hp_bg == null or _boss_hp_fill == null:
		return
	var cur := int(_boss_hp_root.get_meta("hp", 0)) if _boss_hp_root else 0
	var mx := int(_boss_hp_root.get_meta("max_hp", 28)) if _boss_hp_root else 28
	var ratio := 0.0 if mx <= 0 else clampf(float(cur) / float(mx), 0.0, 1.0)
	_boss_hp_fill.position = Vector2(1, 1)
	_boss_hp_fill.size = Vector2(maxf((_boss_hp_bg.size.x - 2.0) * ratio, 0.0), maxf(_boss_hp_bg.size.y - 2.0, 1.0))
	if ratio > 0.5:
		_boss_hp_fill.color = Color(0.95, 0.45, 0.2, 1.0)
	elif ratio > 0.25:
		_boss_hp_fill.color = Color(0.95, 0.75, 0.2, 1.0)
	else:
		_boss_hp_fill.color = Color(0.95, 0.25, 0.3, 1.0)
	if _boss_hp_label:
		_boss_hp_label.text = "%d/%d" % [cur, mx]
