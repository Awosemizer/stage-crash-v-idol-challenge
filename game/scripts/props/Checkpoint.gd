class_name StageCheckpoint
extends Area2D
## Mid-stage checkpoint marker — clear cyan pillar + flag + "CK" label.
## On touch: updates player spawn + GameState per-stage checkpoint.

signal activated(stage_id: String, pos: Vector2)



@export var stage_id: String = ""
@export var marker_label: String = "CK"
@export var spawn_offset: Vector2 = Vector2(0, -20)

var _armed := true
var _active := false
var _pulse := 0.0
var _pillar: ColorRect
var _glow: ColorRect
var _flag: ColorRect
var _lbl: Label
var _done_lbl: Label


static func place(parent: Node, world_pos: Vector2, sid: String, label: String = "CK") -> Area2D:
	## world_pos = pillar base on floor top. Spawn = world_pos + spawn_offset.
	var node: Area2D = (load("res://scenes/props/Checkpoint.tscn") as PackedScene).instantiate()
	node.stage_id = sid
	node.marker_label = label
	node.position = world_pos
	parent.add_child(node)
	return node


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player
	monitoring = true
	monitorable = false
	add_to_group("checkpoints")
	_build_visuals()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	call_deferred("_sync_from_state")


func _build_visuals() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -20)
	add_child(col)

	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.size = Vector2(28, 48)
	_glow.position = Vector2(-14, -44)
	_glow.color = Color(0.25, 0.95, 1.0, 0.18)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	_pillar = ColorRect.new()
	_pillar.name = "Pillar"
	_pillar.size = Vector2(8, 36)
	_pillar.position = Vector2(-4, -36)
	_pillar.color = Color(0.2, 0.85, 0.95, 0.95)
	_pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pillar)

	_flag = ColorRect.new()
	_flag.name = "Flag"
	_flag.size = Vector2(14, 10)
	_flag.position = Vector2(4, -40)
	_flag.color = Color(0.35, 1.0, 0.95, 0.95)
	_flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flag)

	_lbl = Label.new()
	_lbl.name = "CkLabel"
	_lbl.text = marker_label
	_lbl.position = Vector2(-10, -54)
	_lbl.add_theme_font_size_override("font_size", 7)
	_lbl.modulate = Color(0.55, 1.0, 1.0, 0.95)
	_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lbl)

	_done_lbl = Label.new()
	_done_lbl.name = "DoneLabel"
	_done_lbl.text = "✓"
	_done_lbl.visible = false
	_done_lbl.position = Vector2(-4, -56)
	_done_lbl.add_theme_font_size_override("font_size", 8)
	_done_lbl.modulate = Color(0.4, 1.0, 0.55, 1.0)
	_done_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_done_lbl)


func _process(delta: float) -> void:
	_pulse += delta
	if _pillar == null:
		return
	if _active:
		_pillar.color = Color(0.35, 1.0, 0.55, 0.95)
		_flag.color = Color(0.45, 1.0, 0.6, 0.95)
		_glow.color = Color(0.3, 1.0, 0.5, 0.12 + 0.06 * absf(sin(_pulse * 3.0)))
	else:
		_pillar.color = Color(0.2, 0.85, 0.95, 0.85 + 0.1 * absf(sin(_pulse * 4.0)))
		_flag.position.y = -40.0 - 2.0 * absf(sin(_pulse * 3.5))
		_glow.color = Color(0.25, 0.95, 1.0, 0.14 + 0.1 * absf(sin(_pulse * 5.0)))


func _on_body_entered(body: Node) -> void:
	if not _armed or body == null or not body.is_in_group("player"):
		return
	activate(body)


func activate(player: Node = null) -> void:
	var first := not _active
	_active = true
	if _done_lbl:
		_done_lbl.visible = true
	if _lbl:
		_lbl.visible = false
	_apply_spawn(player)
	if first and AudioManager:
		AudioManager.play_sfx("pickup")
	if first:
		activated.emit(stage_id, _spawn_pos())
		print("Checkpoint: stage=%s pos=%s" % [stage_id, str(_spawn_pos())])


func _spawn_pos() -> Vector2:
	return global_position + spawn_offset


func _apply_spawn(player: Node = null) -> void:
	var pos := _spawn_pos()
	var p := player
	if p == null:
		var tree := get_tree()
		if tree:
			p = tree.get_first_node_in_group("player")
	if p != null and p.has_method("set_spawn_pos"):
		p.set_spawn_pos(pos)
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs != null and gs.has_method("set_stage_checkpoint"):
		gs.set_stage_checkpoint(pos, stage_id)


func _sync_from_state() -> void:
	var gs := get_tree().root.get_node_or_null("GameState") if get_tree() else null
	if gs == null or not gs.has_method("get_stage_checkpoint"):
		return
	var saved: Vector2 = gs.get_stage_checkpoint(stage_id)
	if saved == Vector2.ZERO:
		return
	if saved.x + 8.0 >= global_position.x:
		_active = true
		if _done_lbl:
			_done_lbl.visible = true
		if _lbl:
			_lbl.visible = false
