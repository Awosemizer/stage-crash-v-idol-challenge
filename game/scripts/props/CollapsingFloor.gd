extends AnimatableBody2D
## Plataforma que colapsa tras pisarla (temblor / Bassquake).
## Tras caer se regenera tras respawn_time.

@export var warn_time := 0.55
@export var fall_time := 0.85
@export var respawn_time := 2.4
@export var size := Vector2(48, 12)

enum Phase { IDLE, WARN, FALL, GONE }

var _phase: Phase = Phase.IDLE
var _timer := 0.0
var _base_pos := Vector2.ZERO
var _player_on := false

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("collapsing_floors")
	collision_layer = 1
	collision_mask = 0
	_base_pos = position
	_apply_size()
	set_physics_process(true)


func configure(pos: Vector2, sz: Vector2 = Vector2(48, 12), warn: float = 0.55, fall: float = 0.85, respawn: float = 2.4) -> void:
	position = pos
	_base_pos = pos
	size = sz
	warn_time = warn
	fall_time = fall
	respawn_time = respawn
	if is_node_ready():
		_apply_size()


func _apply_size() -> void:
	if visual:
		visual.size = size
		visual.position = -size * 0.5
		visual.color = Color(0.45, 0.32, 0.18, 1.0)
	if collision:
		var shape := collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision.shape = shape
		shape.size = size


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.IDLE:
			_check_player_on()
			if _player_on:
				_phase = Phase.WARN
				_timer = warn_time
		Phase.WARN:
			_timer -= delta
			if visual:
				var pulse := 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.03))
				visual.color = Color(1.0, 0.78, 0.22, pulse)
				position.x = _base_pos.x + sin(Time.get_ticks_msec() * 0.04) * 1.5
			if _timer <= 0.0:
				_phase = Phase.FALL
				_timer = fall_time
				if collision:
					collision.disabled = true
		Phase.FALL:
			_timer -= delta
			position.y += 180.0 * delta
			if visual:
				visual.color.a = clampf(_timer / maxf(fall_time, 0.01), 0.0, 1.0)
			if _timer <= 0.0:
				_phase = Phase.GONE
				_timer = respawn_time
				visible = false
		Phase.GONE:
			_timer -= delta
			if _timer <= 0.0:
				_reset()


func _check_player_on() -> void:
	_player_on = false
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0] as Node2D
	if p == null:
		return
	# Player standing roughly on top of this platform
	var top_y := global_position.y - size.y * 0.5
	var half_w := size.x * 0.5 + 4.0
	if absf(p.global_position.x - global_position.x) <= half_w:
		if p.global_position.y >= top_y - 6.0 and p.global_position.y <= top_y + 14.0:
			if p is CharacterBody2D and (p as CharacterBody2D).is_on_floor():
				_player_on = true


func _reset() -> void:
	_phase = Phase.IDLE
	_player_on = false
	position = _base_pos
	visible = true
	if collision:
		collision.disabled = false
	if visual:
		visual.color = Color(0.45, 0.32, 0.18, 1.0)
		visual.color.a = 1.0
