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
var _box: Sprite2D


func _ready() -> void:
	_t = phase_offset
	_box = Sprite2D.new()  # v0.63: subwoofer 16×20 dibujado
	_box.texture = load("res://assets/sprites/hazards/subwoofer.png")
	_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_box.centered = false
	_box.offset = Vector2(-8, -20)
	add_child(_box)


func _physics_process(delta: float) -> void:
	var before := fmod(_t, period)
	_t += delta
	var c := fmod(_t, period)
	if c > period - WARN:
		var k := 1.0 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.05))
		_box.scale = Vector2(k * 0.9 + 0.1, 1.0 + (k - 1.0) * 0.3)
		_box.modulate = Color(1.3, 1.1, 0.8)
	else:
		_box.scale = Vector2.ONE
		_box.modulate = Color.WHITE
	if c < before:
		var w: Area2D = QuakeWaveScene.instantiate()
		w.lifetime = life
		get_parent().add_child(w)
		w.global_position = global_position + Vector2(direction * 12, 0)
		w.setup(direction, speed)
