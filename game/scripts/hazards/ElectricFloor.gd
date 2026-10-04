extends Area2D
## Piso eléctrico — late al tempo (ON/OFF). Club synth Neon Volt.
## Solo daña cuando está activo (fase "on").

@export var damage := 3
@export var period := 1.2  ## ciclo completo ON+OFF en segundos
@export var on_ratio := 0.45  ## fracción del ciclo activa
@export var phase_offset := 0.0  ## desfase para patrones
const WARN_SEC := 0.28  ## ámbar antes de la descarga (toque)

var _t := 0.0
var _active := false
var _warning := false
var _hurt_cd := 0.0

@onready var visual: ColorRect = $Visual
@onready var spark: Label = $Spark
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("hazards")
	add_to_group("electric_floors")
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
	var psec := maxf(period, 0.05)
	var cycle := fmod(_t, psec)
	var want_on := cycle < psec * on_ratio
	var off := psec * (1.0 - on_ratio)
	var lead := minf(WARN_SEC, maxf(off - 0.06, 0.0))
	var warning := (not want_on) and cycle >= psec - lead and lead > 0.05
	var turned_on := want_on and not _active
	_active = want_on
	_warning = warning
	_refresh_state()
	if _active and (turned_on or _hurt_cd <= 0.0):
		_hurt_overlaps()


func _refresh_state() -> void:
	if visual:
		if _active:
			visual.color = Color(0.95, 0.95, 0.25, 0.55 + 0.35 * absf(sin(Time.get_ticks_msec() * 0.02)))
		elif _warning:
			var pulse := 0.45 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.018))
			visual.color = Color(1.0, 0.78, 0.2, pulse)
		else:
			visual.color = Color(0.25, 0.2, 0.35, 0.22)
	if spark:
		# El pulso ámbar basta. El texto ⚡⚡ / ! no se muestra.
		spark.visible = false
		if _warning and not _active:
			spark.text = "!"
		else:
			spark.text = "⚡⚡"
	ArtKit.dress_hazard(visual, "res://assets/sprites/tiles/hazard_electric.png")


func is_electrified() -> bool:
	return _active


func _on_body_entered(body: Node) -> void:
	if _active:
		_hurt(body)


func _hurt_overlaps() -> void:
	for b in get_overlapping_bodies():
		_hurt(b)


func _hurt(body: Node) -> void:
	if not _active:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("is_invulnerable") and body.is_invulnerable():
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hurt_cd = 0.15
