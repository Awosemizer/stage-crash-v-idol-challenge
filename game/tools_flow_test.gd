extends SceneTree
## v0.60 headless flow test: Title → personaje → selector → 8 etapas (jefe + arma) → fortaleza
## (Lobby → Archive → Shaft → Heart) → final → créditos → título, y guardar/continuar.
## usage: godot --headless --path game -s tools_flow_test.gd   (prints FLOW_PASS)

const SLOT := 2
var errors: PackedStringArray = []


func _goto(path: String) -> Node:
	change_scene_to_file(path)
	for i in 4:
		await process_frame
	return current_scene


func _expect_scene(path: String, why: String) -> void:
	for i in 4:
		await process_frame
	var cur := current_scene.scene_file_path if current_scene else "<none>"
	if cur != path:
		errors.append("%s: expected %s, got %s" % [why, path, cur])
	else:
		print("OK flow ", why, " → ", path.get_file())


func _initialize() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("FLOW_FAIL no GameState")
		quit(1)
		return
	gs.delete_slot(SLOT)
	gs.reset_progress()

	# Title → SaveSelect (new game) → CharacterSelect → BossSelect
	var title = await _goto("res://scenes/ui/TitleScreen.tscn")
	if title == null:
		errors.append("TitleScreen failed to load")
	gs.begin_new_game(SLOT)
	gs.select_teto()
	var bsel = await _goto("res://scenes/ui/CharacterSelect.tscn")
	await _goto("res://scenes/ui/BossSelect.tscn")

	var stages := [
		["res://scenes/levels/Level01.tscn", gs.BOSS_BEATFIRE, "beat_blaze"],
		["res://scenes/levels/LevelGlitchIce.tscn", gs.BOSS_GLITCH_ICE, "freeze_sample"],
		["res://scenes/levels/LevelBassquake.tscn", gs.BOSS_BASSQUAKE, "quake_drop"],
		["res://scenes/levels/LevelEchoWind.tscn", gs.BOSS_ECHO_WIND, "echo_gale"],
		["res://scenes/levels/LevelNeonVolt.tscn", gs.BOSS_NEON_VOLT, "neon_arc"],
		["res://scenes/levels/LevelMetronome.tscn", gs.BOSS_METRONOME, "tempo_spike"],
		["res://scenes/levels/LevelChorusBloom.tscn", gs.BOSS_CHORUS_BLOOM, "petal_chorus"],
		["res://scenes/levels/LevelStaticShadow.tscn", gs.BOSS_STATIC_SHADOW, "static_veil"],
	]
	for st in stages:
		var bs = current_scene
		if bs and bs.has_method("_on_boss_pressed"):
			bs._on_boss_pressed(str(st[1]))
			await _expect_scene(st[0], "select " + str(st[1]))
		else:
			await _goto(st[0])
		var lvl = current_scene
		if gs.is_core9_unlocked():
			errors.append("CORE-9 unlocked too early (before %s)" % st[1])
		lvl._on_boss_died()
		await process_frame
		if not gs.is_boss_defeated(st[1]):
			errors.append("%s not marked defeated" % st[1])
		if not gs.has_weapon_unlocked(st[2]):
			errors.append("%s weapon %s not unlocked" % [st[1], st[2]])
		if lvl.get_node_or_null("WinBanner") == null:
			errors.append("%s: no weapon-get banner" % st[1])
		lvl._return_to_boss_select()
		await _expect_scene("res://scenes/ui/BossSelect.tscn", "after " + str(st[1]))

	if not gs.is_core9_unlocked():
		errors.append("8 bosses beaten but CORE-9 still locked")
	# Selector → fortress hub (must not be a dead end)
	var sel = current_scene
	sel._on_boss_pressed("core9")
	await _expect_scene("res://scenes/ui/FortressComingSoon.tscn", "selector → fortaleza")
	var hub = current_scene
	var enter = hub.get_node_or_null("EnterButton") as Button
	if enter == null or enter.disabled or not enter.visible:
		errors.append("Fortress hub has no usable Enter button")
	hub._on_enter()
	await _expect_scene("res://scenes/levels/LevelFortressLobby.tscn", "hub → Lobby")
	var lobby = current_scene
	lobby._on_boss_died()
	await process_frame
	lobby._go_next()
	await _expect_scene("res://scenes/levels/LevelVoiceArchive.tscn", "Lobby → Archive")
	var arch = current_scene
	arch._seals_left = 0
	var pl = arch.get_node_or_null("Entities/Player")
	arch._on_exit(pl)
	await _expect_scene("res://scenes/levels/LevelCoreShaft.tscn", "Archive → Core Shaft")
	var shaft = current_scene
	shaft._on_boss_died()
	await process_frame
	shaft._go_next()
	await _expect_scene("res://scenes/levels/LevelHeartCore9.tscn", "Shaft → Heart")
	var heart = current_scene
	heart._on_boss_died()
	await process_frame
	heart._go_ending()
	await _expect_scene("res://scenes/ui/EndingScreen.tscn", "Heart → final")
	var ending = current_scene
	var teto_text := _all_text(ending)
	if "Teto" not in teto_text:
		errors.append("Ending (Teto) should name Teto")
	if not gs.is_boss_defeated(gs.BOSS_CORE9):
		errors.append("CORE-9 not marked defeated after ending")
	# Miku variant of the ending
	gs.select_miku()
	var ending_m = await _goto("res://scenes/ui/EndingScreen.tscn")
	var miku_text := _all_text(ending_m)
	if "Miku" not in miku_text or miku_text == teto_text:
		errors.append("Ending should have a Miku variant")
	gs.select_teto()
	ending_m._go_credits()
	await _expect_scene("res://scenes/ui/CreditsScreen.tscn", "final → créditos")
	var credits = current_scene
	var ctext := _all_text(credits)
	for bad in ["Prototipo", "prototipo", "Próximamente", "Coming soon", "demo"]:
		if bad in ctext:
			errors.append("Credits still say '%s'" % bad)
	credits._go_select()
	await _expect_scene("res://scenes/ui/TitleScreen.tscn", "créditos → título")

	# Save / continue
	var want_count: int = gs.defeated_boss_count()
	var want_weapons: int = gs.get_unlocked_weapons().size()
	if not gs.autosave():
		errors.append("autosave failed")
	gs.reset_progress()
	if gs.defeated_boss_count() != 0:
		errors.append("reset_progress did not clear")
	if not gs.begin_continue(SLOT):
		errors.append("continue (load slot) failed")
	if gs.defeated_boss_count() != want_count:
		errors.append("continue: bosses %d != %d" % [gs.defeated_boss_count(), want_count])
	if gs.get_unlocked_weapons().size() != want_weapons:
		errors.append("continue: weapons %d != %d" % [gs.get_unlocked_weapons().size(), want_weapons])
	if not gs.is_boss_defeated(gs.BOSS_CORE9) or not gs.is_core9_unlocked():
		errors.append("continue: fortress/CORE-9 state lost")
	var summary: Dictionary = gs.get_slot_summary(SLOT)
	print("slot summary ", summary)
	gs.delete_slot(SLOT)
	gs.reset_progress()

	if errors.is_empty():
		print("FLOW_PASS")
		quit(0)
	else:
		for e in errors:
			print("FLOW_FAIL: ", e)
		quit(1)


func _all_text(n: Node) -> String:
	var s := ""
	if n is Label:
		s += (n as Label).text + "\n"
	elif n is Button:
		s += (n as Button).text + "\n"
	for c in n.get_children():
		s += _all_text(c)
	if "_lines" in n:
		for l in n._lines:
			s += str(l) + "\n"
	if "CREDIT_LINES" in n.get_script().get_script_constant_map() if n.get_script() else false:
		for l in n.get_script().get_script_constant_map()["CREDIT_LINES"]:
			s += str(l) + "\n"
	return s
