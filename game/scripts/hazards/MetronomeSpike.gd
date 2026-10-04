extends Area2D
## Púa de metrónomo — se extiende/retrae a intervalos fijos (fábrica de relojes).
## Solo daña cuando está extendida (fase "on").

@export var damage := 4
@export var period := 1.0  ## ciclo completo extend+retract
@export var on_ratio := 0.45  ## fracción del ciclo extendida
@export var phase_offset := 0.0
@export var telegraph_ratio := 0.15  ## legado; el aviso real es WARN_SEC
const WARN_SEC := 0.28

var _t := 0.0
var _extended := false
var _hurt_cd := 0.0

@onready var visual: Polygon2D = $Polygon2D
@onready var spike_sprite: Sprite2D = $SpikeSprite
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
	var off := p - on_end
	var lead := minf(WARN_SEC, maxf(off - 0.06, 0.0))
	var telegraph_start := p - lead
	var want_on := cycle < on_end
	var turned_on := want_on and not _extended
	_extended = want_on
	_refresh_state(lead > 0.05 and cycle >= telegraph_start and not want_on)
	if _extended and (turned_on or _hurt_cd <= 0.0):
		_hurt_overlaps()


func _refresh_state(warning: bool = false) -> void:
	if visual:
		visual.visible = false
	if spike_sprite:
		spike_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _extended:
			spike_sprite.modulate = Color(1, 1, 1, 1)
			spike_sprite.scale = Vector2(0.5, 0.5)
			spike_sprite.position = Vector2.ZERO
		elif warning:
			spike_sprite.modulate = Color(1.35, 1.05, 0.45, 1)
			spike_sprite.scale = Vector2(0.5, 0.31)
			spike_sprite.position = Vector2(0, 3)
		else:
			spike_sprite.modulate = Color(0.75, 0.75, 0.8, 0.65)
			spike_sprite.scale = Vector2(0.5, 0.18)
			spike_sprite.position = Vector2(0, 5)
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
