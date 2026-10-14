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
	# v0.66: opciones, HUD táctil y pausa.
	Engine.set_meta("title_seen", true)
	change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	for i in 40:
		await process_frame
	var opt = current_scene.get_node_or_null("OptionsPanel")
	if opt:
		opt.visible = true
		var ob = opt.find_child("OptDiffButton", true, false)
		if ob:
			ob.grab_focus()
	await _shot("options")
	change_scene_to_file("res://scenes/levels/Level01.tscn")
	for i in 90:
		await process_frame
	var tc = root.find_child("TouchControls", true, false)
	if tc and tc.has_method("set_show_touch_always"):
		tc.set_show_touch_always(true)
	await _shot("hud")
	var hud = root.find_child("HUD", true, false)
	if hud and hud.has_method("_toggle_pause"):
		hud._toggle_pause()
	await _shot("pause")
	paused = false
	gs.reset_progress()
	quit()


func _shot(n: String) -> void:
	for i in 30:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, n])
	print("CAPTURED ", n, " ", img.get_size())
