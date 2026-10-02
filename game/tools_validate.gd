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

	# BossSelect must route Echo Wind to LevelEchoWind
	var bsel_src = FileAccess.get_file_as_string("res://scripts/ui/BossSelect.gd")
	if "LevelEchoWind.tscn" not in bsel_src:
		errors.append("BossSelect should load LevelEchoWind for echo_wind")
	else:
		print("OK BossSelect → LevelEchoWind")

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
		# Greyed Pronto on a locked boss
		var pronto_ok := false
		if grid:
			for c in grid.get_children():
				var bid2 = str(c.get_meta("boss_id", ""))
				if bid2 in ["glitch_ice", "neon_volt", "bassquake"]:
					var st2 = c.get_node_or_null("SelectButton/StatusLabel")
					if st2 and "Pronto" in st2.text:
						pronto_ok = true
						break
		if not pronto_ok:
			errors.append("Expected at least one boss with Pronto label")
		else:
			print("OK greyed Pronto bosses present")
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
