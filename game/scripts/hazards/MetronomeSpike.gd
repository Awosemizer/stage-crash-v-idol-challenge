extends Area2D
## Púa de metrónomo — se extiende/retrae a intervalos fijos (fábrica de relojes).
## Solo daña cuando está extendida (fase "on").

@export var damage := 4
@export var period := 1.0  ## ciclo completo extend+retract
@export var on_ratio := 0.45  ## fracción del ciclo extendida
@export var phase_offset := 0.0
@export var telegraph_ratio := 0.15  ## fracción previa al extend (aviso)

var _t := 0.0
var _extended := false
var _hurt_cd := 0.0

@onready var visual: Polygon2D = $Polygon2D
@onready var warn: ColorRect = $Warn
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("metronome_spikes")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_t = phase_offset
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_refresh_state()


func _physics_process(delta: float) -> void:
	_t += delta
	_hurt_cd = maxf(_hurt_cd - delta, 0.0)
	var p := maxf(period, 0.05)
	var cycle := fmod(_t, p)
	var on_end := p * on_ratio
	var telegraph_start := p - p * telegraph_ratio
	# If telegraph wraps before on: treat end-of-cycle as warn when next beat is near
	var want_on := cycle < on_end
	var turned_on := want_on and not _extended
	_extended = want_on
	_refresh_state(cycle >= telegraph_start and not want_on)
	if _extended and (turned_on or _hurt_cd <= 0.0):
		_hurt_overlaps()


func _refresh_state(warning: bool = false) -> void:
	if visual:
		if _extended:
			visual.color = Color(0.9, 0.25, 0.3, 1.0)
			visual.scale = Vector2(1.0, 1.0)
			visual.position = Vector2.ZERO
		else:
			visual.color = Color(0.45, 0.4, 0.5, 0.55)
			visual.scale = Vector2(1.0, 0.35)
			visual.position = Vector2(0, 5)
	if collision:
		collision.disabled = not _extended
	if warn:
		warn.visible = warning and not _extended
		if warn.visible:
			warn.color = Color(0.95, 0.85, 0.3, 0.35 + 0.25 * absf(sin(Time.get_ticks_msec() * 0.02)))


func is_extended() -> bool:
	return _extended


func _on_body_entered(body: Node) -> void:
	if _extended:
		_hurt(body)


func _hurt_overlaps() -> void:
	for b in get_overlapping_bodies():
		_hurt(b)


func _hurt(body: Node) -> void:
	if not _extended:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hurt_cd = 0.18
