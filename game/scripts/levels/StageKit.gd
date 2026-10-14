extends RefCounted
## v0.61: helpers compartidos que usa gen_stage_courses.py para los tramos temáticos
## y los enemigos nuevos. Todo se crea por código (sin escenas nuevas).

const FireJetScript := preload("res://scripts/hazards/FireJet.gd")
const DropScript := preload("res://scripts/hazards/DropHazard.gd")
const QuakeEmitterScript := preload("res://scripts/hazards/QuakeEmitter.gd")
const DroneScript := preload("res://scripts/enemies/SpeakerDrone.gd")
const TurretScript := preload("res://scripts/enemies/SpotlightTurret.gd")


static func fire_jet(parent: Node, x: float, floor_y: float, period: float, phase: float, height := 40.0) -> void:
	var j := FireJetScript.new()
	j.name = "FireJet"
	j.period = period
	j.phase_offset = phase
	j.height = height
	j.position = Vector2(x, floor_y)
	parent.add_child(j)


static func drop(parent: Node, x: float, top_y: float, floor_y: float, period: float, phase: float, tex: String, tint: Color) -> void:
	var d := DropScript.new()
	d.name = "Drop"
	d.position = Vector2(x, top_y)
	d.top_y = top_y
	d.floor_y = floor_y
	d.period = period
	d.phase_offset = phase
	d.texture_path = tex
	d.tint = tint
	parent.add_child(d)


static func quake(parent: Node, x: float, floor_y: float, period: float, phase: float, dir: int) -> void:
	var q := QuakeEmitterScript.new()
	q.name = "QuakeSpeaker"
	q.position = Vector2(x, floor_y)
	q.period = period
	q.phase_offset = phase
	q.direction = dir
	parent.add_child(q)


static func drone(parent: Node, x: float, y: float, tint: Color) -> void:
	var e := DroneScript.new()
	e.name = "SpeakerDrone"
	e.tint = tint
	e.position = Vector2(x, y)
	parent.add_child(e)


static func turret(parent: Node, x: float, floor_y: float, tint: Color) -> void:
	var e := TurretScript.new()
	e.name = "SpotlightTurret"
	e.tint = tint
	e.position = Vector2(x, floor_y)
	parent.add_child(e)
