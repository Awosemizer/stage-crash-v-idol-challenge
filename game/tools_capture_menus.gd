extends SceneTree
## v0.64: captura real de menús (requiere display; usar xvfb-run). usage:
## xvfb-run -a godot --path game --rendering-driver opengl3 -s tools_capture_menus.gd -- OUT_DIR
var shots := [
	["res://scenes/ui/TitleScreen.tscn", "title_press", false],
	["res://scenes/ui/TitleScreen.tscn", "title", true],
	["res://scenes/ui/CharacterSelect.tscn", "charselect", false],
	["res://scenes/ui/BossSelect.tscn", "bossselect", false],
]
var out := "/tmp/menus"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _run() -> void:
	var gs = root.get_node("GameState")
	gs.active_slot = -1
	gs.select_miku()
	gs.mark_boss_defeated("beatfire")
	gs.mark_boss_defeated("bassquake")
	gs.unlock_weapon("beat_blaze")
	for s in shots:
		Engine.set_meta("title_seen", s[2])
		change_scene_to_file(s[0])
		for i in 60:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, s[1]])
		print("CAPTURED ", s[1], " ", img.get_size())
	gs.reset_progress()
	quit()
