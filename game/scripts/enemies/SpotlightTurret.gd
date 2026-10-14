extends Area2D
## Spotlight Turret (v0.61) — foco fijo en el suelo. Se ilumina 0.4 s (aviso) y dispara
## un perdigón recto hacia el lado del jugador. Solo es vulnerable con la lente abierta.
## HP 2. Hoja propia v0.62: spotlight_turret.png, 3 cuadros 22×24 (cerrado / aviso / abierto).

const MetBeatShotScript := preload("res://scripts/enemies/MetBeatShot.gd")
const HP_MAX := 2
const CYCLE := 2.2
const WARN := 0.4
const OPEN := 0.8
const RANGE_X := 180.0
const RANGE_Y := 48.0

var hp := HP_MAX
var tint := Color(1.0, 0.85, 0.55)
var _t := 0.0
var _flash := 0.0
var _alive := true
var _fired := false
var _vis: Sprite2D
var _beam: ColorRect


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = true
	_t = fmod(position.x * 0.007, CYCLE)
	var shp := RectangleShape2D.new()
	shp.size = Vector2(14, 14)
	var col := CollisionShape2D.new()
	col.shape = shp
	col.position = Vector2(0, -7)
	add_child(col)
	_beam = ColorRect.new()
	_beam.size = Vector2(4, 80)
	_beam.position = Vector2(-2, -94)
	_beam.color = Color(1, 0.95, 0.6, 0.0)
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_beam)
	_vis = Sprite2D.new()
	_vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vis.texture = load("res://assets/sprites/enemies/spotlight_turret.png")
	_vis.hframes = 3
	_vis.position = Vector2(0, -12)
	add_child(_vis)
	_refresh()


func _open_state() -> int:
	## 0 cerrado, 1 aviso, 2 abierto
	var c := fmod(_t, CYCLE)
	var closed := CYCLE - WARN - OPEN
	if c < closed:
		return 0
	if c < closed + WARN:
		return 1
	return 2


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	var st := _open_state()
	if st == 2 and not _fired:
		_fired = true
		_shoot()
	elif st != 2:
		_fired = false
	_refresh()


func _refresh() -> void:
	var st := _open_state()
	_vis.frame = st
	var ps := get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	if not ps.is_empty():
		_vis.flip_h = (ps[0] as Node2D).global_position.x < global_position.x
	if _flash > 0.0:
		_vis.modulate = Color(2, 2, 2)
	else:
		_vis.modulate = Color.WHITE.lerp(tint, 0.2)
	_beam.color.a = 0.35 if st == 1 else (0.18 if st == 2 else 0.0)


func take_damage(amount: int) -> bool:
	if not _alive or _open_state() != 2:
		_flash = 0.06
		return false
	hp -= amount
	_flash = 0.12
	if AudioManager:
		AudioManager.play_sfx("hit")
	if hp <= 0:
		_alive = false
		queue_free()
	return true


func _shoot() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var ps := tree.get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p := ps[0] as Node2D
	var d := p.global_position - global_position
	if absf(d.x) > RANGE_X or absf(d.y) > RANGE_Y:
		return
	var shot: Area2D = MetBeatShotScript.new()
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(0, -9)
	shot.setup(1 if d.x >= 0.0 else -1)
