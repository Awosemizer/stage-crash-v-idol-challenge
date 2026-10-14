extends Node2D
## Altavoz sísmico (Bassquake, v0.61): cada `period` s el cono vibra (aviso) y lanza una
## onda QuakeWave por el suelo. Se esquiva saltando; los catwalks quedan a salvo.

const QuakeWaveScene := preload("res://scenes/hazards/QuakeWave.tscn")
@export var period := 2.6
@export var phase_offset := 0.0
@export var direction := -1
@export var speed := 95.0
@export var life := 2.4
const WARN := 0.45

var _t := 0.0
var _box: ColorRect
var _cone: ColorRect


func _ready() -> void:
	_t = phase_offset
	_box = ColorRect.new()
	_box.size = Vector2(16, 20)
	_box.position = Vector2(-8, -20)
	_box.color = Color(0.18, 0.14, 0.12)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_cone = ColorRect.new()
	_cone.size = Vector2(8, 8)
	_cone.position = Vector2(-4, -15)
	_cone.color = Color(0.75, 0.45, 0.15)
	_cone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cone)


func _physics_process(delta: float) -> void:
	var before := fmod(_t, period)
	_t += delta
	var c := fmod(_t, period)
	if c > period - WARN:
		var k := 1.0 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.05))
		_cone.scale = Vector2(k, k)
		_cone.color = Color(1.0, 0.75, 0.25)
	else:
		_cone.scale = Vector2.ONE
		_cone.color = Color(0.75, 0.45, 0.15)
	if c < before:
		var w: Area2D = QuakeWaveScene.instantiate()
		w.lifetime = life
		get_parent().add_child(w)
		w.global_position = global_position + Vector2(direction * 12, 0)
		w.setup(direction, speed)
