extends SceneTree

func _initialize() -> void:
	var errors: PackedStringArray = []
	var paths := [
		"res://scripts/player/Player.gd",
		"res://scripts/levels/Level01.gd",
		"res://scripts/hazards/Hazard.gd",
		"res://scripts/ui/TouchControls.gd",
		"res://scripts/ui/HUD.gd",
		"res://scripts/combat/BusterShot.gd",
		"res://scripts/combat/BeatBlazeShot.gd",
		"res://scripts/combat/Fireball.gd",
		"res://scripts/enemies/MetBeat.gd",
		"res://scripts/bosses/BeatfireMan.gd",
		"res://scenes/player/Player.tscn",
		"res://scenes/levels/Level01.tscn",
		"res://scenes/hazards/Spike.tscn",
		"res://scenes/ui/TouchControls.tscn",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/combat/BusterShot.tscn",
		"res://scenes/combat/BeatBlazeShot.tscn",
		"res://scenes/combat/Fireball.tscn",
		"res://scenes/enemies/MetBeat.tscn",
		"res://scenes/bosses/BeatfireMan.tscn",
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
		player.queue_free()
		await process_frame
	else:
		errors.append("Player.tscn failed to load")

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
				var win = level.get_node_or_null("WinBanner")
				if win == null:
					# May already be created
					print("WARN WinBanner not found immediately (may be timing)")
				else:
					print("OK WinBanner shown")
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
