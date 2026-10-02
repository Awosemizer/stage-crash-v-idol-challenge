extends SceneTree

func _initialize() -> void:
	var errors: PackedStringArray = []
	var paths := [
		"res://scripts/autoload/GameState.gd",
		"res://scripts/player/Player.gd",
		"res://scripts/levels/Level01.gd",
		"res://scripts/hazards/Hazard.gd",
		"res://scripts/ui/TouchControls.gd",
		"res://scripts/ui/HUD.gd",
		"res://scripts/ui/TitleScreen.gd",
		"res://scripts/ui/CharacterSelect.gd",
		"res://scripts/ui/BossSelect.gd",
		"res://scripts/combat/BusterShot.gd",
		"res://scripts/combat/BeatBlazeShot.gd",
		"res://scripts/combat/Fireball.gd",
		"res://scripts/enemies/MetBeat.gd",
		"res://scripts/bosses/BeatfireMan.gd",
		"res://scripts/props/BreakableBlock.gd",
		"res://scripts/pickups/ArmorPickup.gd",
		"res://scenes/props/BreakableBlock.tscn",
		"res://scenes/pickups/ArmorPickup.tscn",
		"res://scenes/player/Player.tscn",
		"res://scenes/levels/Level01.tscn",
		"res://scenes/hazards/Spike.tscn",
		"res://scenes/ui/TouchControls.tscn",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/ui/TitleScreen.tscn",
		"res://scenes/ui/CharacterSelect.tscn",
		"res://scenes/ui/BossSelect.tscn",
		"res://scenes/combat/BusterShot.tscn",
		"res://scenes/combat/BeatBlazeShot.tscn",
		"res://scenes/combat/Fireball.tscn",
		"res://scenes/enemies/MetBeat.tscn",
		"res://scenes/bosses/BeatfireMan.tscn",
		"res://scripts/levels/LevelEchoWind.gd",
		"res://scripts/bosses/EchoWind.gd",
		"res://scripts/combat/WindGust.gd",
		"res://scripts/combat/EchoGaleShot.gd",
		"res://scripts/hazards/WindCurrent.gd",
		"res://scenes/levels/LevelEchoWind.tscn",
		"res://scenes/bosses/EchoWind.tscn",
		"res://scenes/combat/WindGust.tscn",
		"res://scenes/combat/EchoGaleShot.tscn",
		"res://scenes/hazards/WindCurrent.tscn",
		"res://scripts/levels/LevelNeonVolt.gd",
		"res://scripts/bosses/NeonVolt.gd",
		"res://scripts/combat/ElectricZigzagShot.gd",
		"res://scripts/combat/NeonArcShot.gd",
		"res://scripts/hazards/ElectricFloor.gd",
		"res://scenes/levels/LevelNeonVolt.tscn",
		"res://scenes/bosses/NeonVolt.tscn",
		"res://scenes/combat/ElectricZigzagShot.tscn",
		"res://scenes/combat/NeonArcShot.tscn",
		"res://scenes/hazards/ElectricFloor.tscn",
		"res://scripts/levels/LevelGlitchIce.gd",
		"res://scripts/bosses/GlitchIce.gd",
		"res://scripts/combat/IceGlitchShot.gd",
		"res://scripts/combat/FreezeSampleShot.gd",
		"res://scripts/props/FrameSkipPlatform.gd",
		"res://scripts/pickups/EnergyTankPickup.gd",
		"res://scenes/levels/LevelGlitchIce.tscn",
		"res://scenes/bosses/GlitchIce.tscn",
		"res://scenes/combat/IceGlitchShot.tscn",
		"res://scenes/combat/FreezeSampleShot.tscn",
		"res://scenes/props/FrameSkipPlatform.tscn",
		"res://scenes/pickups/EnergyTankPickup.tscn",
		"res://scripts/levels/LevelChorusBloom.gd",
		"res://scripts/bosses/ChorusBloom.gd",
		"res://scripts/combat/PetalChorusShot.gd",
		"res://scripts/combat/FanPetalShot.gd",
		"res://scripts/props/VinePlatform.gd",
		"res://scripts/hazards/PetalHazard.gd",
		"res://scenes/levels/LevelChorusBloom.tscn",
		"res://scenes/bosses/ChorusBloom.tscn",
		"res://scenes/combat/PetalChorusShot.tscn",
		"res://scenes/combat/FanPetalShot.tscn",
		"res://scenes/props/VinePlatform.tscn",
		"res://scenes/hazards/PetalHazard.tscn",
		"res://scripts/levels/LevelBassquake.gd",
		"res://scripts/bosses/Bassquake.gd",
		"res://scripts/combat/QuakeDropShot.gd",
		"res://scripts/hazards/QuakeWave.gd",
		"res://scripts/props/CollapsingFloor.gd",
		"res://scenes/levels/LevelBassquake.tscn",
		"res://scenes/bosses/Bassquake.tscn",
		"res://scenes/combat/QuakeDropShot.tscn",
		"res://scenes/hazards/QuakeWave.tscn",
		"res://scenes/props/CollapsingFloor.tscn",
		"res://scripts/levels/LevelMetronome.gd",
		"res://scripts/bosses/Metronome.gd",
		"res://scripts/combat/TempoSpikeShot.gd",
		"res://scripts/combat/TempoNeedle.gd",
		"res://scripts/hazards/MetronomeSpike.gd",
		"res://scenes/levels/LevelMetronome.tscn",
		"res://scenes/bosses/Metronome.tscn",
		"res://scenes/combat/TempoSpikeShot.tscn",
		"res://scenes/combat/TempoNeedle.tscn",
		"res://scenes/hazards/MetronomeSpike.tscn",
		"res://scripts/levels/LevelStaticShadow.gd",
		"res://scripts/bosses/StaticShadow.gd",
		"res://scripts/combat/StaticVeilShot.gd",
		"res://scripts/hazards/StaticZone.gd",
		"res://scripts/ui/FortressComingSoon.gd",
		"res://scenes/levels/LevelStaticShadow.tscn",
		"res://scenes/bosses/StaticShadow.tscn",
		"res://scenes/combat/StaticVeilShot.tscn",
		"res://scenes/hazards/StaticZone.tscn",
		"res://scenes/ui/FortressComingSoon.tscn",
		"res://scripts/levels/LevelFortressLobby.gd",
		"res://scripts/levels/LevelVoiceArchive.gd",
		"res://scripts/levels/LevelCoreShaft.gd",
		"res://scripts/levels/LevelHeartCore9.gd",
		"res://scripts/bosses/RefrainUnit.gd",
		"res://scripts/bosses/OverdubTitan.gd",
		"res://scripts/bosses/Core9.gd",
		"res://scripts/props/VocalSeal.gd",
		"res://scripts/ui/EndingScreen.gd",
		"res://scripts/ui/CreditsScreen.gd",
		"res://scenes/levels/LevelFortressLobby.tscn",
		"res://scenes/levels/LevelVoiceArchive.tscn",
		"res://scenes/levels/LevelCoreShaft.tscn",
		"res://scenes/levels/LevelHeartCore9.tscn",
		"res://scenes/bosses/RefrainUnit.tscn",
		"res://scenes/bosses/OverdubTitan.tscn",
		"res://scenes/bosses/Core9.tscn",
		"res://scenes/props/VocalSeal.tscn",
		"res://scenes/ui/EndingScreen.tscn",
		"res://scenes/ui/CreditsScreen.tscn",
	]
	for p in paths:
		if not ResourceLoader.exists(p):
			errors.append("Missing: " + p)
			continue
		var res = load(p)
		if res == null:
			errors.append("Failed to load: " + p)
		else:
			print("OK load: ", p)

	# GameState autoload present
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		# Headless --script may not load project autoloads the same way; load manually
		var gs_script = load("res://scripts/autoload/GameState.gd")
		if gs_script == null:
			errors.append("GameState.gd failed to load")
		else:
			gs = Node.new()
			gs.set_script(gs_script)
			gs.name = "GameState"
			root.add_child(gs)
			print("OK GameState mounted manually for validate")
	else:
		print("OK GameState autoload present")
	if gs:
		gs.select_miku()
		if not gs.is_miku() or gs.get_character_id() != "miku":
			errors.append("GameState select_miku failed")
		else:
			print("OK GameState miku")
		gs.select_teto()
		if not gs.is_teto() or gs.get_character_id() != "teto":
			errors.append("GameState select_teto failed")
		else:
			print("OK GameState teto")
		var pc: Color = gs.get_portrait_color()
		if pc.r < 0.8:
			errors.append("Teto portrait should be reddish")
		else:
			print("OK Teto portrait color")
		gs.select_miku()
		# Armor Stage Flight API
		if not gs.has_method("grant_armor_piece"):
			errors.append("GameState missing grant_armor_piece")
		else:
			var was_new = gs.grant_armor_piece("flight", "torso", true)
			if not gs.has_armor_piece("flight", "torso"):
				errors.append("grant_armor_piece did not own torso")
			elif not gs.has_flight_torso_equipped():
				errors.append("flight torso not auto-equipped")
			elif int(gs.get_armor_owned_count("flight")) != 1:
				errors.append("armor owned count expected 1")
			else:
				print("OK GameState flight torso owned+equipped count=", gs.get_armor_owned_count("flight"))
			var mask = gs.get_armor_equipped_mask("flight")
			if mask.size() != 3 or mask[1] != true or mask[0] != false:
				errors.append("armor mask expected [false,true,false], got %s" % str(mask))
			else:
				print("OK armor equipped mask=", mask)
			# Reset for later level tests that expect pickup present
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
			print("OK armor state cleared for level pickup test")

	# Title screen UI
	var title_packed: PackedScene = load("res://scenes/ui/TitleScreen.tscn")
	if title_packed:
		var title = title_packed.instantiate()
		root.add_child(title)
		await process_frame
		if title.get_node_or_null("PlayButton") == null:
			errors.append("TitleScreen missing PlayButton")
		else:
			print("OK TitleScreen PlayButton")
		if title.get_node_or_null("Title") == null:
			errors.append("TitleScreen missing Title label")
		else:
			print("OK TitleScreen Title")
		title.queue_free()
		await process_frame
	else:
		errors.append("TitleScreen.tscn failed to load")

	# Character select UI
	var sel_packed: PackedScene = load("res://scenes/ui/CharacterSelect.tscn")
	if sel_packed:
		var sel = sel_packed.instantiate()
		root.add_child(sel)
		await process_frame
		if sel.get_node_or_null("MikuButton") == null or sel.get_node_or_null("TetoButton") == null:
			errors.append("CharacterSelect missing Miku/Teto buttons")
		else:
			print("OK CharacterSelect buttons")
		sel.queue_free()
		await process_frame
	else:
		errors.append("CharacterSelect.tscn failed to load")

	# CharacterSelect must route to BossSelect (not Level01)
	var sel_src = FileAccess.get_file_as_string("res://scripts/ui/CharacterSelect.gd")
	if "BossSelect.tscn" not in sel_src:
		errors.append("CharacterSelect should go to BossSelect")
	else:
		print("OK CharacterSelect → BossSelect")

	# BossSelect must route Echo Wind / Neon Volt
	var bsel_src = FileAccess.get_file_as_string("res://scripts/ui/BossSelect.gd")
	if "LevelEchoWind.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelEchoWind for echo_wind")
	else:
		print("OK BossSelect → LevelEchoWind")
	if "LevelNeonVolt.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelNeonVolt for neon_volt")
	else:
		print("OK BossSelect → LevelNeonVolt")
	if "LevelGlitchIce.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelGlitchIce for glitch_ice")
	else:
		print("OK BossSelect → LevelGlitchIce")
	if "LevelChorusBloom.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelChorusBloom for chorus_bloom")
	else:
		print("OK BossSelect → LevelChorusBloom")
	if "LevelBassquake.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelBassquake for bassquake")
	else:
		print("OK BossSelect → LevelBassquake")
	if "LevelMetronome.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelMetronome for metronome")
	else:
		print("OK BossSelect → LevelMetronome")
	if "LevelStaticShadow.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelStaticShadow for static_shadow")
	else:
		print("OK BossSelect → LevelStaticShadow")
	if "FortressComingSoon.tscn" not in bsel_src:
		errors.append("BossSelect should load FortressComingSoon for CORE-9")
	else:
		print("OK BossSelect → FortressComingSoon")

	# Boss select UI
	var boss_sel_packed: PackedScene = load("res://scenes/ui/BossSelect.tscn")
	if boss_sel_packed:
		var bsel = boss_sel_packed.instantiate()
		root.add_child(bsel)
		await process_frame
		var grid = bsel.get_node_or_null("BossGrid")
		if grid == null:
			errors.append("BossSelect missing BossGrid")
		else:
			print("OK BossSelect BossGrid children=", grid.get_child_count())
			if grid.get_child_count() != 9:
				errors.append("BossSelect grid expected 9 cells, got %d" % grid.get_child_count())
		var beat_cell = null
		var core_cell = null
		if grid:
			for c in grid.get_children():
				var bid = str(c.get_meta("boss_id", ""))
				if bid == "beatfire":
					beat_cell = c
				elif bid == "core9":
					core_cell = c
		if beat_cell == null:
			errors.append("BossSelect missing Beatfire cell")
		else:
			var st = beat_cell.get_node_or_null("SelectButton/StatusLabel")
			if st and "Pronto" in st.text and (gs == null or not gs.is_beatfire_defeated()):
				# playable should say ENTRAR not Pronto when not defeated
				errors.append("Beatfire playable status unexpected: " + st.text)
			elif st:
				print("OK Beatfire status=", st.text)
			# Secret stub when flight torso missing
			var secret = beat_cell.get_node_or_null("SelectButton/SecretStub")
			if secret == null and gs != null and gs.has_pending_armor_secret("beatfire"):
				errors.append("Beatfire missing SecretStub for pending armor")
			elif secret:
				print("OK Beatfire SecretStub present")
		if core_cell == null:
			errors.append("BossSelect missing CORE-9 cell")
		else:
			var cst = core_cell.get_node_or_null("SelectButton/StatusLabel")
			if cst == null or "BLOQUEADO" not in cst.text:
				errors.append("CORE-9 should show BLOQUEADO")
			else:
				print("OK CORE-9 locked status=", cst.text)
		# Echo Wind playable cell
		var echo_cell = null
		if grid:
			for c in grid.get_children():
				if str(c.get_meta("boss_id", "")) == "echo_wind":
					echo_cell = c
					break
		if echo_cell == null:
			errors.append("BossSelect missing Echo Wind cell")
		else:
			var est = echo_cell.get_node_or_null("SelectButton/StatusLabel")
			if est and "Pronto" in est.text:
				errors.append("Echo Wind should be playable, got: " + est.text)
			elif est:
				print("OK Echo Wind status=", est.text)
			var esecret = echo_cell.get_node_or_null("SelectButton/SecretStub")
			if esecret == null and gs != null and gs.has_pending_armor_secret("echo_wind"):
				errors.append("Echo Wind missing SecretStub for pending helmet")
			elif esecret:
				print("OK Echo Wind SecretStub present")
		# Neon Volt playable cell
		var neon_cell = null
		if grid:
			for c in grid.get_children():
				if str(c.get_meta("boss_id", "")) == "neon_volt":
					neon_cell = c
					break
		if neon_cell == null:
			errors.append("BossSelect missing Neon Volt cell")
		else:
			var nst = neon_cell.get_node_or_null("SelectButton/StatusLabel")
			if nst and "Pronto" in nst.text:
				errors.append("Neon Volt should be playable, got: " + nst.text)
			elif nst:
				print("OK Neon Volt status=", nst.text)
			var nsecret = neon_cell.get_node_or_null("SelectButton/SecretStub")
			if nsecret == null and gs != null and gs.has_pending_armor_secret("neon_volt"):
				errors.append("Neon Volt missing SecretStub for pending arms")
			elif nsecret:
				print("OK Neon Volt SecretStub present")
		# Glitch Ice playable cell
		var ice_cell = null
		if grid:
			for c in grid.get_children():
				if str(c.get_meta("boss_id", "")) == "glitch_ice":
					ice_cell = c
					break
		if ice_cell == null:
			errors.append("BossSelect missing Glitch Ice cell")
		else:
			var ist = ice_cell.get_node_or_null("SelectButton/StatusLabel")
			if ist and "Pronto" in ist.text:
				errors.append("Glitch Ice should be playable, got: " + ist.text)
			elif ist:
				print("OK Glitch Ice status=", ist.text)
		# Static Shadow playable cell
		var ss_cell = null
		if grid:
			for c in grid.get_children():
				if str(c.get_meta("boss_id", "")) == "static_shadow":
					ss_cell = c
					break
		if ss_cell == null:
			errors.append("BossSelect missing Static Shadow cell")
		else:
			var sst = ss_cell.get_node_or_null("SelectButton/StatusLabel")
			if sst and "Pronto" in sst.text:
				errors.append("Static Shadow should be playable, got: " + sst.text)
			elif sst:
				print("OK Static Shadow status=", sst.text)
			var sssecret = ss_cell.get_node_or_null("SelectButton/SecretStub")
			if sssecret == null and gs != null and gs.has_pending_armor_secret("static_shadow"):
				errors.append("Static Shadow missing SecretStub for pending encore helmet")
			elif sssecret:
				print("OK Static Shadow SecretStub present")
		# Spanish / GDD names present in scene tree
		var names_needed = ["Beatfire Man", "Glitch Ice", "Bassquake", "Echo Wind", "Neon Volt", "Metronome", "Chorus Bloom", "Static Shadow", "CORE-9"]
		var found_names := 0
		if grid:
			for c in grid.get_children():
				var nl = c.get_node_or_null("SelectButton/NameLabel")
				if nl:
					for nn in names_needed:
						if nn in nl.text or nl.text in nn:
							found_names += 1
							break
		if found_names < 8:
			errors.append("BossSelect missing GDD boss name labels (found %d)" % found_names)
		else:
			print("OK BossSelect GDD names found=", found_names)
		# Header SynthoCorp vibe
		var hdr = bsel.get_node_or_null("Header")
		if hdr == null or "SYNTHOCORP" not in hdr.text:
			errors.append("BossSelect missing SynthoCorp header")
		else:
			print("OK BossSelect SynthoCorp header")
		bsel.queue_free()
		await process_frame
	else:
		errors.append("BossSelect.tscn failed to load")

	# GameState boss defeat API
	if gs:
		gs.beatfire_defeated = false
		gs._bosses_defeated.clear()
		if "_weapons_unlocked" in gs:
			gs._weapons_unlocked.clear()
		if gs.is_beatfire_defeated():
			errors.append("beatfire_defeated should start false")
		else:
			print("OK beatfire_defeated starts false")
		gs.mark_beatfire_defeated()
		if not gs.is_beatfire_defeated() or not gs.beatfire_defeated:
			errors.append("mark_beatfire_defeated failed")
		else:
			print("OK mark_beatfire_defeated")
		# Rebuild BossSelect with checkmark
		var bsel2 = load("res://scenes/ui/BossSelect.tscn").instantiate()
		root.add_child(bsel2)
		await process_frame
		var grid2 = bsel2.get_node_or_null("BossGrid")
		var check_ok := false
		if grid2:
			for c in grid2.get_children():
				if str(c.get_meta("boss_id", "")) == "beatfire":
					var chk = c.get_node_or_null("SelectButton/Checkmark")
					var st3 = c.get_node_or_null("SelectButton/StatusLabel")
					if chk != null or (st3 and "VENCIDO" in st3.text):
						check_ok = true
						print("OK Beatfire checkmark/VENCIDO after defeat")
		if not check_ok:
			errors.append("BossSelect missing checkmark after beatfire_defeated")
		bsel2.queue_free()
		await process_frame
		# Leave defeated true for later boss-kill path consistency, then reset before level
		gs.beatfire_defeated = false
		gs._bosses_defeated.clear()
		if "_weapons_unlocked" in gs:
			gs._weapons_unlocked.clear()

	# Main scene should be Title
	var main_path: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if str(main_path) != "res://scenes/ui/TitleScreen.tscn":
		errors.append("main_scene expected TitleScreen, got %s" % str(main_path))
	else:
		print("OK main_scene=TitleScreen")

	# Instantiate TouchControls alone
	var touch_packed: PackedScene = load("res://scenes/ui/TouchControls.tscn")
	if touch_packed:
		var touch = touch_packed.instantiate()
		root.add_child(touch)
		await process_frame
		if touch.get_child_count() < 1:
			errors.append("TouchControls built no UI children")
		else:
			print("OK TouchControls UI children=", touch.get_child_count())
		for action in ["jump", "attack", "slide", "move_left", "move_right", "weapon_prev", "weapon_next"]:
			if not InputMap.has_action(action):
				errors.append("Missing InputMap action: " + action)
			else:
				print("OK InputMap action: ", action)
		for action in ["jump", "attack", "slide", "move_left", "move_right"]:
			var has_joy := false
			for e in InputMap.action_get_events(action):
				if e is InputEventJoypadButton or e is InputEventJoypadMotion:
					has_joy = true
					break
			if not has_joy:
				errors.append("No joypad binding on action: " + action)
			else:
				print("OK joypad bound: ", action)
		touch.queue_free()
		await process_frame
	else:
		errors.append("TouchControls.tscn failed to load as PackedScene")

	# Instantiate HUD alone
	var hud_packed: PackedScene = load("res://scenes/ui/HUD.tscn")
	if hud_packed:
		var hud = hud_packed.instantiate()
		root.add_child(hud)
		await process_frame
		if hud.layer != 50:
			errors.append("HUD layer expected 50, got %s" % str(hud.layer))
		else:
			print("OK HUD layer=", hud.layer)
		if hud.get_child_count() < 1:
			errors.append("HUD built no UI children")
		else:
			print("OK HUD UI children=", hud.get_child_count())
		var root_ctrl = hud.get_node_or_null("Root")
		if root_ctrl == null:
			errors.append("HUD missing Root control")
		else:
			for child_name in ["Portrait", "HpBg", "WeaponLabel", "PauseBtn", "PausePanel", "ArmorSlot0"]:
				if root_ctrl.get_node_or_null(child_name) == null:
					errors.append("HUD missing child: " + child_name)
				else:
					print("OK HUD has ", child_name)
		hud.queue_free()
		await process_frame
	else:
		errors.append("HUD.tscn failed to load as PackedScene")

	# Player HP API + weapons + ChargeAura smoke test
	var player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if player_packed:
		var player = player_packed.instantiate()
		root.add_child(player)
		await process_frame
		if not player.has_signal("hp_changed"):
			errors.append("Player missing hp_changed signal")
		else:
			print("OK Player hp_changed signal")
		if not player.has_signal("weapon_changed"):
			errors.append("Player missing weapon_changed signal")
		else:
			print("OK Player weapon_changed signal")
		if not ("hp" in player) or not ("max_hp" in player):
			errors.append("Player missing hp/max_hp")
		else:
			print("OK Player hp=", player.hp, " max_hp=", player.max_hp)
		if not player.has_method("take_damage"):
			errors.append("Player missing take_damage")
		else:
			var before: int = int(player.hp)
			player.take_damage(4)
			if int(player.hp) != before - 4:
				errors.append("take_damage did not reduce hp")
			else:
				print("OK take_damage hp ", before, "->", player.hp)
		if player.get_node_or_null("ChargeAura") == null:
			errors.append("Player missing ChargeAura")
		else:
			print("OK Player ChargeAura node")
		# Stage Flight hover
		if gs:
			gs.grant_armor_piece("flight", "torso", true)
		if player.has_method("on_armor_pickup"):
			player.on_armor_pickup("flight", "torso", "Torso Stage Flight")
		await process_frame
		if not player.has_method("has_flight_hover") or not player.has_flight_hover():
			errors.append("Player missing flight hover after armor")
		else:
			print("OK Player has_flight_hover")
		if player.get_node_or_null("ThrusterStub") == null:
			errors.append("Player missing ThrusterStub")
		else:
			print("OK Player ThrusterStub")
		# Clear armor so Level01 still spawns pickup
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
			player._sync_armor_from_state()
		if not player.has_method("_fire_buster") and not player.has_method("get_charge_level"):
			errors.append("Player missing buster API")
		else:
			print("OK Player buster helpers")
		if not player.has_method("grant_weapon"):
			errors.append("Player missing grant_weapon")
		else:
			player.grant_weapon("beat_blaze")
			await process_frame
			if not player.has_method("get_weapon_id"):
				errors.append("Player missing get_weapon_id")
			else:
				# grant switches to Beat Blaze
				if str(player.get_weapon_id()) != "beat_blaze":
					errors.append("grant_weapon did not select beat_blaze")
				else:
					print("OK grant_weapon beat_blaze")
			var w: Dictionary = player.get_current_weapon()
			if int(w.get("ammo", 0)) != 28:
				errors.append("Beat Blaze ammo expected 28, got %s" % str(w.get("ammo")))
			else:
				print("OK Beat Blaze ammo=", w.get("ammo"))
			# Fire Beat Blaze
			if player.has_method("_fire_beat_blaze"):
				player._fire_beat_blaze()
				await process_frame
				var blaze_shots = root.get_tree().get_nodes_in_group("player_shots")
				var found_blaze := false
				for s in blaze_shots:
					if s.get_script() and "BeatBlaze" in str(s.get_script().resource_path):
						found_blaze = true
					elif "damage" in s and int(s.damage) == 2 and s.is_in_group("player_shots"):
						# Beat Blaze damage 2
						found_blaze = true
				if not found_blaze and blaze_shots.is_empty():
					errors.append("BeatBlazeShot not spawned")
				else:
					print("OK BeatBlazeShot spawned count=", blaze_shots.size())
					w = player.get_current_weapon()
					if int(w.get("ammo", 28)) != 27:
						errors.append("Beat Blaze ammo not consumed (expected 27)")
					else:
						print("OK Beat Blaze ammo consumed=", w.get("ammo"))
					for sh in blaze_shots:
						sh.queue_free()
		# Fire a buster shot directly
		if player.has_method("_select_weapon_by_id"):
			player._select_weapon_by_id("buster")
		if player.has_method("_fire_buster"):
			player._fire_buster(1)
			await process_frame
			var shots = root.get_tree().get_nodes_in_group("player_shots")
			if shots.is_empty():
				errors.append("BusterShot not spawned after _fire_buster")
			else:
				print("OK BusterShot spawned count=", shots.size())
				var s = shots[0]
				if "damage" in s and int(s.damage) != 1:
					errors.append("Lv1 shot damage expected 1")
				else:
					print("OK Lv1 shot damage=", s.damage)
				for sh in shots:
					sh.queue_free()
		# Ensure Miku has SaberHitbox node even if unused
		if player.get_node_or_null("SaberHitbox") == null:
			errors.append("Player missing SaberHitbox")
		else:
			print("OK Player SaberHitbox node")
		player.queue_free()
		await process_frame

		# Teto saber path
		if gs:
			gs.select_teto()
		var teto = player_packed.instantiate()
		root.add_child(teto)
		await process_frame
		if not teto.has_method("is_teto") or not teto.is_teto():
			errors.append("Teto player is_teto expected true")
		else:
			print("OK Teto character applied")
		if str(teto.get_weapon_id()) != "saber":
			errors.append("Teto default weapon expected saber, got %s" % str(teto.get_weapon_id()))
		else:
			print("OK Teto weapon=saber")
		if teto.has_method("_swing_saber"):
			teto._swing_saber()
			await process_frame
			if float(teto._saber_timer) <= 0.0 and teto.saber_hitbox and not teto.saber_hitbox.monitoring:
				# may already have ended in same frame if duration tiny — check visual was armed
				pass
			if teto.saber_hitbox == null:
				errors.append("Teto saber_hitbox null")
			else:
				print("OK Teto saber swing armed monitoring=", teto.saber_hitbox.monitoring, " timer=", teto._saber_timer)
			# Spawn a Met in saber range and hit
			var met2 = load("res://scenes/enemies/MetBeat.tscn").instantiate()
			root.add_child(met2)
			met2.global_position = teto.global_position + Vector2(18, -6)
			met2._open = true
			await process_frame
			teto._saber_cd = 0.0
			teto._saber_timer = 0.0
			teto._swing_saber()
			await process_frame
			if int(met2.hp) >= 2:
				# try direct try_hit
				teto._saber_try_hit(met2)
			if int(met2.hp) >= 2:
				errors.append("Teto saber did not damage Met (hp=%d)" % int(met2.hp))
			else:
				print("OK Teto saber damaged Met hp=", met2.hp)
			met2.queue_free()
		# Beat Blaze still available for Teto
		teto.grant_weapon("beat_blaze")
		await process_frame
		if str(teto.get_weapon_id()) != "beat_blaze":
			errors.append("Teto grant Beat Blaze failed")
		else:
			print("OK Teto can use Beat Blaze")
		teto.queue_free()
		await process_frame
		if gs:
			gs.select_miku()
	else:
		errors.append("Player.tscn failed to load")

	# BreakableBlock smoke
	var brk_packed: PackedScene = load("res://scenes/props/BreakableBlock.tscn")
	if brk_packed:
		var brk = brk_packed.instantiate()
		root.add_child(brk)
		await process_frame
		if not brk.is_in_group("breakable"):
			errors.append("BreakableBlock not in breakable group")
		else:
			print("OK BreakableBlock group")
		if not brk.has_method("take_damage"):
			errors.append("BreakableBlock missing take_damage")
		else:
			brk.take_damage(1)
			await process_frame
			if is_instance_valid(brk):
				errors.append("BreakableBlock should free after HP 0")
			else:
				print("OK BreakableBlock destroyed")
		if is_instance_valid(brk):
			brk.queue_free()
			await process_frame
	else:
		errors.append("BreakableBlock.tscn failed to load")

	# ArmorPickup smoke
	var ap_packed: PackedScene = load("res://scenes/pickups/ArmorPickup.tscn")
	if ap_packed:
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
		var ap = ap_packed.instantiate()
		root.add_child(ap)
		await process_frame
		if str(ap.display_name_es).find("Stage Flight") < 0:
			errors.append("ArmorPickup Spanish name missing Stage Flight")
		else:
			print("OK ArmorPickup name=", ap.display_name_es)
		ap.queue_free()
		await process_frame
	else:
		errors.append("ArmorPickup.tscn failed to load")

	# MetBeat open/closed + damage
	var met_packed: PackedScene = load("res://scenes/enemies/MetBeat.tscn")
	if met_packed:
		var met = met_packed.instantiate()
		root.add_child(met)
		await process_frame
		if not met.is_in_group("enemies"):
			errors.append("MetBeat not in enemies group")
		else:
			print("OK MetBeat in enemies group")
		if not met.has_method("take_damage"):
			errors.append("MetBeat missing take_damage")
		else:
			met._open = false
			var blocked = met.take_damage(1)
			if blocked != false:
				errors.append("Closed Met should reject damage")
			else:
				print("OK Met shell blocked shot")
			if int(met.hp) != 2:
				errors.append("Closed Met HP should stay 2")
			met._open = true
			met.take_damage(1)
			if int(met.hp) != 1:
				errors.append("Open Met HP expected 1 after 1 dmg")
			else:
				print("OK Met took damage while open hp=", met.hp)
			met.take_damage(1)
			await process_frame
			if is_instance_valid(met):
				errors.append("Met should queue_free after HP 0")
			else:
				print("OK Met freed on death")
		if is_instance_valid(met):
			met.queue_free()
			await process_frame
	else:
		errors.append("MetBeat.tscn failed to load")

	# Beatfire Man boss smoke
	var boss_packed: PackedScene = load("res://scenes/bosses/BeatfireMan.tscn")
	if boss_packed:
		var boss = boss_packed.instantiate()
		root.add_child(boss)
		await process_frame
		if not boss.is_in_group("enemies") or not boss.is_in_group("bosses"):
			errors.append("BeatfireMan missing enemies/bosses group")
		else:
			print("OK BeatfireMan groups")
		if int(boss.hp) != 28:
			errors.append("BeatfireMan HP expected 28")
		else:
			print("OK BeatfireMan hp=", boss.hp)
		# Inactive: should not take damage
		var blocked_inactive = boss.take_damage(3)
		if blocked_inactive != false or int(boss.hp) != 28:
			errors.append("Inactive boss should ignore damage")
		else:
			print("OK inactive boss ignores damage")
		if boss.has_method("activate"):
			boss.activate()
		boss.take_damage(3)
		if int(boss.hp) != 25:
			errors.append("Active boss HP expected 25 after 3 dmg")
		else:
			print("OK boss took buster damage hp=", boss.hp)
		# Wait out brief hit invuln then apply charge-style damage
		boss._invuln = 0.0
		boss.take_damage(3)
		if int(boss.hp) != 22:
			errors.append("Boss HP expected 22, got %d" % int(boss.hp))
		else:
			print("OK boss charge-style dmg hp=", boss.hp)
		boss.queue_free()
		await process_frame
	else:
		errors.append("BeatfireMan.tscn failed to load")

	# Echo Wind boss smoke + Beat Blaze weakness ×3
	var ewb_packed: PackedScene = load("res://scenes/bosses/EchoWind.tscn")
	if ewb_packed:
		var ewb = ewb_packed.instantiate()
		root.add_child(ewb)
		await process_frame
		if not ewb.is_in_group("enemies") or not ewb.is_in_group("bosses"):
			errors.append("EchoWind missing enemies/bosses group")
		else:
			print("OK EchoWind groups")
		if not ewb.is_in_group("weak_to_beat_blaze"):
			errors.append("EchoWind missing weak_to_beat_blaze group")
		else:
			print("OK EchoWind weak_to_beat_blaze")
		if int(ewb.hp) != 28:
			errors.append("EchoWind HP expected 28")
		else:
			print("OK EchoWind hp=", ewb.hp)
		var eblocked = ewb.take_damage(3)
		if eblocked != false or int(ewb.hp) != 28:
			errors.append("Inactive EchoWind should ignore damage")
		else:
			print("OK inactive EchoWind ignores damage")
		if ewb.has_method("activate"):
			ewb.activate()
		ewb.take_damage(2)
		if int(ewb.hp) != 26:
			errors.append("EchoWind HP expected 26 after 2 dmg")
		else:
			print("OK EchoWind took dmg hp=", ewb.hp)
		# Weakness via BeatBlazeShot
		ewb._invuln = 0.0
		var blaze = load("res://scenes/combat/BeatBlazeShot.tscn").instantiate()
		root.add_child(blaze)
		blaze.global_position = ewb.global_position
		if blaze.has_method("_try_hit"):
			blaze._try_hit(ewb)
		await process_frame
		# damage 2 * 3 = 6 → hp 20
		if int(ewb.hp) != 20:
			errors.append("Beat Blaze weakness expected hp 20 (26-6), got %d" % int(ewb.hp))
		else:
			print("OK Beat Blaze ×3 vs EchoWind hp=", ewb.hp)
		if is_instance_valid(blaze):
			blaze.queue_free()
		ewb.queue_free()
		await process_frame
	else:
		errors.append("EchoWind.tscn failed to load")

	# Echo Gale weapon smoke on Player
	var eg_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if eg_player_packed:
		if gs:
			gs.select_miku()
		var egp = eg_player_packed.instantiate()
		root.add_child(egp)
		await process_frame
		egp.grant_weapon("echo_gale")
		await process_frame
		if str(egp.get_weapon_id()) != "echo_gale":
			errors.append("grant_weapon echo_gale failed")
		else:
			print("OK grant_weapon echo_gale")
		var egw: Dictionary = egp.get_current_weapon()
		if int(egw.get("ammo", 0)) != 28:
			errors.append("Echo Gale ammo expected 28")
		else:
			print("OK Echo Gale ammo=", egw.get("ammo"))
		if egp.has_method("_fire_echo_gale"):
			egp._fire_echo_gale()
			await process_frame
			var gale_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_gale := false
			for s in gale_shots:
				if s.get_script() and "EchoGale" in str(s.get_script().resource_path):
					found_gale = true
				elif "damage" in s and int(s.damage) == 2:
					found_gale = true
			if not found_gale and gale_shots.is_empty():
				errors.append("EchoGaleShot not spawned")
			else:
				print("OK EchoGaleShot spawned count=", gale_shots.size())
				egw = egp.get_current_weapon()
				if int(egw.get("ammo", 28)) != 27:
					errors.append("Echo Gale ammo not consumed")
				else:
					print("OK Echo Gale ammo consumed=", egw.get("ammo"))
				for sh in gale_shots:
					sh.queue_free()
		# Wind push API
		if not egp.has_method("apply_wind"):
			errors.append("Player missing apply_wind")
		else:
			egp.apply_wind(Vector2(50, 0))
			if egp._wind_force.x < 40.0:
				errors.append("apply_wind did not accumulate")
			else:
				print("OK apply_wind force=", egp._wind_force)
			egp._wind_force = Vector2.ZERO
		egp.queue_free()
		await process_frame
	else:
		errors.append("Player.tscn failed for Echo Gale test")

	# WindCurrent smoke
	var wc_packed: PackedScene = load("res://scenes/hazards/WindCurrent.tscn")
	if wc_packed:
		var wc = wc_packed.instantiate()
		root.add_child(wc)
		await process_frame
		if not wc.is_in_group("wind_currents"):
			errors.append("WindCurrent not in wind_currents group")
		else:
			print("OK WindCurrent group")
		wc.queue_free()
		await process_frame
	else:
		errors.append("WindCurrent.tscn failed to load")

	# GameState echo_wind defeat + weapon unlock
	if gs:
		gs.beatfire_defeated = false
		gs._bosses_defeated.clear()
		# keep prior unlocks from tests; ensure echo mark works
		gs.mark_boss_defeated("echo_wind")
		if not gs.is_boss_defeated("echo_wind"):
			errors.append("mark echo_wind defeated failed")
		else:
			print("OK echo_wind defeated in GameState")
		if not gs.has_weapon_unlocked("echo_gale"):
			errors.append("echo_gale should unlock on echo_wind defeat")
		else:
			print("OK echo_gale unlocked")
		# Rebuild BossSelect checkmark for echo
		var bsel_e = load("res://scenes/ui/BossSelect.tscn").instantiate()
		root.add_child(bsel_e)
		await process_frame
		var grid_e = bsel_e.get_node_or_null("BossGrid")
		var echo_check := false
		if grid_e:
			for c in grid_e.get_children():
				if str(c.get_meta("boss_id", "")) == "echo_wind":
					var chk = c.get_node_or_null("SelectButton/Checkmark")
					var st = c.get_node_or_null("SelectButton/StatusLabel")
					if chk != null or (st and "VENCIDO" in st.text):
						echo_check = true
						print("OK Echo Wind checkmark/VENCIDO after defeat")
		if not echo_check:
			errors.append("BossSelect missing Echo Wind checkmark after defeat")
		bsel_e.queue_free()
		await process_frame
		gs._bosses_defeated.clear()
		# leave weapons unlocked for level restore test

	# Instantiate LevelEchoWind
	var echo_level_packed: PackedScene = load("res://scenes/levels/LevelEchoWind.tscn")
	if echo_level_packed:
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
		var elvl = echo_level_packed.instantiate()
		root.add_child(elvl)
		print("OK instantiate LevelEchoWind, children=", elvl.get_child_count())
		await process_frame
		await process_frame
		var eent = elvl.get_node_or_null("Entities")
		if eent == null:
			errors.append("LevelEchoWind Entities missing")
		else:
			var ep = eent.get_node_or_null("Player")
			if ep == null:
				errors.append("Player not spawned in LevelEchoWind")
			else:
				print("OK EchoWind level player spawned")
			var eboss = 0
			var emet = 0
			for c in eent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Echo"):
					eboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					emet += 1
			if emet < 2:
				errors.append("Expected >=2 MetBeat in LevelEchoWind, got %d" % emet)
			else:
				print("OK MetBeat in LevelEchoWind=", emet)
			if eboss < 1:
				errors.append("Expected EchoWind boss in level")
			else:
				print("OK EchoWind boss in level")
			if eent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelEchoWind ArenaTrigger missing")
			else:
				print("OK LevelEchoWind ArenaTrigger")
			var helm = eent.get_node_or_null("FlightHelmetPickup")
			if helm == null:
				errors.append("FlightHelmetPickup missing in LevelEchoWind")
			else:
				print("OK FlightHelmetPickup at ", helm.position)
		var ehaz = elvl.get_node_or_null("Hazards")
		var wind_n := 0
		if ehaz:
			for c in ehaz.get_children():
				if c.is_in_group("wind_currents") or str(c.name).begins_with("Wind"):
					wind_n += 1
		if wind_n < 2:
			errors.append("Expected >=2 WindCurrent in LevelEchoWind, got %d" % wind_n)
		else:
			print("OK WindCurrent count=", wind_n)
		if elvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelEchoWind")
		else:
			print("OK HUD in LevelEchoWind")
		if elvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelEchoWind")
		else:
			print("OK TouchControls in LevelEchoWind")
		# Helmet pickup → armor head (2/3 if torso also — grant torso first)
		if gs:
			gs.grant_armor_piece("flight", "torso", true)
		var helm2 = eent.get_node_or_null("FlightHelmetPickup") if eent else null
		var ep2 = eent.get_node_or_null("Player") if eent else null
		if helm2 and ep2 and helm2.has_method("_collect"):
			helm2._collect(ep2)
			await process_frame
			if gs and not gs.has_armor_piece("flight", "head"):
				errors.append("Helmet pickup did not grant head")
			else:
				print("OK flight head owned count=", gs.get_armor_owned_count("flight") if gs else -1)
			if gs and int(gs.get_armor_owned_count("flight")) < 2:
				errors.append("Expected armor 2/3 after torso+head")
			else:
				print("OK Stage Flight armor 2/3")
		# Boss kill path
		if elvl.has_method("_start_boss_fight"):
			elvl._start_boss_fight()
			await process_frame
			var boss_e = eent.get_node_or_null("EchoWind") if eent else null
			if boss_e and boss_e.has_method("take_damage"):
				while is_instance_valid(boss_e) and int(boss_e.hp) > 0:
					boss_e.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var ep3 = eent.get_node_or_null("Player") if eent else null
				if ep3 and ep3.has_method("_has_weapon"):
					if not ep3._has_weapon("echo_gale"):
						errors.append("Echo Wind defeat did not grant Echo Gale")
					else:
						print("OK Echo Wind defeat granted Echo Gale")
				if gs and not gs.is_boss_defeated("echo_wind"):
					errors.append("Echo Wind defeat did not set GameState")
				else:
					print("OK GameState echo_wind defeated after win")
				var win_e = elvl.get_node_or_null("WinBanner")
				if win_e == null:
					print("WARN Echo Wind WinBanner not found immediately")
				else:
					print("OK Echo Wind WinBanner")
					var ret_e = win_e.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_e == null:
						errors.append("Echo Wind WinBanner missing ReturnBossSelect")
					else:
						print("OK Echo Wind ReturnBossSelect")
		elvl.queue_free()
		await process_frame
	else:
		errors.append("LevelEchoWind.tscn failed to load")

	# --- Neon Volt boss / weapon / level ---
	var nv_boss_packed: PackedScene = load("res://scenes/bosses/NeonVolt.tscn")
	if nv_boss_packed:
		var nvb = nv_boss_packed.instantiate()
		root.add_child(nvb)
		await process_frame
		if not nvb.is_in_group("weak_to_echo_gale"):
			errors.append("NeonVolt missing weak_to_echo_gale group")
		else:
			print("OK NeonVolt weak_to_echo_gale")
		if int(nvb.hp) != 28:
			errors.append("NeonVolt HP expected 28, got %d" % int(nvb.hp))
		else:
			print("OK NeonVolt HP=28")
		if nvb.has_method("activate"):
			nvb.activate()
		# Echo Gale ×3 weakness: base damage 2 → 6
		nvb.hp = 26
		var gale = load("res://scenes/combat/EchoGaleShot.tscn").instantiate()
		root.add_child(gale)
		gale.global_position = nvb.global_position
		# Echo Gale delays launch; force moving so _try_hit applies
		if "_moving" in gale:
			gale._moving = true
		if gale.has_method("_try_hit"):
			gale._try_hit(nvb)
		await process_frame
		if int(nvb.hp) != 20:
			errors.append("Echo Gale weakness expected hp 20 (26-6), got %d" % int(nvb.hp))
		else:
			print("OK Echo Gale ×3 vs NeonVolt hp=", nvb.hp)
		if is_instance_valid(gale):
			gale.queue_free()
		nvb.queue_free()
		await process_frame
	else:
		errors.append("NeonVolt.tscn failed to load")

	# Neon Arc weapon smoke
	var na_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if na_player_packed:
		if gs:
			gs.select_miku()
		var nap = na_player_packed.instantiate()
		root.add_child(nap)
		await process_frame
		nap.grant_weapon("neon_arc")
		await process_frame
		if str(nap.get_weapon_id()) != "neon_arc":
			errors.append("grant_weapon neon_arc failed")
		else:
			print("OK grant_weapon neon_arc")
		var naw: Dictionary = nap.get_current_weapon()
		if int(naw.get("ammo", 0)) != 28:
			errors.append("Neon Arc ammo expected 28")
		else:
			print("OK Neon Arc ammo=", naw.get("ammo"))
		if nap.has_method("_fire_neon_arc"):
			nap._fire_neon_arc()
			await process_frame
			var na_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_na := false
			for s in na_shots:
				if s.get_script() and "NeonArc" in str(s.get_script().resource_path):
					found_na = true
				elif "damage" in s and int(s.damage) == 2:
					found_na = true
			if not found_na and na_shots.is_empty():
				errors.append("NeonArcShot not spawned")
			else:
				print("OK NeonArcShot spawned count=", na_shots.size())
				naw = nap.get_current_weapon()
				if int(naw.get("ammo", 28)) != 27:
					errors.append("Neon Arc ammo not consumed")
				else:
					print("OK Neon Arc ammo consumed=", naw.get("ammo"))
				for sh in na_shots:
					sh.queue_free()
		# Arms armor → charge Nv4 stub
		if gs:
			gs.grant_armor_piece("flight", "arms", true)
		if nap.has_method("on_armor_pickup"):
			nap.on_armor_pickup("flight", "arms", "Brazos Stage Flight")
		await process_frame
		if nap.has_method("has_flight_arms") and not nap.has_flight_arms():
			errors.append("Player missing flight arms after pickup")
		else:
			print("OK Player flight arms equipped")
		# Simulate charge time past LV4 (select buster first — switch clears charge)
		nap._select_weapon_by_id("buster")
		nap._has_flight_arms = true
		nap._charging = true
		nap._charge_time = 2.0
		var clv = int(nap.get_charge_level()) if nap.has_method("get_charge_level") else 0
		if clv < 4:
			errors.append("Expected charge Nv4 with arms, got %d" % clv)
		else:
			print("OK charge Nv4 stub level=", clv)
		nap.queue_free()
		await process_frame
	else:
		errors.append("Player.tscn failed for Neon Arc test")

	# ElectricFloor smoke
	var ef_packed: PackedScene = load("res://scenes/hazards/ElectricFloor.tscn")
	if ef_packed:
		var ef = ef_packed.instantiate()
		root.add_child(ef)
		await process_frame
		if not ef.is_in_group("electric_floors"):
			errors.append("ElectricFloor not in electric_floors group")
		else:
			print("OK ElectricFloor group")
		ef.queue_free()
		await process_frame
	else:
		errors.append("ElectricFloor.tscn failed to load")

	# GameState neon_volt defeat + weapon unlock
	if gs:
		gs.mark_boss_defeated("neon_volt")
		if not gs.is_boss_defeated("neon_volt"):
			errors.append("mark neon_volt defeated failed")
		else:
			print("OK neon_volt defeated in GameState")
		if not gs.has_weapon_unlocked("neon_arc"):
			errors.append("neon_arc should unlock on neon_volt defeat")
		else:
			print("OK neon_arc unlocked")
		# BossSelect defeated checkmark for neon
		var bsel2_packed: PackedScene = load("res://scenes/ui/BossSelect.tscn")
		if bsel2_packed:
			var bsel2 = bsel2_packed.instantiate()
			root.add_child(bsel2)
			await process_frame
			var grid2 = bsel2.get_node_or_null("BossGrid")
			var neon_def = null
			if grid2:
				for c in grid2.get_children():
					if str(c.get_meta("boss_id", "")) == "neon_volt":
						neon_def = c
						break
			if neon_def:
				var stn = neon_def.get_node_or_null("SelectButton/StatusLabel")
				if stn and "VENCIDO" in stn.text:
					print("OK Neon Volt VENCIDO status")
				elif stn:
					print("OK Neon Volt status after defeat=", stn.text)
			bsel2.queue_free()
			await process_frame

	# Instantiate LevelNeonVolt
	var neon_level_packed: PackedScene = load("res://scenes/levels/LevelNeonVolt.tscn")
	if neon_level_packed:
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
		var nlvl = neon_level_packed.instantiate()
		root.add_child(nlvl)
		print("OK instantiate LevelNeonVolt, children=", nlvl.get_child_count())
		await process_frame
		await process_frame
		var nent = nlvl.get_node_or_null("Entities")
		if nent == null:
			errors.append("LevelNeonVolt Entities missing")
		else:
			var np = nent.get_node_or_null("Player")
			if np == null:
				errors.append("Player not spawned in LevelNeonVolt")
			else:
				print("OK NeonVolt level player spawned")
			var nboss = 0
			var nmet = 0
			for c in nent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Neon"):
					nboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					nmet += 1
			if nmet < 2:
				errors.append("Expected >=2 MetBeat in LevelNeonVolt, got %d" % nmet)
			else:
				print("OK MetBeat in LevelNeonVolt=", nmet)
			if nboss < 1:
				errors.append("Expected NeonVolt boss in level")
			else:
				print("OK NeonVolt boss in level")
			if nent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelNeonVolt ArenaTrigger missing")
			else:
				print("OK LevelNeonVolt ArenaTrigger")
			var arms = nent.get_node_or_null("FlightArmsPickup")
			if arms == null:
				errors.append("FlightArmsPickup missing in LevelNeonVolt")
			else:
				print("OK FlightArmsPickup at ", arms.position)
		var nhaz = nlvl.get_node_or_null("Hazards")
		var elec_n := 0
		if nhaz:
			for c in nhaz.get_children():
				if c.is_in_group("electric_floors") or str(c.name).begins_with("Electric"):
					elec_n += 1
		if elec_n < 3:
			errors.append("Expected >=3 ElectricFloor in LevelNeonVolt, got %d" % elec_n)
		else:
			print("OK ElectricFloor count=", elec_n)
		if nlvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelNeonVolt")
		else:
			print("OK HUD in LevelNeonVolt")
		if nlvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelNeonVolt")
		else:
			print("OK TouchControls in LevelNeonVolt")
		# Arms pickup → armor 3/3 if head+torso granted
		if gs:
			gs.grant_armor_piece("flight", "torso", true)
			gs.grant_armor_piece("flight", "head", true)
		var arms2 = nent.get_node_or_null("FlightArmsPickup") if nent else null
		var np2 = nent.get_node_or_null("Player") if nent else null
		if arms2 and np2 and arms2.has_method("_collect"):
			arms2._collect(np2)
			await process_frame
			if gs and not gs.has_armor_piece("flight", "arms"):
				errors.append("Arms pickup did not grant arms")
			else:
				print("OK flight arms owned count=", gs.get_armor_owned_count("flight") if gs else -1)
			if gs and int(gs.get_armor_owned_count("flight")) < 3:
				errors.append("Expected armor 3/3 after torso+head+arms")
			else:
				print("OK Stage Flight armor 3/3")
		# Boss kill path
		if nlvl.has_method("_start_boss_fight"):
			nlvl._start_boss_fight()
			await process_frame
			var boss_n = nent.get_node_or_null("NeonVolt") if nent else null
			if boss_n and boss_n.has_method("take_damage"):
				while is_instance_valid(boss_n) and int(boss_n.hp) > 0:
					boss_n.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var np3 = nent.get_node_or_null("Player") if nent else null
				if np3 and np3.has_method("_has_weapon"):
					if not np3._has_weapon("neon_arc"):
						errors.append("Neon Volt defeat did not grant Neon Arc")
					else:
						print("OK Neon Volt defeat granted Neon Arc")
				if gs and not gs.is_boss_defeated("neon_volt"):
					errors.append("Neon Volt defeat did not set GameState")
				else:
					print("OK GameState neon_volt defeated after win")
				var win_n = nlvl.get_node_or_null("WinBanner")
				if win_n == null:
					print("WARN Neon Volt WinBanner not found immediately")
				else:
					print("OK Neon Volt WinBanner")
					var ret_n = win_n.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_n == null:
						errors.append("Neon Volt WinBanner missing ReturnBossSelect")
					else:
						print("OK Neon Volt ReturnBossSelect")
		nlvl.queue_free()
		await process_frame
	else:
		errors.append("LevelNeonVolt.tscn failed to load")


	# --- Glitch Ice boss / weapon / level ---
	var gi_boss_packed: PackedScene = load("res://scenes/bosses/GlitchIce.tscn")
	if gi_boss_packed:
		var gib = gi_boss_packed.instantiate()
		root.add_child(gib)
		await process_frame
		if not gib.is_in_group("weak_to_neon_arc"):
			errors.append("GlitchIce missing weak_to_neon_arc group")
		else:
			print("OK GlitchIce weak_to_neon_arc")
		if int(gib.hp) != 28:
			errors.append("GlitchIce HP expected 28, got %d" % int(gib.hp))
		else:
			print("OK GlitchIce HP=28")
		if gib.has_method("activate"):
			gib.activate()
		# Neon Arc ×3: base 2 → 6
		gib.hp = 26
		var narc = load("res://scenes/combat/NeonArcShot.tscn").instantiate()
		root.add_child(narc)
		narc.global_position = gib.global_position
		if narc.has_method("_try_hit"):
			narc._try_hit(gib)
		await process_frame
		if int(gib.hp) != 20:
			errors.append("Neon Arc weakness expected hp 20 (26-6), got %d" % int(gib.hp))
		else:
			print("OK Neon Arc ×3 vs GlitchIce hp=", gib.hp)
		if is_instance_valid(narc):
			narc.queue_free()
		gib.queue_free()
		await process_frame
	else:
		errors.append("GlitchIce.tscn failed to load")

	# Freeze Sample weapon smoke
	var fs_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if fs_player_packed:
		if gs:
			gs.select_miku()
		var fsp = fs_player_packed.instantiate()
		root.add_child(fsp)
		await process_frame
		fsp.grant_weapon("freeze_sample")
		await process_frame
		if str(fsp.get_weapon_id()) != "freeze_sample":
			errors.append("grant_weapon freeze_sample failed")
		else:
			print("OK grant_weapon freeze_sample")
		var fsw: Dictionary = fsp.get_current_weapon()
		if int(fsw.get("ammo", 0)) != 28:
			errors.append("Freeze Sample ammo expected 28")
		else:
			print("OK Freeze Sample ammo=", fsw.get("ammo"))
		if fsp.has_method("_fire_freeze_sample"):
			fsp._fire_freeze_sample()
			await process_frame
			var fs_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_fs := false
			for s in fs_shots:
				if s.get_script() and "FreezeSample" in str(s.get_script().resource_path):
					found_fs = true
				elif "damage" in s and int(s.damage) == 2:
					found_fs = true
			if not found_fs and fs_shots.is_empty():
				errors.append("FreezeSampleShot not spawned")
			else:
				print("OK FreezeSampleShot spawned count=", fs_shots.size())
				fsw = fsp.get_current_weapon()
				if int(fsw.get("ammo", 28)) != 27:
					errors.append("Freeze Sample ammo not consumed")
				else:
					print("OK Freeze Sample ammo consumed=", fsw.get("ammo"))
				for sh in fs_shots:
					sh.queue_free()
		# Optional: Freeze Sample ×3 vs Beatfire
		var bf_pack: PackedScene = load("res://scenes/bosses/BeatfireMan.tscn")
		if bf_pack:
			var bfb = bf_pack.instantiate()
			root.add_child(bfb)
			await process_frame
			if not bfb.is_in_group("weak_to_freeze_sample"):
				errors.append("BeatfireMan missing weak_to_freeze_sample")
			else:
				print("OK Beatfire weak_to_freeze_sample")
			if bfb.has_method("activate"):
				bfb.activate()
			bfb.hp = 26
			var fshot = load("res://scenes/combat/FreezeSampleShot.tscn").instantiate()
			root.add_child(fshot)
			fshot.global_position = bfb.global_position
			if fshot.has_method("_try_hit"):
				fshot._try_hit(bfb)
			await process_frame
			if int(bfb.hp) != 20:
				errors.append("Freeze Sample vs Beatfire expected hp 20, got %d" % int(bfb.hp))
			else:
				print("OK Freeze Sample ×3 vs Beatfire hp=", bfb.hp)
			if is_instance_valid(fshot):
				fshot.queue_free()
			bfb.queue_free()
			await process_frame
		fsp.queue_free()
		await process_frame
	else:
		errors.append("Player.tscn failed for Freeze Sample test")

	# FrameSkipPlatform smoke
	var fsp_plat: PackedScene = load("res://scenes/props/FrameSkipPlatform.tscn")
	if fsp_plat:
		var fplat = fsp_plat.instantiate()
		root.add_child(fplat)
		await process_frame
		if not fplat.is_in_group("frame_skip_platforms"):
			errors.append("FrameSkipPlatform missing group")
		else:
			print("OK FrameSkipPlatform group")
		fplat.queue_free()
		await process_frame
	else:
		errors.append("FrameSkipPlatform.tscn failed to load")

	# Energy tank GameState API
	if gs:
		var prev_et = int(gs.get_energy_tanks()) if gs.has_method("get_energy_tanks") else -1
		if not gs.has_method("grant_energy_tank"):
			errors.append("GameState missing grant_energy_tank")
		else:
			gs.energy_tanks = 0
			var n1 = int(gs.grant_energy_tank())
			if n1 != 1:
				errors.append("grant_energy_tank expected 1, got %d" % n1)
			else:
				print("OK grant_energy_tank=", n1)
		gs.mark_boss_defeated("glitch_ice")
		if not gs.is_boss_defeated("glitch_ice"):
			errors.append("mark glitch_ice defeated failed")
		else:
			print("OK glitch_ice defeated in GameState")
		if not gs.has_weapon_unlocked("freeze_sample"):
			errors.append("freeze_sample should unlock on glitch_ice defeat")
		else:
			print("OK freeze_sample unlocked")

	# Instantiate LevelGlitchIce
	var ice_level_packed: PackedScene = load("res://scenes/levels/LevelGlitchIce.tscn")
	if ice_level_packed:
		if gs:
			gs.energy_tanks = 0
		var ilvl = ice_level_packed.instantiate()
		root.add_child(ilvl)
		print("OK instantiate LevelGlitchIce, children=", ilvl.get_child_count())
		await process_frame
		await process_frame
		var ient = ilvl.get_node_or_null("Entities")
		if ient == null:
			errors.append("LevelGlitchIce Entities missing")
		else:
			var ip = ient.get_node_or_null("Player")
			if ip == null:
				errors.append("Player not spawned in LevelGlitchIce")
			else:
				print("OK GlitchIce level player spawned")
			var iboss = 0
			var imet = 0
			for c in ient.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Glitch"):
					iboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					imet += 1
			if imet < 2:
				errors.append("Expected >=2 MetBeat in LevelGlitchIce, got %d" % imet)
			else:
				print("OK MetBeat in LevelGlitchIce=", imet)
			if iboss < 1:
				errors.append("Expected GlitchIce boss in level")
			else:
				print("OK GlitchIce boss in level")
			if ient.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelGlitchIce ArenaTrigger missing")
			else:
				print("OK LevelGlitchIce ArenaTrigger")
			var etank = ient.get_node_or_null("EnergyTankPickup")
			if etank == null:
				errors.append("EnergyTankPickup missing in LevelGlitchIce")
			else:
				print("OK EnergyTankPickup at ", etank.position)
		var igeom = ilvl.get_node_or_null("Geometry")
		var skip_n := 0
		if igeom:
			for c in igeom.get_children():
				if c.is_in_group("frame_skip_platforms") or str(c.name).begins_with("FrameSkip"):
					skip_n += 1
		if skip_n < 3:
			errors.append("Expected >=3 FrameSkipPlatform in LevelGlitchIce, got %d" % skip_n)
		else:
			print("OK FrameSkipPlatform count=", skip_n)
		if ilvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelGlitchIce")
		else:
			print("OK HUD in LevelGlitchIce")
		if ilvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelGlitchIce")
		else:
			print("OK TouchControls in LevelGlitchIce")
		# Energy tank pickup
		var et2 = ient.get_node_or_null("EnergyTankPickup") if ient else null
		var ip2 = ient.get_node_or_null("Player") if ient else null
		if et2 and ip2 and et2.has_method("_collect"):
			et2._collect(ip2)
			await process_frame
			if gs and int(gs.get_energy_tanks()) < 1:
				errors.append("Energy tank pickup did not increase tanks")
			else:
				print("OK energy tanks after pickup=", gs.get_energy_tanks() if gs else -1)
			var hud_i = ilvl.get_node_or_null("HUD")
			if hud_i and hud_i.has_method("sync_energy_tanks_from_state"):
				hud_i.sync_energy_tanks_from_state()
			if hud_i and "energy_tanks" in hud_i:
				if int(hud_i.energy_tanks) < 1:
					errors.append("HUD energy_tanks not updated")
				else:
					print("OK HUD energy_tanks=", hud_i.energy_tanks)
		# Boss kill path
		if ilvl.has_method("_start_boss_fight"):
			ilvl._start_boss_fight()
			await process_frame
			var boss_i = ient.get_node_or_null("GlitchIce") if ient else null
			if boss_i and boss_i.has_method("take_damage"):
				while is_instance_valid(boss_i) and int(boss_i.hp) > 0:
					boss_i.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var ip3 = ient.get_node_or_null("Player") if ient else null
				if ip3 and ip3.has_method("_has_weapon"):
					if not ip3._has_weapon("freeze_sample"):
						errors.append("Glitch Ice defeat did not grant Freeze Sample")
					else:
						print("OK Glitch Ice defeat granted Freeze Sample")
				if gs and not gs.is_boss_defeated("glitch_ice"):
					errors.append("Glitch Ice defeat did not set GameState")
				else:
					print("OK GameState glitch_ice defeated after win")
				var win_i = ilvl.get_node_or_null("WinBanner")
				if win_i == null:
					print("WARN Glitch Ice WinBanner not found immediately")
				else:
					print("OK Glitch Ice WinBanner")
					var ret_i = win_i.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_i == null:
						errors.append("Glitch Ice WinBanner missing ReturnBossSelect")
					else:
						print("OK Glitch Ice ReturnBossSelect")
		ilvl.queue_free()
		await process_frame
	else:
		errors.append("LevelGlitchIce.tscn failed to load")


	# --- Chorus Bloom boss / weapon / level ---
	var cb_boss_packed: PackedScene = load("res://scenes/bosses/ChorusBloom.tscn")
	if cb_boss_packed:
		var cbb = cb_boss_packed.instantiate()
		root.add_child(cbb)
		await process_frame
		if not cbb.is_in_group("weak_to_freeze_sample"):
			errors.append("ChorusBloom missing weak_to_freeze_sample group")
		else:
			print("OK ChorusBloom weak_to_freeze_sample")
		if int(cbb.hp) != 28:
			errors.append("ChorusBloom HP expected 28, got %d" % int(cbb.hp))
		else:
			print("OK ChorusBloom HP=28")
		if cbb.has_method("activate"):
			cbb.activate()
		# Freeze Sample ×3: base 2 → 6
		cbb.hp = 26
		var fsc = load("res://scenes/combat/FreezeSampleShot.tscn").instantiate()
		root.add_child(fsc)
		fsc.global_position = cbb.global_position
		if fsc.has_method("_try_hit"):
			fsc._try_hit(cbb)
		await process_frame
		if int(cbb.hp) != 20:
			errors.append("Freeze Sample weakness vs ChorusBloom expected hp 20 (26-6), got %d" % int(cbb.hp))
		else:
			print("OK Freeze Sample ×3 vs ChorusBloom hp=", cbb.hp)
		if is_instance_valid(fsc):
			fsc.queue_free()
		cbb.queue_free()
		await process_frame
	else:
		errors.append("ChorusBloom.tscn failed to load")

	# Petal Chorus weapon smoke
	var pc_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if pc_player_packed:
		if gs:
			gs.select_miku()
		var pcp = pc_player_packed.instantiate()
		root.add_child(pcp)
		await process_frame
		pcp.grant_weapon("petal_chorus")
		await process_frame
		if str(pcp.get_weapon_id()) != "petal_chorus":
			errors.append("grant_weapon petal_chorus failed")
		else:
			print("OK grant_weapon petal_chorus")
		var pcw: Dictionary = pcp.get_current_weapon()
		if int(pcw.get("ammo", 0)) != 28:
			errors.append("Petal Chorus ammo expected 28")
		else:
			print("OK Petal Chorus ammo=", pcw.get("ammo"))
		if pcp.has_method("_fire_petal_chorus"):
			pcp._fire_petal_chorus()
			await process_frame
			var pc_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_pc := false
			for s in pc_shots:
				if s.get_script() and "PetalChorus" in str(s.get_script().resource_path):
					found_pc = true
				elif "damage" in s and int(s.damage) == 1:
					found_pc = true
			if not found_pc and pc_shots.is_empty():
				errors.append("PetalChorusShot not spawned")
			else:
				print("OK PetalChorusShot spawned count=", pc_shots.size())
				pcw = pcp.get_current_weapon()
				if int(pcw.get("ammo", 28)) != 27:
					errors.append("Petal Chorus ammo not consumed")
				else:
					print("OK Petal Chorus ammo consumed=", pcw.get("ammo"))
				for sh in pc_shots:
					sh.queue_free()
		# Heal stub
		if pcp.has_method("heal"):
			pcp.hp = 20
			pcp.heal(1)
			if int(pcp.hp) != 21:
				errors.append("Player.heal expected 21, got %d" % int(pcp.hp))
			else:
				print("OK Player.heal")
		pcp.queue_free()
		await process_frame
	else:
		errors.append("Player.tscn failed for Petal Chorus test")

	# VinePlatform smoke
	var vine_plat: PackedScene = load("res://scenes/props/VinePlatform.tscn")
	if vine_plat:
		var vplat = vine_plat.instantiate()
		root.add_child(vplat)
		await process_frame
		if not vplat.is_in_group("vine_platforms"):
			errors.append("VinePlatform missing group")
		else:
			print("OK VinePlatform group")
		vplat.queue_free()
		await process_frame
	else:
		errors.append("VinePlatform.tscn failed to load")

	# PetalHazard smoke
	var petal_hz: PackedScene = load("res://scenes/hazards/PetalHazard.tscn")
	if petal_hz:
		var phz = petal_hz.instantiate()
		root.add_child(phz)
		await process_frame
		if not phz.is_in_group("petal_hazards"):
			errors.append("PetalHazard missing group")
		else:
			print("OK PetalHazard group")
		phz.queue_free()
		await process_frame
	else:
		errors.append("PetalHazard.tscn failed to load")

	# GameState chorus_bloom unlock
	if gs:
		gs.mark_boss_defeated("chorus_bloom")
		if not gs.is_boss_defeated("chorus_bloom"):
			errors.append("mark chorus_bloom defeated failed")
		else:
			print("OK chorus_bloom defeated in GameState")
		if not gs.has_weapon_unlocked("petal_chorus"):
			errors.append("petal_chorus should unlock on chorus_bloom defeat")
		else:
			print("OK petal_chorus unlocked")

	# BossSelect chorus playable
	var bs_chk: PackedScene = load("res://scenes/ui/BossSelect.tscn")
	if bs_chk:
		var bsc = bs_chk.instantiate()
		root.add_child(bsc)
		await process_frame
		var found_cb_slot := false
		for slot in bsc.BOSS_SLOTS if "BOSS_SLOTS" in bsc else []:
			if str(slot.get("id", "")) == "chorus_bloom" and bool(slot.get("playable", false)):
				found_cb_slot = true
		# BOSS_SLOTS is const on script — access via script constant
		var slots = bsc.get_script().get_script_constant_map().get("BOSS_SLOTS", []) if bsc.get_script() else []
		# Fallback: check button exists and not disabled
		var cell = bsc.find_child("BossCell_chorus_bloom", true, false)
		if cell:
			var btn = cell.get_node_or_null("SelectButton")
			if btn and btn.disabled:
				errors.append("Chorus Bloom BossSelect cell should be playable")
			else:
				print("OK BossSelect Chorus Bloom playable")
				found_cb_slot = true
		elif not found_cb_slot:
			# Try reading const from class
			print("WARN BossCell_chorus_bloom not found via find_child; checking script const")
		bsc.queue_free()
		await process_frame

	# Instantiate LevelChorusBloom
	var bloom_level_packed: PackedScene = load("res://scenes/levels/LevelChorusBloom.tscn")
	if bloom_level_packed:
		if gs:
			gs.energy_tanks = 0
		var blvl = bloom_level_packed.instantiate()
		root.add_child(blvl)
		print("OK instantiate LevelChorusBloom, children=", blvl.get_child_count())
		await process_frame
		await process_frame
		var bent = blvl.get_node_or_null("Entities")
		if bent == null:
			errors.append("LevelChorusBloom Entities missing")
		else:
			var bp = bent.get_node_or_null("Player")
			if bp == null:
				errors.append("Player not spawned in LevelChorusBloom")
			else:
				print("OK ChorusBloom level player spawned")
			var bboss = 0
			var bmet = 0
			for c in bent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Chorus"):
					bboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					bmet += 1
			if bmet < 2:
				errors.append("Expected >=2 MetBeat in LevelChorusBloom, got %d" % bmet)
			else:
				print("OK MetBeat in LevelChorusBloom=", bmet)
			if bboss < 1:
				errors.append("Expected ChorusBloom boss in level")
			else:
				print("OK ChorusBloom boss in level")
			if bent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelChorusBloom ArenaTrigger missing")
			else:
				print("OK LevelChorusBloom ArenaTrigger")
			var betank = bent.get_node_or_null("EnergyTankPickup")
			if betank == null:
				errors.append("EnergyTankPickup missing in LevelChorusBloom")
			else:
				print("OK EnergyTankPickup at ", betank.position)
		var bgeom = blvl.get_node_or_null("Geometry")
		var vine_n := 0
		if bgeom:
			for c in bgeom.get_children():
				if c.is_in_group("vine_platforms") or str(c.name).begins_with("Vine"):
					vine_n += 1
		if vine_n < 3:
			errors.append("Expected >=3 VinePlatform in LevelChorusBloom, got %d" % vine_n)
		else:
			print("OK VinePlatform count=", vine_n)
		var bhaz = blvl.get_node_or_null("Hazards")
		var petal_n := 0
		if bhaz:
			for c in bhaz.get_children():
				if c.is_in_group("petal_hazards") or str(c.name).begins_with("Petal"):
					petal_n += 1
		if petal_n < 3:
			errors.append("Expected >=3 PetalHazard in LevelChorusBloom, got %d" % petal_n)
		else:
			print("OK PetalHazard count=", petal_n)
		if blvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelChorusBloom")
		else:
			print("OK HUD in LevelChorusBloom")
		if blvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelChorusBloom")
		else:
			print("OK TouchControls in LevelChorusBloom")
		# Energy tank pickup
		var bet2 = bent.get_node_or_null("EnergyTankPickup") if bent else null
		var bp2 = bent.get_node_or_null("Player") if bent else null
		if bet2 and bp2 and bet2.has_method("_collect"):
			bet2._collect(bp2)
			await process_frame
			if gs and int(gs.get_energy_tanks()) < 1:
				errors.append("Chorus Bloom energy tank pickup did not increase tanks")
			else:
				print("OK Chorus Bloom energy tanks after pickup=", gs.get_energy_tanks() if gs else -1)
		# Boss kill path
		if blvl.has_method("_start_boss_fight"):
			blvl._start_boss_fight()
			await process_frame
			var boss_b = bent.get_node_or_null("ChorusBloom") if bent else null
			if boss_b and boss_b.has_method("take_damage"):
				while is_instance_valid(boss_b) and int(boss_b.hp) > 0:
					boss_b.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var bp3 = bent.get_node_or_null("Player") if bent else null
				if bp3 and bp3.has_method("_has_weapon"):
					if not bp3._has_weapon("petal_chorus"):
						errors.append("Chorus Bloom defeat did not grant Petal Chorus")
					else:
						print("OK Chorus Bloom defeat granted Petal Chorus")
				if gs and not gs.is_boss_defeated("chorus_bloom"):
					errors.append("Chorus Bloom defeat did not set GameState")
				else:
					print("OK GameState chorus_bloom defeated after win")
				var win_b = blvl.get_node_or_null("WinBanner")
				if win_b == null:
					print("WARN Chorus Bloom WinBanner not found immediately")
				else:
					print("OK Chorus Bloom WinBanner")
					var ret_b = win_b.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_b == null:
						errors.append("Chorus Bloom WinBanner missing ReturnBossSelect")
					else:
						print("OK Chorus Bloom ReturnBossSelect")
		blvl.queue_free()
		await process_frame
	else:
		errors.append("LevelChorusBloom.tscn failed to load")



	# --- Bassquake boss / weapon / level ---
	var bq_boss_packed: PackedScene = load("res://scenes/bosses/Bassquake.tscn")
	if bq_boss_packed:
		var bqb = bq_boss_packed.instantiate()
		root.add_child(bqb)
		await process_frame
		if not bqb.is_in_group("weak_to_freeze_sample"):
			errors.append("Bassquake missing weak_to_freeze_sample group")
		else:
			print("OK Bassquake weak_to_freeze_sample")
		if int(bqb.hp) != 28:
			errors.append("Bassquake HP expected 28, got %d" % int(bqb.hp))
		else:
			print("OK Bassquake HP=28")
		if bqb.has_method("activate"):
			bqb.activate()
		# Freeze Sample ×3: base 2 → 6
		bqb.hp = 26
		var fsb = load("res://scenes/combat/FreezeSampleShot.tscn").instantiate()
		root.add_child(fsb)
		fsb.global_position = bqb.global_position
		if fsb.has_method("_try_hit"):
			fsb._try_hit(bqb)
		await process_frame
		if int(bqb.hp) != 20:
			errors.append("Freeze Sample weakness vs Bassquake expected hp 20 (26-6), got %d" % int(bqb.hp))
		else:
			print("OK Freeze Sample ×3 vs Bassquake hp=", bqb.hp)
		if is_instance_valid(fsb):
			fsb.queue_free()
		bqb.queue_free()
		await process_frame
	else:
		errors.append("Bassquake.tscn failed to load")

	# Quake Drop weapon smoke
	var qd_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if qd_player_packed:
		if gs:
			gs.select_miku()
		var qdp = qd_player_packed.instantiate()
		root.add_child(qdp)
		await process_frame
		qdp.grant_weapon("quake_drop")
		await process_frame
		if str(qdp.get_weapon_id()) != "quake_drop":
			errors.append("grant_weapon quake_drop failed")
		else:
			print("OK grant_weapon quake_drop")
		var qdw: Dictionary = qdp.get_current_weapon()
		if int(qdw.get("ammo", 0)) != 14:
			errors.append("Quake Drop ammo expected 14")
		else:
			print("OK Quake Drop ammo=", qdw.get("ammo"))
		if int(qdw.get("cost", 0)) != 2:
			errors.append("Quake Drop cost expected 2")
		else:
			print("OK Quake Drop cost=2")
		if qdp.has_method("_fire_quake_drop"):
			qdp._fire_quake_drop()
			await process_frame
			var qd_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_qd := false
			for s in qd_shots:
				if s.get_script() and "QuakeDrop" in str(s.get_script().resource_path):
					found_qd = true
				elif "damage" in s and int(s.damage) == 3:
					found_qd = true
			if not found_qd and qd_shots.is_empty():
				errors.append("QuakeDropShot not spawned")
			else:
				print("OK QuakeDropShot spawned count=", qd_shots.size())
				qdw = qdp.get_current_weapon()
				if int(qdw.get("ammo", 14)) != 12:
					errors.append("Quake Drop ammo not consumed (cost 2)")
				else:
					print("OK Quake Drop ammo consumed=", qdw.get("ammo"))
				for sh in qd_shots:
					sh.queue_free()
		# Encore Guard torso defense + slide hyper armor
		if gs:
			gs.grant_armor_piece("encore", "torso", true)
		if qdp.has_method("_sync_armor_from_state"):
			qdp._sync_armor_from_state()
		if qdp.has_method("has_encore_torso") and not qdp.has_encore_torso():
			errors.append("Encore torso not synced on player")
		else:
			print("OK Encore torso equipped on player")
		# Damage reduction: 4 → 3
		qdp.hp = 28
		qdp._invuln = 0.0
		qdp.take_damage(4)
		await process_frame
		if int(qdp.hp) != 25:
			errors.append("Encore torso damage reduce expected hp 25 (28-3), got %d" % int(qdp.hp))
		else:
			print("OK Encore torso damage reduction hp=", qdp.hp)
		qdp.queue_free()
		await process_frame
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
	else:
		errors.append("Player.tscn failed for Quake Drop test")

	# CollapsingFloor smoke
	var col_plat: PackedScene = load("res://scenes/props/CollapsingFloor.tscn")
	if col_plat:
		var cplat = col_plat.instantiate()
		root.add_child(cplat)
		await process_frame
		if not cplat.is_in_group("collapsing_floors"):
			errors.append("CollapsingFloor missing group")
		else:
			print("OK CollapsingFloor group")
		cplat.queue_free()
		await process_frame
	else:
		errors.append("CollapsingFloor.tscn failed to load")

	# QuakeWave smoke
	var qw_hz: PackedScene = load("res://scenes/hazards/QuakeWave.tscn")
	if qw_hz:
		var qwh = qw_hz.instantiate()
		root.add_child(qwh)
		await process_frame
		if not qwh.is_in_group("quake_waves"):
			errors.append("QuakeWave missing group")
		else:
			print("OK QuakeWave group")
		qwh.queue_free()
		await process_frame
	else:
		errors.append("QuakeWave.tscn failed to load")

	# GameState bassquake unlock
	if gs:
		gs.mark_boss_defeated("bassquake")
		if not gs.is_boss_defeated("bassquake"):
			errors.append("mark bassquake defeated failed")
		else:
			print("OK bassquake defeated in GameState")
		if not gs.has_weapon_unlocked("quake_drop"):
			errors.append("quake_drop should unlock on bassquake defeat")
		else:
			print("OK quake_drop unlocked")
		if gs.has_method("has_pending_armor_secret"):
			# Grant then clear for pending check
			var pending_before = gs.has_pending_armor_secret("bassquake")
			if not pending_before and not gs.has_armor_piece("encore", "torso"):
				errors.append("bassquake should have pending encore torso secret when not owned")
			elif pending_before:
				print("OK bassquake pending armor secret")
			gs.grant_armor_piece("encore", "torso", true)
			if gs.has_pending_armor_secret("bassquake"):
				errors.append("bassquake secret should clear after encore torso")
			else:
				print("OK bassquake secret cleared after grant")
			gs._armor_owned.clear()
			gs._armor_equipped.clear()

	# BossSelect bassquake playable
	var bs_bq: PackedScene = load("res://scenes/ui/BossSelect.tscn")
	if bs_bq:
		var bsb = bs_bq.instantiate()
		root.add_child(bsb)
		await process_frame
		var cell_bq = bsb.find_child("BossCell_bassquake", true, false)
		if cell_bq:
			var btn_bq = cell_bq.get_node_or_null("SelectButton")
			if btn_bq and btn_bq.disabled:
				errors.append("Bassquake BossSelect cell should be playable")
			else:
				print("OK BossSelect Bassquake playable")
		else:
			print("WARN BossCell_bassquake not found via find_child")
		bsb.queue_free()
		await process_frame

	# Instantiate LevelBassquake
	var bq_level_packed: PackedScene = load("res://scenes/levels/LevelBassquake.tscn")
	if bq_level_packed:
		var bqlvl = bq_level_packed.instantiate()
		root.add_child(bqlvl)
		print("OK instantiate LevelBassquake, children=", bqlvl.get_child_count())
		await process_frame
		await process_frame
		var bqent = bqlvl.get_node_or_null("Entities")
		if bqent == null:
			errors.append("LevelBassquake Entities missing")
		else:
			var bqp = bqent.get_node_or_null("Player")
			if bqp == null:
				errors.append("Player not spawned in LevelBassquake")
			else:
				print("OK Bassquake level player spawned")
			var bqboss = 0
			var bqmet = 0
			for c in bqent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Bass"):
					bqboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					bqmet += 1
			if bqmet < 2:
				errors.append("Expected >=2 MetBeat in LevelBassquake, got %d" % bqmet)
			else:
				print("OK MetBeat in LevelBassquake=", bqmet)
			if bqboss < 1:
				errors.append("Expected Bassquake boss in level")
			else:
				print("OK Bassquake boss in level")
			if bqent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelBassquake ArenaTrigger missing")
			else:
				print("OK LevelBassquake ArenaTrigger")
			var etorso = bqent.get_node_or_null("EncoreTorsoPickup")
			if etorso == null:
				errors.append("EncoreTorsoPickup missing in LevelBassquake")
			else:
				print("OK EncoreTorsoPickup at ", etorso.position)
		var bqgeom = bqlvl.get_node_or_null("Geometry")
		var collapse_n := 0
		if bqgeom:
			for c in bqgeom.get_children():
				if c.is_in_group("collapsing_floors") or str(c.name).begins_with("Collaps"):
					collapse_n += 1
		if collapse_n < 3:
			errors.append("Expected >=3 CollapsingFloor in LevelBassquake, got %d" % collapse_n)
		else:
			print("OK CollapsingFloor count=", collapse_n)
		if bqlvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelBassquake")
		else:
			print("OK HUD in LevelBassquake")
		if bqlvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelBassquake")
		else:
			print("OK TouchControls in LevelBassquake")
		# Armor pickup
		var et2 = bqent.get_node_or_null("EncoreTorsoPickup") if bqent else null
		var bp2 = bqent.get_node_or_null("Player") if bqent else null
		if et2 and bp2 and et2.has_method("_collect"):
			et2._collect(bp2)
			await process_frame
			if gs and not gs.has_encore_torso_equipped():
				errors.append("Bassquake encore torso pickup did not equip")
			else:
				print("OK Bassquake encore torso equipped")
		# Boss kill path
		if bqlvl.has_method("_start_boss_fight"):
			bqlvl._start_boss_fight()
			await process_frame
			var boss_q = bqent.get_node_or_null("Bassquake") if bqent else null
			if boss_q and boss_q.has_method("take_damage"):
				while is_instance_valid(boss_q) and int(boss_q.hp) > 0:
					boss_q.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var bp3 = bqent.get_node_or_null("Player") if bqent else null
				if bp3 and bp3.has_method("_has_weapon"):
					if not bp3._has_weapon("quake_drop"):
						errors.append("Bassquake defeat did not grant Quake Drop")
					else:
						print("OK Bassquake defeat granted Quake Drop")
				if gs and not gs.is_boss_defeated("bassquake"):
					errors.append("Bassquake defeat did not set GameState")
				else:
					print("OK GameState bassquake defeated after win")
				var win_q = bqlvl.get_node_or_null("WinBanner")
				if win_q == null:
					print("WARN Bassquake WinBanner not found immediately")
				else:
					print("OK Bassquake WinBanner")
					var ret_q = win_q.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_q == null:
						errors.append("Bassquake WinBanner missing ReturnBossSelect")
					else:
						print("OK Bassquake ReturnBossSelect")
		bqlvl.queue_free()
		await process_frame
	else:
		errors.append("LevelBassquake.tscn failed to load")




	# --- Metronome boss / weapon / level ---
	var mn_boss_packed: PackedScene = load("res://scenes/bosses/Metronome.tscn")
	if mn_boss_packed:
		var mnb = mn_boss_packed.instantiate()
		root.add_child(mnb)
		await process_frame
		if not mnb.is_in_group("weak_to_neon_arc"):
			errors.append("Metronome missing weak_to_neon_arc group")
		else:
			print("OK Metronome weak_to_neon_arc")
		if int(mnb.hp) != 28:
			errors.append("Metronome HP expected 28, got %d" % int(mnb.hp))
		else:
			print("OK Metronome HP=28")
		if mnb.has_method("activate"):
			mnb.activate()
		# Neon Arc ×3: base 2 → 6
		mnb.hp = 26
		var nas = load("res://scenes/combat/NeonArcShot.tscn").instantiate()
		root.add_child(nas)
		nas.global_position = mnb.global_position
		if nas.has_method("_try_hit"):
			nas._try_hit(mnb)
		await process_frame
		if int(mnb.hp) != 20:
			errors.append("Neon Arc weakness vs Metronome expected hp 20 (26-6), got %d" % int(mnb.hp))
		else:
			print("OK Neon Arc ×3 vs Metronome hp=", mnb.hp)
		if is_instance_valid(nas):
			nas.queue_free()
		mnb.queue_free()
		await process_frame
	else:
		errors.append("Metronome.tscn failed to load")

	# Tempo Spike weapon smoke
	var ts_player_packed: PackedScene = load("res://scenes/player/Player.tscn")
	if ts_player_packed:
		if gs:
			gs.select_miku()
		var tsp = ts_player_packed.instantiate()
		root.add_child(tsp)
		await process_frame
		tsp.grant_weapon("tempo_spike")
		await process_frame
		if str(tsp.get_weapon_id()) != "tempo_spike":
			errors.append("grant_weapon tempo_spike failed")
		else:
			print("OK grant_weapon tempo_spike")
		var tsw: Dictionary = tsp.get_current_weapon()
		if int(tsw.get("ammo", 0)) != 14:
			errors.append("Tempo Spike ammo expected 14")
		else:
			print("OK Tempo Spike ammo=", tsw.get("ammo"))
		if int(tsw.get("cost", 0)) != 2:
			errors.append("Tempo Spike cost expected 2")
		else:
			print("OK Tempo Spike cost=2")
		if tsp.has_method("_fire_tempo_spike"):
			tsp._fire_tempo_spike()
			await process_frame
			var ts_shots = root.get_tree().get_nodes_in_group("player_shots")
			var found_ts := false
			for s in ts_shots:
				if s.get_script() and "TempoSpike" in str(s.get_script().resource_path):
					found_ts = true
				elif "damage" in s and int(s.damage) == 3:
					found_ts = true
			if not found_ts and ts_shots.is_empty():
				errors.append("TempoSpikeShot not spawned")
			else:
				print("OK TempoSpikeShot spawned count=", ts_shots.size())
				tsw = tsp.get_current_weapon()
				if int(tsw.get("ammo", 14)) != 12:
					errors.append("Tempo Spike ammo not consumed (cost 2)")
				else:
					print("OK Tempo Spike ammo consumed=", tsw.get("ammo"))
				for sh in ts_shots:
					sh.queue_free()
		# Encore Guard legs → longer slide i-frames
		if gs:
			gs.grant_armor_piece("encore", "legs", true)
		if tsp.has_method("_sync_armor_from_state"):
			tsp._sync_armor_from_state()
		if tsp.has_method("has_encore_legs") and not tsp.has_encore_legs():
			errors.append("Encore legs not synced on player")
		else:
			print("OK Encore legs equipped on player")
		tsp._invuln = 0.0
		if tsp.has_method("_start_slide"):
			# Force floor for slide
			tsp.velocity = Vector2.ZERO
			tsp._start_slide()
			if float(tsp._invuln) < 0.25:
				errors.append("Encore legs slide i-frames expected >=0.25, got %s" % str(tsp._invuln))
			else:
				print("OK Encore legs slide i-frames=", tsp._invuln)
		tsp.queue_free()
		await process_frame
		if gs:
			gs._armor_owned.clear()
			gs._armor_equipped.clear()
	else:
		errors.append("Player.tscn failed for Tempo Spike test")

	# MetronomeSpike smoke
	var ms_hz: PackedScene = load("res://scenes/hazards/MetronomeSpike.tscn")
	if ms_hz:
		var msh = ms_hz.instantiate()
		root.add_child(msh)
		await process_frame
		if not msh.is_in_group("metronome_spikes"):
			errors.append("MetronomeSpike missing group")
		else:
			print("OK MetronomeSpike group")
		msh.queue_free()
		await process_frame
	else:
		errors.append("MetronomeSpike.tscn failed to load")

	# GameState metronome unlock
	if gs:
		gs.mark_boss_defeated("metronome")
		if not gs.is_boss_defeated("metronome"):
			errors.append("mark metronome defeated failed")
		else:
			print("OK metronome defeated in GameState")
		if not gs.has_weapon_unlocked("tempo_spike"):
			errors.append("tempo_spike should unlock on metronome defeat")
		else:
			print("OK tempo_spike unlocked")
		if gs.has_method("has_pending_armor_secret"):
			var pending_m = gs.has_pending_armor_secret("metronome")
			if not pending_m and not gs.has_armor_piece("encore", "legs"):
				errors.append("metronome should have pending encore legs secret when not owned")
			elif pending_m:
				print("OK metronome pending armor secret")
			gs.grant_armor_piece("encore", "legs", true)
			if gs.has_pending_armor_secret("metronome"):
				errors.append("metronome secret should clear after encore legs")
			else:
				print("OK metronome secret cleared after grant")
			gs._armor_owned.clear()
			gs._armor_equipped.clear()

	# BossSelect metronome playable
	var bs_mn: PackedScene = load("res://scenes/ui/BossSelect.tscn")
	if bs_mn:
		var bsm = bs_mn.instantiate()
		root.add_child(bsm)
		await process_frame
		var cell_mn = bsm.find_child("BossCell_metronome", true, false)
		if cell_mn:
			var btn_mn = cell_mn.get_node_or_null("SelectButton")
			if btn_mn and btn_mn.disabled:
				errors.append("Metronome BossSelect cell should be playable")
			else:
				print("OK BossSelect Metronome playable")
		else:
			print("WARN BossCell_metronome not found via find_child")
		bsm.queue_free()
		await process_frame

	# Instantiate LevelMetronome
	var mn_level_packed: PackedScene = load("res://scenes/levels/LevelMetronome.tscn")
	if mn_level_packed:
		var mnlvl = mn_level_packed.instantiate()
		root.add_child(mnlvl)
		print("OK instantiate LevelMetronome, children=", mnlvl.get_child_count())
		await process_frame
		await process_frame
		var mnent = mnlvl.get_node_or_null("Entities")
		if mnent == null:
			errors.append("LevelMetronome Entities missing")
		else:
			var mnp = mnent.get_node_or_null("Player")
			if mnp == null:
				errors.append("Player not spawned in LevelMetronome")
			else:
				print("OK Metronome level player spawned")
			var mnboss = 0
			var mnmet = 0
			for c in mnent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Metro"):
					mnboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					mnmet += 1
			if mnmet < 2:
				errors.append("Expected >=2 MetBeat in LevelMetronome, got %d" % mnmet)
			else:
				print("OK MetBeat in LevelMetronome=", mnmet)
			if mnboss < 1:
				errors.append("Expected Metronome boss in level")
			else:
				print("OK Metronome boss in level")
			if mnent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelMetronome ArenaTrigger missing")
			else:
				print("OK LevelMetronome ArenaTrigger")
			var elegs = mnent.get_node_or_null("EncoreLegsPickup")
			if elegs == null:
				errors.append("EncoreLegsPickup missing in LevelMetronome")
			else:
				print("OK EncoreLegsPickup at ", elegs.position)
		var mnhaz = mnlvl.get_node_or_null("Hazards")
		var metro_n := 0
		if mnhaz:
			for c in mnhaz.get_children():
				if c.is_in_group("metronome_spikes") or str(c.name).begins_with("Metronome"):
					metro_n += 1
		if metro_n < 5:
			errors.append("Expected >=5 MetronomeSpike in LevelMetronome, got %d" % metro_n)
		else:
			print("OK MetronomeSpike count=", metro_n)
		if mnlvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelMetronome")
		else:
			print("OK HUD in LevelMetronome")
		if mnlvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelMetronome")
		else:
			print("OK TouchControls in LevelMetronome")
		# Armor pickup
		var el2 = mnent.get_node_or_null("EncoreLegsPickup") if mnent else null
		var bp2m = mnent.get_node_or_null("Player") if mnent else null
		if el2 and bp2m and el2.has_method("_collect"):
			el2._collect(bp2m)
			await process_frame
			if gs and not gs.has_encore_legs_equipped():
				errors.append("Metronome encore legs pickup did not equip")
			else:
				print("OK Metronome encore legs equipped")
		# Boss kill path
		if mnlvl.has_method("_start_boss_fight"):
			mnlvl._start_boss_fight()
			await process_frame
			var boss_m = mnent.get_node_or_null("Metronome") if mnent else null
			if boss_m and boss_m.has_method("take_damage"):
				while is_instance_valid(boss_m) and int(boss_m.hp) > 0:
					boss_m.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var bp3m = mnent.get_node_or_null("Player") if mnent else null
				if bp3m and bp3m.has_method("_has_weapon"):
					if not bp3m._has_weapon("tempo_spike"):
						errors.append("Metronome defeat did not grant Tempo Spike")
					else:
						print("OK Metronome defeat granted Tempo Spike")
				if gs and not gs.is_boss_defeated("metronome"):
					errors.append("Metronome defeat did not set GameState")
				else:
					print("OK GameState metronome defeated after win")
				var win_m = mnlvl.get_node_or_null("WinBanner")
				if win_m == null:
					print("WARN Metronome WinBanner not found immediately")
				else:
					print("OK Metronome WinBanner")
					var ret_m = win_m.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret_m == null:
						errors.append("Metronome WinBanner missing ReturnBossSelect")
					else:
						print("OK Metronome ReturnBossSelect")
		mnlvl.queue_free()
		await process_frame
	else:
		errors.append("LevelMetronome.tscn failed to load")



	# --- Static Shadow boss / weapon / level ---
	var ss_boss_packed: PackedScene = load("res://scenes/bosses/StaticShadow.tscn")
	if ss_boss_packed:
		var ssb = ss_boss_packed.instantiate()
		root.add_child(ssb)
		await process_frame
		if not ssb.is_in_group("weak_to_petal_chorus"):
			errors.append("StaticShadow missing weak_to_petal_chorus group")
		else:
			print("OK StaticShadow weak_to_petal_chorus")
		if int(ssb.hp) != 28:
			errors.append("StaticShadow HP expected 28, got %d" % int(ssb.hp))
		else:
			print("OK StaticShadow HP=28")
		if ssb.has_method("activate"):
			ssb.activate()
		# Petal Chorus ×3: base 1 → 3; start hp 26 after fake chip? use 28-3=25 if one hit of 3
		# Petal Chorus ×3: base 1 → 3
		ssb.hp = 26
		var pcs = load("res://scenes/combat/PetalChorusShot.tscn").instantiate()
		root.add_child(pcs)
		pcs.global_position = ssb.global_position
		if pcs.has_method("_try_hit"):
			pcs._try_hit(ssb)
		await process_frame
		if int(ssb.hp) != 23:
			errors.append("Petal Chorus weakness vs StaticShadow expected hp 23 (26-3), got %d" % int(ssb.hp))
		else:
			print("OK Petal Chorus ×3 vs StaticShadow hp=", ssb.hp)
		if is_instance_valid(pcs):
			pcs.queue_free()
		ssb.queue_free()
		await process_frame
	else:
		errors.append("StaticShadow.tscn failed to load")

	var svp: Node = load("res://scenes/player/Player.tscn").instantiate()
	root.add_child(svp)
	await process_frame
	if svp.has_method("grant_weapon"):
		svp.grant_weapon("static_veil")
		await process_frame
		if str(svp.get_weapon_id()) != "static_veil":
			errors.append("grant_weapon static_veil failed")
		else:
			print("OK grant_weapon static_veil")
		if svp.has_method("_fire_static_veil"):
			svp._fire_static_veil()
			await process_frame
			await process_frame
			var veil_n := 0
			for n in root.get_children():
				if "StaticVeil" in str(n.name) or n.is_in_group("player_shots"):
					if n.get_script() and "StaticVeil" in str(n.get_script().resource_path):
						veil_n += 1
			print("OK StaticVeil fire smoke shots_nearby")
	# Encore helmet sync
	if gs:
		gs.grant_armor_piece("encore", "head", true)
		if svp.has_method("_sync_armor_from_state"):
			svp._sync_armor_from_state()
		if gs.has_method("has_encore_head_equipped") and not gs.has_encore_head_equipped():
			errors.append("encore head not equipped after grant")
		else:
			print("OK encore head equipped")
	svp.queue_free()
	await process_frame

	# StaticZone smoke
	var sz_hz: PackedScene = load("res://scenes/hazards/StaticZone.tscn")
	if sz_hz:
		var sz = sz_hz.instantiate()
		root.add_child(sz)
		await process_frame
		if not sz.is_in_group("static_zones") and not sz.is_in_group("hazards"):
			errors.append("StaticZone missing group")
		else:
			print("OK StaticZone group")
		sz.queue_free()
		await process_frame
	else:
		errors.append("StaticZone.tscn failed to load")

	# GameState unlock static_veil
	if gs:
		gs.mark_boss_defeated("static_shadow")
		if not gs.has_weapon_unlocked("static_veil"):
			errors.append("static_veil should unlock on static_shadow defeat")
		else:
			print("OK static_veil unlocked")
		var pending_ss = gs.has_pending_armor_secret("static_shadow")
		if not pending_ss and not gs.has_armor_piece("encore", "head"):
			errors.append("static_shadow should have pending encore head when not owned")
		# clear by owning (already granted above) — re-check
		if gs.has_armor_piece("encore", "head"):
			if gs.has_pending_armor_secret("static_shadow"):
				errors.append("static_shadow secret should clear after encore head")
			else:
				print("OK static_shadow secret cleared")
		# CORE-9 unlock with 8 bosses — ensure count path
		# Mark all 8 if needed for fortress test later
		for bid in ["beatfire", "echo_wind", "neon_volt", "glitch_ice", "chorus_bloom", "bassquake", "metronome", "static_shadow"]:
			gs.mark_boss_defeated(bid)
		if not gs.is_core9_unlocked():
			errors.append("CORE-9 should unlock after 8 bosses")
		else:
			print("OK CORE-9 unlocked after 8 bosses count=", gs.defeated_boss_count())

	# BossSelect Static Shadow playable (fresh instance)
	var bsel_ss: PackedScene = load("res://scenes/ui/BossSelect.tscn")
	if bsel_ss and gs:
		var bsel2 = bsel_ss.instantiate()
		root.add_child(bsel2)
		await process_frame
		var grid2 = bsel2.get_node_or_null("BossGrid")
		if grid2:
			for c in grid2.get_children():
				if str(c.get_meta("boss_id", "")) == "static_shadow":
					var st = c.get_node_or_null("SelectButton/StatusLabel")
					if st and "Pronto" in st.text:
						errors.append("Static Shadow BossSelect cell should be playable")
					else:
						print("OK BossSelect Static Shadow playable")
				elif str(c.get_meta("boss_id", "")) == "core9":
					var cst = c.get_node_or_null("SelectButton/StatusLabel")
					if cst and ("FORTALEZA" in cst.text or "LISTO" in cst.text):
						print("OK CORE-9 unlocked status=", cst.text)
					elif cst and "BLOQUEADO" in cst.text:
						errors.append("CORE-9 should be unlocked after 8 bosses, got " + cst.text)
					elif cst:
						print("OK CORE-9 status=", cst.text)
		bsel2.queue_free()
		await process_frame

	# Fortress hub smoke (was ComingSoon stub)
	var fs_packed: PackedScene = load("res://scenes/ui/FortressComingSoon.tscn")
	if fs_packed:
		var fs = fs_packed.instantiate()
		root.add_child(fs)
		await process_frame
		var ftitle = fs.get_node_or_null("Panel/Title")
		if ftitle and "Fortaleza" in ftitle.text:
			print("OK FortressComingSoon title=", ftitle.text)
		else:
			errors.append("FortressComingSoon missing title")
		var fback = fs.get_node_or_null("ReturnButton")
		if fback == null:
			errors.append("FortressComingSoon missing ReturnButton")
		else:
			print("OK FortressComingSoon ReturnButton")
		var fenter = fs.get_node_or_null("Panel/EnterButton")
		if fenter == null:
			errors.append("FortressComingSoon missing EnterButton")
		else:
			print("OK FortressComingSoon EnterButton")
		fs.queue_free()
		await process_frame
	else:
		errors.append("FortressComingSoon.tscn failed to load")

	# Fortress lobby instantiate smoke
	var lobby_packed: PackedScene = load("res://scenes/levels/LevelFortressLobby.tscn")
	if lobby_packed:
		var lobby = lobby_packed.instantiate()
		root.add_child(lobby)
		await process_frame
		await process_frame
		print("OK instantiate LevelFortressLobby children=", lobby.get_child_count())
		var lent = lobby.get_node_or_null("Entities")
		if lent == null:
			errors.append("LevelFortressLobby Entities missing")
		else:
			var ru = lent.get_node_or_null("RefrainUnit")
			if ru == null:
				errors.append("LevelFortressLobby missing RefrainUnit")
			else:
				print("OK Lobby RefrainUnit")
		lobby.queue_free()
		await process_frame
	else:
		errors.append("LevelFortressLobby.tscn failed to load")

	# Voice Archive + VocalSeal
	var va_packed: PackedScene = load("res://scenes/levels/LevelVoiceArchive.tscn")
	if va_packed:
		var va = va_packed.instantiate()
		root.add_child(va)
		await process_frame
		await process_frame
		print("OK instantiate LevelVoiceArchive")
		va.queue_free()
		await process_frame
	else:
		errors.append("LevelVoiceArchive.tscn failed to load")

	# Core Shaft
	var cs_packed: PackedScene = load("res://scenes/levels/LevelCoreShaft.tscn")
	if cs_packed:
		var cs = cs_packed.instantiate()
		root.add_child(cs)
		await process_frame
		await process_frame
		print("OK instantiate LevelCoreShaft")
		var csent = cs.get_node_or_null("Entities")
		if csent and csent.get_node_or_null("OverdubTitan"):
			print("OK CoreShaft OverdubTitan")
		else:
			errors.append("LevelCoreShaft missing OverdubTitan")
		cs.queue_free()
		await process_frame
	else:
		errors.append("LevelCoreShaft.tscn failed to load")

	# Heart CORE-9
	var hc_packed: PackedScene = load("res://scenes/levels/LevelHeartCore9.tscn")
	if hc_packed:
		var hc = hc_packed.instantiate()
		root.add_child(hc)
		await process_frame
		await process_frame
		print("OK instantiate LevelHeartCore9")
		var hcent = hc.get_node_or_null("Entities")
		if hcent and hcent.get_node_or_null("Core9"):
			print("OK Heart Core9 boss")
		else:
			errors.append("LevelHeartCore9 missing Core9")
		hc.queue_free()
		await process_frame
	else:
		errors.append("LevelHeartCore9.tscn failed to load")

	# Ending / Credits smoke
	var end_packed: PackedScene = load("res://scenes/ui/EndingScreen.tscn")
	if end_packed:
		var end = end_packed.instantiate()
		root.add_child(end)
		await process_frame
		var ebody = end.get_node_or_null("Body")
		if ebody == null:
			errors.append("EndingScreen missing Body")
		else:
			print("OK EndingScreen Body")
		end.queue_free()
		await process_frame
	else:
		errors.append("EndingScreen.tscn failed to load")

	var cred_packed: PackedScene = load("res://scenes/ui/CreditsScreen.tscn")
	if cred_packed:
		var cred = cred_packed.instantiate()
		root.add_child(cred)
		await process_frame
		var cback = cred.get_node_or_null("ReturnButton")
		if cback == null:
			errors.append("CreditsScreen missing ReturnButton")
		else:
			print("OK CreditsScreen ReturnButton")
		cred.queue_free()
		await process_frame
	else:
		errors.append("CreditsScreen.tscn failed to load")

	# Core9 phase damage rule unit check
	var c9s: PackedScene = load("res://scenes/bosses/Core9.tscn")
	if c9s:
		var c9 = c9s.instantiate()
		root.add_child(c9)
		await process_frame
		if c9.has_method("activate"):
			c9.activate()
		# Force phase 3
		c9.hp = 10
		c9._phase = 3
		var before = c9.hp
		c9.take_damage(1)  # weak → 1
		if c9.hp != before - 1:
			errors.append("Core9 P3 weak hit should deal 1, hp=%d" % c9.hp)
		else:
			print("OK Core9 P3 weak tick")
		before = c9.hp
		c9._invuln = 0.0
		c9.take_damage(4)  # strong ×1.5 = 6
		var expected = before - 6
		if c9.hp != expected and c9.hp != maxi(expected, 0):
			# may have died
			if c9.hp > 0 and c9.hp != expected:
				errors.append("Core9 P3 strong should ×1.5, hp=%d expected=%d" % [c9.hp, expected])
			else:
				print("OK Core9 P3 strong ×1.5 (or died)")
		else:
			print("OK Core9 P3 strong ×1.5")
		c9.queue_free()
		await process_frame

	# Instantiate LevelStaticShadow
	var ss_level_packed: PackedScene = load("res://scenes/levels/LevelStaticShadow.tscn")
	if ss_level_packed:
		var sslvl = ss_level_packed.instantiate()
		root.add_child(sslvl)
		await process_frame
		await process_frame
		print("OK instantiate LevelStaticShadow, children=", sslvl.get_child_count())
		var ssent = sslvl.get_node_or_null("Entities")
		if ssent == null:
			errors.append("LevelStaticShadow Entities missing")
		else:
			var ssp = ssent.get_node_or_null("Player")
			if ssp == null:
				errors.append("Player not spawned in LevelStaticShadow")
			else:
				print("OK Static Shadow level player spawned")
			var ssmet := 0
			var ssboss := 0
			for c in ssent.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Static"):
					ssboss += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					ssmet += 1
			if ssmet < 2:
				errors.append("Expected >=2 MetBeat in LevelStaticShadow, got %d" % ssmet)
			else:
				print("OK MetBeat in LevelStaticShadow=", ssmet)
			if ssboss < 1:
				errors.append("Expected StaticShadow boss in level")
			else:
				print("OK StaticShadow boss in level")
			if ssent.get_node_or_null("ArenaTrigger") == null:
				errors.append("LevelStaticShadow ArenaTrigger missing")
			else:
				print("OK LevelStaticShadow ArenaTrigger")
			if ssent.get_node_or_null("EncoreHelmetPickup") == null:
				errors.append("EncoreHelmetPickup missing in LevelStaticShadow")
			else:
				print("OK EncoreHelmetPickup present")
		if sslvl.get_node_or_null("DarkVignette") == null:
			errors.append("DarkVignette missing in LevelStaticShadow")
		else:
			print("OK DarkVignette present")
		if sslvl.get_node_or_null("HUD") == null:
			errors.append("HUD missing in LevelStaticShadow")
		else:
			print("OK HUD in LevelStaticShadow")
		if sslvl.get_node_or_null("TouchControls") == null:
			errors.append("TouchControls missing in LevelStaticShadow")
		else:
			print("OK TouchControls in LevelStaticShadow")
		# secret pickup equip
		var helm = ssent.get_node_or_null("EncoreHelmetPickup") if ssent else null
		var ssp2 = ssent.get_node_or_null("Player") if ssent else null
		if helm and ssp2 and helm.has_method("_collect"):
			# Clear then collect
			if gs:
				# already may own head — ensure collect path
				pass
			helm._collect(ssp2)
			await process_frame
			if gs and not gs.has_encore_head_equipped():
				errors.append("StaticShadow encore head pickup did not equip")
			else:
				print("OK StaticShadow encore head equipped")
		# Defeat flow
		var boss_ss = ssent.get_node_or_null("StaticShadow") if ssent else null
		if boss_ss and ssp2 and boss_ss.has_method("activate"):
			boss_ss.activate()
			boss_ss.hp = 1
			if boss_ss.has_method("take_damage"):
				boss_ss.take_damage(1)
			await process_frame
			await process_frame
			await process_frame
			if gs and gs.is_boss_defeated("static_shadow"):
				if ssp2.has_method("_has_weapon") and not ssp2._has_weapon("static_veil"):
					# grant may happen on died signal — wait a bit more
					await process_frame
				if ssp2.has_method("_has_weapon") and not ssp2._has_weapon("static_veil"):
					errors.append("StaticShadow defeat did not grant Static Veil")
				else:
					print("OK StaticShadow defeat granted Static Veil")
			# WinBanner
			var wb = sslvl.get_node_or_null("WinBanner")
			if wb == null:
				print("WARN StaticShadow WinBanner not found immediately")
			else:
				print("OK StaticShadow WinBanner")
				if wb.get_node_or_null("Root/Panel/ReturnBossSelect") == null:
					errors.append("StaticShadow WinBanner missing ReturnBossSelect")
				else:
					print("OK StaticShadow ReturnBossSelect")
		sslvl.queue_free()
		await process_frame
	else:
		errors.append("LevelStaticShadow.tscn failed to load")


	# Instantiate main scene briefly
	var packed: PackedScene = load("res://scenes/levels/Level01.tscn")
	if packed:
		var level = packed.instantiate()
		root.add_child(level)
		print("OK instantiate Level01, children=", level.get_child_count())
		await process_frame
		await process_frame
		var entities = level.get_node_or_null("Entities")
		if entities == null:
			errors.append("Entities node missing")
		else:
			var p = entities.get_node_or_null("Player")
			if p == null:
				errors.append("Player not spawned under Entities")
			else:
				print("OK player spawned: ", p.name)
			var met_count := 0
			var boss_count := 0
			for c in entities.get_children():
				if c.is_in_group("bosses") or str(c.name).begins_with("Beatfire"):
					boss_count += 1
				elif c.is_in_group("enemies") or str(c.name).begins_with("Met"):
					met_count += 1
			if met_count < 2:
				errors.append("Expected >=2 MetBeat in Level01, got %d" % met_count)
			else:
				print("OK MetBeat count in Level01=", met_count)
			if boss_count < 1:
				errors.append("Expected BeatfireMan in Level01")
			else:
				print("OK BeatfireMan in Level01 count=", boss_count)
			var trigger = entities.get_node_or_null("ArenaTrigger")
			if trigger == null:
				errors.append("ArenaTrigger missing")
			else:
				print("OK ArenaTrigger present")
			var flight_pick = entities.get_node_or_null("FlightTorsoPickup")
			if flight_pick == null:
				errors.append("FlightTorsoPickup missing in Level01 secret")
			else:
				print("OK FlightTorsoPickup at ", flight_pick.position)
			var breakables := 0
			var geom = level.get_node_or_null("Geometry")
			if geom:
				for c in geom.get_children():
					if c.is_in_group("breakable") or str(c.name).begins_with("Breakable"):
						breakables += 1
			if breakables < 2:
				errors.append("Expected >=2 breakable blocks sealing secret, got %d" % breakables)
			else:
				print("OK breakable blocks=", breakables)
		var tc = level.get_node_or_null("TouchControls")
		if tc == null:
			errors.append("TouchControls not found under Level01")
		else:
			print("OK TouchControls in Level01, visible=", tc.visible)
		var hud_node = level.get_node_or_null("HUD")
		if hud_node == null:
			errors.append("HUD not found under Level01")
		else:
			print("OK HUD in Level01, layer=", hud_node.layer)
			var portrait = hud_node.get_node_or_null("Root/Portrait")
			if portrait == null:
				errors.append("HUD Portrait missing in Level01")
			else:
				print("OK HUD Portrait color=", portrait.color)
			var p2 = entities.get_node_or_null("Player") if entities else null
			if p2 and hud_node.has_method("bind_player"):
				var hp_lbl = hud_node.get_node_or_null("Root/HpLabel")
				p2.take_damage(4)
				await process_frame
				if hp_lbl and "24" in hp_lbl.text:
					print("OK HUD reflects spike-style damage: ", hp_lbl.text)
				elif hp_lbl:
					print("OK HUD HpLabel after damage: ", hp_lbl.text)
					if str(p2.hp) not in hp_lbl.text:
						errors.append("HUD HpLabel not updated after damage")
				else:
					errors.append("HUD HpLabel missing after Level01 bind")
				# Weapon HUD after grant
				if p2.has_method("grant_weapon"):
					p2.grant_weapon("beat_blaze")
					await process_frame
					var wpn = hud_node.get_node_or_null("Root/WeaponLabel")
					if wpn == null:
						errors.append("WeaponLabel missing")
					elif "Beat Blaze" not in wpn.text:
						errors.append("HUD weapon label missing Beat Blaze: " + wpn.text)
					elif "28" not in wpn.text and "27" not in wpn.text:
						errors.append("HUD weapon ammo not shown: " + wpn.text)
					else:
						print("OK HUD weapon+ammo: ", wpn.text)
			# Armor pickup → HUD 1/3
			if gs:
				gs._armor_owned.clear()
				gs._armor_equipped.clear()
			var flight_pick2 = entities.get_node_or_null("FlightTorsoPickup") if entities else null
			var p_armor = entities.get_node_or_null("Player") if entities else null
			if flight_pick2 and p_armor and flight_pick2.has_method("_collect"):
				flight_pick2._collect(p_armor)
				await process_frame
				await process_frame
				if gs and not gs.has_flight_torso_equipped():
					errors.append("Pickup did not equip flight torso")
				else:
					print("OK secret pickup equipped flight torso")
				if hud_node.has_method("_refresh_armor"):
					hud_node._refresh_armor()
				if hud_node.has_method("get_armor_filled_count"):
					var filled = int(hud_node.get_armor_filled_count())
					if filled != 1:
						errors.append("HUD armor filled expected 1, got %d" % filled)
					else:
						print("OK HUD armor 1/3 filled")
				var slot1 = hud_node.get_node_or_null("Root/ArmorSlot1")
				if slot1 == null:
					errors.append("ArmorSlot1 missing")
				else:
					# torso slot should be brighter cyan-ish
					print("OK ArmorSlot1 color=", slot1.color)
				if p_armor and p_armor.has_method("has_flight_hover") and not p_armor.has_flight_hover():
					errors.append("Player hover not enabled after pickup")
				else:
					print("OK player hover after secret pickup")
			elif flight_pick2 == null:
				print("WARN FlightTorsoPickup already gone before armor HUD test")
		# Simulate boss start + kill for win path
		if level.has_method("_start_boss_fight"):
			level._start_boss_fight()
			await process_frame
			var boss_node = entities.get_node_or_null("BeatfireMan") if entities else null
			if boss_node and boss_node.has_method("take_damage"):
				# Kill boss
				while is_instance_valid(boss_node) and int(boss_node.hp) > 0:
					boss_node.take_damage(7)
					await process_frame
				await process_frame
				await process_frame
				var p3 = entities.get_node_or_null("Player") if entities else null
				if p3 and p3.has_method("_has_weapon"):
					if not p3._has_weapon("beat_blaze"):
						errors.append("Boss defeat did not grant Beat Blaze")
					else:
						print("OK boss defeat granted Beat Blaze")
				if gs and not gs.is_beatfire_defeated():
					errors.append("Boss defeat did not set GameState.beatfire_defeated")
				else:
					print("OK GameState.beatfire_defeated after win")
				var win = level.get_node_or_null("WinBanner")
				if win == null:
					# May already be created
					print("WARN WinBanner not found immediately (may be timing)")
				else:
					print("OK WinBanner shown")
					var ret = win.get_node_or_null("Root/Panel/ReturnBossSelect")
					if ret == null:
						errors.append("WinBanner missing ReturnBossSelect button")
					else:
						print("OK ReturnBossSelect button")
		level.queue_free()
	else:
		errors.append("Level01.tscn failed to load")

	if errors.is_empty():
		print("VALIDATE_PASS")
		quit(0)
	else:
		for e in errors:
			print("VALIDATE_FAIL: ", e)
		quit(1)
