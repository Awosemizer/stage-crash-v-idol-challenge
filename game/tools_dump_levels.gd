extends SceneTree
## v0.60 passability audit — dumps level geometry to JSON for scripts/audit_levels.py.
## usage: godot --headless --path game -s tools_dump_levels.gd -- OUT_DIR

const LEVELS := {
	"beatfire": "res://scenes/levels/Level01.tscn",
	"glitch_ice": "res://scenes/levels/LevelGlitchIce.tscn",
	"bassquake": "res://scenes/levels/LevelBassquake.tscn",
	"echo_wind": "res://scenes/levels/LevelEchoWind.tscn",
	"neon_volt": "res://scenes/levels/LevelNeonVolt.tscn",
	"metronome": "res://scenes/levels/LevelMetronome.tscn",
	"chorus_bloom": "res://scenes/levels/LevelChorusBloom.tscn",
	"static_shadow": "res://scenes/levels/LevelStaticShadow.tscn",
	"fortress_lobby": "res://scenes/levels/LevelFortressLobby.tscn",
	"voice_archive": "res://scenes/levels/LevelVoiceArchive.tscn",
	"core_shaft": "res://scenes/levels/LevelCoreShaft.tscn",
	"heart_core9": "res://scenes/levels/LevelHeartCore9.tscn",
}


func _rect_of(cs: CollisionShape2D) -> Dictionary:
	var sh := cs.shape
	if sh is RectangleShape2D:
		var t := cs.global_transform
		var sz: Vector2 = (sh as RectangleShape2D).size * t.get_scale().abs()
		var c := t.origin
		return {"x": c.x - sz.x * 0.5, "y": c.y - sz.y * 0.5, "w": sz.x, "h": sz.y}
	return {}


func _kind(n: Node) -> String:
	var s: Script = n.get_script()
	if s:
		return s.resource_path.get_file().get_basename()
	return n.get_class()


func _walk(n: Node, out: Dictionary) -> void:
	for c in n.get_children():
		_walk(c, out)
	if n is CollisionObject2D:
		var co := n as CollisionObject2D
		var kind := _kind(n)
		var is_player := n.is_in_group("player")
		var is_enemy := n.is_in_group("enemies") or n.is_in_group("bosses")
		for c in n.get_children():
			if c is CollisionShape2D and not (c as CollisionShape2D).disabled:
				var r := _rect_of(c)
				if r.is_empty():
					continue
				r["kind"] = kind
				r["name"] = str(n.name)
				if n is Area2D:
					if kind == "Checkpoint":
						continue
					r["area"] = true
					if "push_force" in n:
						r["push"] = [n.push_force.x, n.push_force.y]
					out["areas"].append(r)
				elif kind == "BreakableBlock" or kind == "VocalSeal":
					r["breakable"] = true
					out["solids"].append(r)
				elif not is_player and not is_enemy and (co.collision_layer & 1) != 0:
					r["one_way"] = (c as CollisionShape2D).one_way_collision
					if "pos_a" in n and "pos_b" in n:
						r["pos_a"] = [n.pos_a.x, n.pos_a.y]
						r["pos_b"] = [n.pos_b.x, n.pos_b.y]
					out["solids"].append(r)
	if _kind(n) == "Checkpoint":
		out["checkpoints"].append({"x": (n as Node2D).global_position.x, "y": (n as Node2D).global_position.y, "name": str(n.name)})
	if n.is_in_group("player") and n is Node2D:
		out["spawn"] = [(n as Node2D).global_position.x, (n as Node2D).global_position.y]
	if n.is_in_group("bosses") and n is Node2D:
		out["bosses"].append([(n as Node2D).global_position.x, (n as Node2D).global_position.y, str(n.name)])


func _initialize() -> void:
	var out_dir := "/tmp/stagecrash_audit"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var gs = root.get_node_or_null("GameState")
	for id in LEVELS:
		if gs and "_armor_owned" in gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
		var packed: PackedScene = load(LEVELS[id])
		var lvl := packed.instantiate()
		root.add_child(lvl)
		await process_frame
		await physics_frame
		await process_frame
		var out := {"id": id, "solids": [], "areas": [], "checkpoints": [], "spawn": null, "bosses": []}
		for k in ["LEVEL_RIGHT", "ARENA_LEFT", "ARENA_FLOOR_Y", "GATE_X"]:
			var v = lvl.get_script().get_script_constant_map().get(k)
			if v != null:
				out[k] = v
		_walk(lvl, out)
		var f := FileAccess.open(out_dir + "/" + id + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify(out, " "))
		f.close()
		print("DUMP ", id, " solids=", out["solids"].size(), " areas=", out["areas"].size(), " cks=", out["checkpoints"].size())
		lvl.queue_free()
		await process_frame
	print("DUMP_DONE")
	quit(0)
