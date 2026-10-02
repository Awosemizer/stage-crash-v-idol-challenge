extends Node
## Estado global de partida — personaje elegido (Miku / Teto), armaduras y progreso mínimo.
## Autoload: GameState

enum Character { MIKU, TETO }

const COLOR_MIKU := Color(0.2, 0.9, 0.95, 1.0)
const COLOR_TETO := Color(0.92, 0.28, 0.35, 1.0)

## Stage Flight set — slots: head / torso / legs (HUD muestra 3).
const ARMOR_SET_FLIGHT := "flight"
const ARMOR_PIECE_HEAD := "head"
const ARMOR_PIECE_TORSO := "torso"
const ARMOR_PIECE_LEGS := "legs"
const ARMOR_PIECE_ARMS := "arms"
## Slot 3 = brazos Stage Flight (weapon+); "legs" queda como alias legacy.
const ARMOR_SLOT_ORDER := [ARMOR_PIECE_HEAD, ARMOR_PIECE_TORSO, ARMOR_PIECE_ARMS]

const COLOR_FLIGHT := Color(0.35, 0.85, 1.0, 1.0)

## Encore Guard set — defensa / utilidad.
const ARMOR_SET_ENCORE := "encore"
const COLOR_ENCORE := Color(0.85, 0.55, 0.25, 1.0)

## Boss ids (Robot Masters + fortaleza).
const BOSS_BEATFIRE := "beatfire"
const BOSS_GLITCH_ICE := "glitch_ice"
const BOSS_BASSQUAKE := "bassquake"
const BOSS_ECHO_WIND := "echo_wind"
const BOSS_NEON_VOLT := "neon_volt"
const BOSS_METRONOME := "metronome"
const BOSS_CHORUS_BLOOM := "chorus_bloom"
const BOSS_STATIC_SHADOW := "static_shadow"
const BOSS_CORE9 := "core9"

signal character_changed(character_id: String)
signal armor_changed(set_id: String)
signal boss_defeated(boss_id: String)

var selected_character: Character = Character.MIKU

## owned[set_id][piece_id] = true
var _armor_owned: Dictionary = {}
## equipped[set_id][piece_id] = true (proto: auto-equip on pickup)
var _armor_equipped: Dictionary = {}

## Progreso de jefes — proto: 8 Robot Masters jugables (Static Shadow incluido).
var beatfire_defeated: bool = false
var _bosses_defeated: Dictionary = {}

## Armas desbloqueadas (persisten entre etapas).
var _weapons_unlocked: Dictionary = {}

## Energy tanks (0–4) — HUD / recoverable stubs.
const MAX_ENERGY_TANKS := 4
var energy_tanks: int = 0

signal energy_tanks_changed(count: int)

## --- Dificultad ---
enum Difficulty { NORMAL, HARD }
var difficulty: Difficulty = Difficulty.NORMAL

const HURT_INVULN_NORMAL := 1.0
const HURT_INVULN_HARD := 0.6
const HARD_CONTACT_BONUS := 2  # +2 daño de contacto en Hard

## --- Logros ---
const ACH_EIGHT_MASTERS := "eight_masters"
const ACH_ALL_ARMOR := "all_armor"
const ACH_ALL_SECRETS := "all_secrets"
const ACH_CLEAR_MIKU := "clear_miku"
const ACH_CLEAR_TETO := "clear_teto"
const ACH_DEFEAT_CORE9 := "defeat_core9"
const ACH_NO_DAMAGE_BOSS := "no_damage_boss"

## Definiciones ES (id → título / descripción). Sin speed clear (stub omitido).
const ACHIEVEMENT_DEFS := [
	{"id": ACH_EIGHT_MASTERS, "title": "Ocho maestros", "desc": "Derrota a los 8 Robot Masters"},
	{"id": ACH_ALL_ARMOR, "title": "Colección de armaduras", "desc": "Obtén todas las piezas Flight + Encore"},
	{"id": ACH_ALL_SECRETS, "title": "Secretos al 100%", "desc": "Todas las armaduras y 4 Energy Tanks"},
	{"id": ACH_CLEAR_MIKU, "title": "Clear con Miku", "desc": "Termina CORE-9 con Hatsune Miku"},
	{"id": ACH_CLEAR_TETO, "title": "Clear con Teto", "desc": "Termina CORE-9 con Kasane Teto"},
	{"id": ACH_DEFEAT_CORE9, "title": "Núcleo apagado", "desc": "Derrota a CORE-9"},
	{"id": ACH_NO_DAMAGE_BOSS, "title": "Sin rasguño", "desc": "Vence un jefe sin recibir daño"},
]

signal achievement_unlocked(ach_id: String, title: String)
signal difficulty_changed(is_hard: bool)

## unlocked[id] = true
var _achievements: Dictionary = {}

## Tracking pelea de jefe (no-damage)
var _boss_fight_tracking := false
var _boss_fight_took_damage := false



func select_miku() -> void:
	selected_character = Character.MIKU
	character_changed.emit("miku")


func select_teto() -> void:
	selected_character = Character.TETO
	character_changed.emit("teto")


func is_miku() -> bool:
	return selected_character == Character.MIKU


func is_teto() -> bool:
	return selected_character == Character.TETO


func get_character_id() -> String:
	return "teto" if is_teto() else "miku"


func get_character_display_name() -> String:
	return "Kasane Teto" if is_teto() else "Hatsune Miku"


func get_portrait_color() -> Color:
	return COLOR_TETO if is_teto() else COLOR_MIKU


func get_body_color() -> Color:
	return get_portrait_color()


func _ensure_set(set_id: String) -> void:
	if not _armor_owned.has(set_id):
		_armor_owned[set_id] = {}
	if not _armor_equipped.has(set_id):
		_armor_equipped[set_id] = {}


func has_armor_piece(set_id: String, piece_id: String) -> bool:
	if not _armor_owned.has(set_id):
		return false
	return bool(_armor_owned[set_id].get(piece_id, false))


func is_armor_equipped(set_id: String, piece_id: String) -> bool:
	if not _armor_equipped.has(set_id):
		return false
	return bool(_armor_equipped[set_id].get(piece_id, false))


func grant_armor_piece(set_id: String, piece_id: String, auto_equip: bool = true) -> bool:
	## Otorga pieza de armadura. Devuelve true si es nueva.
	_ensure_set(set_id)
	var was_new := not has_armor_piece(set_id, piece_id)
	_armor_owned[set_id][piece_id] = true
	if auto_equip:
		_armor_equipped[set_id][piece_id] = true
	armor_changed.emit(set_id)
	if was_new:
		print("GameState: armadura %s/%s obtenida" % [set_id, piece_id])
		evaluate_achievements()
	return was_new


func equip_armor_piece(set_id: String, piece_id: String) -> void:
	if not has_armor_piece(set_id, piece_id):
		return
	_ensure_set(set_id)
	_armor_equipped[set_id][piece_id] = true
	armor_changed.emit(set_id)


func get_armor_owned_count(set_id: String) -> int:
	## Cuántas piezas del set se poseen (0–3).
	var n := 0
	for piece in ARMOR_SLOT_ORDER:
		if has_armor_piece(set_id, piece):
			n += 1
	return n


func get_armor_equipped_mask(set_id: String = ARMOR_SET_FLIGHT) -> Array:
	## Array[3] bool — [head, torso, legs] para HUD.
	var mask: Array = []
	for piece in ARMOR_SLOT_ORDER:
		mask.append(is_armor_equipped(set_id, piece))
	return mask


func has_flight_torso_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_FLIGHT, ARMOR_PIECE_TORSO)


func has_flight_arms_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_FLIGHT, ARMOR_PIECE_ARMS)


func has_encore_torso_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_ENCORE, ARMOR_PIECE_TORSO)


func has_encore_legs_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_ENCORE, ARMOR_PIECE_LEGS)


func has_encore_head_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_ENCORE, ARMOR_PIECE_HEAD)


func has_flight_head_equipped() -> bool:
	return is_armor_equipped(ARMOR_SET_FLIGHT, ARMOR_PIECE_HEAD)


func has_full_flight_equipped() -> bool:
	## Set completo Stage Flight (head+torso+arms) — bonus hover prolongado.
	return (
		has_flight_head_equipped()
		and has_flight_torso_equipped()
		and has_flight_arms_equipped()
	)


func get_encore_armor_color() -> Color:
	return COLOR_ENCORE


func get_flight_armor_color() -> Color:
	return COLOR_FLIGHT


func is_boss_defeated(boss_id: String) -> bool:
	if boss_id == BOSS_BEATFIRE:
		return beatfire_defeated
	return bool(_bosses_defeated.get(boss_id, false))


func mark_boss_defeated(boss_id: String) -> void:
	## Marca jefe vencido (idempotente). Siempre cierra tracking no-damage.
	var already := is_boss_defeated(boss_id)
	if not already:
		if boss_id == BOSS_BEATFIRE:
			beatfire_defeated = true
			unlock_weapon("beat_blaze")
		else:
			_bosses_defeated[boss_id] = true
			if boss_id == BOSS_ECHO_WIND:
				unlock_weapon("echo_gale")
			elif boss_id == BOSS_NEON_VOLT:
				unlock_weapon("neon_arc")
			elif boss_id == BOSS_GLITCH_ICE:
				unlock_weapon("freeze_sample")
			elif boss_id == BOSS_CHORUS_BLOOM:
				unlock_weapon("petal_chorus")
			elif boss_id == BOSS_BASSQUAKE:
				unlock_weapon("quake_drop")
			elif boss_id == BOSS_METRONOME:
				unlock_weapon("tempo_spike")
			elif boss_id == BOSS_STATIC_SHADOW:
				unlock_weapon("static_veil")
			elif boss_id == BOSS_CORE9:
				print("GameState: fortaleza CORE-9 completada")
		boss_defeated.emit(boss_id)
		print("GameState: jefe derrotado → %s" % boss_id)
	complete_boss_fight_track()
	if not already:
		evaluate_achievements()
		if active_slot >= 0:
			autosave()


func mark_beatfire_defeated() -> void:
	mark_boss_defeated(BOSS_BEATFIRE)


func is_beatfire_defeated() -> bool:
	return beatfire_defeated


func has_pending_armor_secret(boss_id: String) -> bool:
	## Stub: Beatfire → torso; Echo Wind → casco; Neon Volt → brazos Stage Flight.
	if boss_id == BOSS_BEATFIRE:
		return not has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_TORSO)
	if boss_id == BOSS_ECHO_WIND:
		return not has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_HEAD)
	if boss_id == BOSS_NEON_VOLT:
		return not has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_ARMS)
	if boss_id == BOSS_BASSQUAKE:
		return not has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_TORSO)
	if boss_id == BOSS_METRONOME:
		return not has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_LEGS)
	if boss_id == BOSS_STATIC_SHADOW:
		return not has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_HEAD)
	return false



func get_energy_tanks() -> int:
	return energy_tanks


func grant_energy_tank() -> int:
	## +1 tanque (cap MAX). Devuelve el nuevo total.
	if energy_tanks < MAX_ENERGY_TANKS:
		energy_tanks += 1
		energy_tanks_changed.emit(energy_tanks)
		print("GameState: Energy Tank → %d/%d" % [energy_tanks, MAX_ENERGY_TANKS])
		evaluate_achievements()
	return energy_tanks


func set_energy_tanks(count: int) -> void:
	energy_tanks = clampi(count, 0, MAX_ENERGY_TANKS)
	energy_tanks_changed.emit(energy_tanks)

func unlock_weapon(weapon_id: String) -> void:
	_weapons_unlocked[weapon_id] = true
	print("GameState: arma desbloqueada → %s" % weapon_id)


func has_weapon_unlocked(weapon_id: String) -> bool:
	return bool(_weapons_unlocked.get(weapon_id, false))


func get_unlocked_weapons() -> Array:
	var out: Array = []
	for k in _weapons_unlocked.keys():
		if bool(_weapons_unlocked[k]):
			out.append(str(k))
	return out


func defeated_boss_count() -> int:
	var n := 0
	if beatfire_defeated:
		n += 1
	for k in _bosses_defeated.keys():
		if bool(_bosses_defeated[k]):
			n += 1
	return n


func is_core9_unlocked() -> bool:
	## Bloqueado hasta los 8 Robot Masters.
	return defeated_boss_count() >= 8


## --- Saves (3 slots → user://save_N.json) ---
const SAVE_SLOT_COUNT := 3
const SAVE_VERSION := 1

signal save_written(slot: int)
signal save_loaded(slot: int)

## Slot activo 0..2; -1 = sin partida (no autosave).
var active_slot: int = -1
## Modo UI SaveSelect: "new" | "continue"
var save_ui_mode: String = "new"


func get_save_path(slot: int) -> String:
	return "user://save_%d.json" % clampi(slot, 0, SAVE_SLOT_COUNT - 1)


func slot_exists(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false
	return FileAccess.file_exists(get_save_path(slot))


func any_slot_exists() -> bool:
	for i in SAVE_SLOT_COUNT:
		if slot_exists(i):
			return true
	return false


func reset_progress() -> void:
	## Limpia progreso de partida (no toca active_slot).
	selected_character = Character.MIKU
	_armor_owned.clear()
	_armor_equipped.clear()
	beatfire_defeated = false
	_bosses_defeated.clear()
	_weapons_unlocked.clear()
	energy_tanks = 0
	energy_tanks_changed.emit(energy_tanks)
	difficulty = Difficulty.NORMAL
	_achievements.clear()
	_boss_fight_tracking = false
	_boss_fight_took_damage = false
	armor_changed.emit(ARMOR_SET_FLIGHT)
	difficulty_changed.emit(false)


func _dup_armor_dict(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for set_id in src.keys():
		var pieces: Dictionary = {}
		var inner = src[set_id]
		if typeof(inner) == TYPE_DICTIONARY:
			for piece_id in inner.keys():
				pieces[str(piece_id)] = bool(inner[piece_id])
		out[str(set_id)] = pieces
	return out


func to_save_dict() -> Dictionary:
	var bosses: Dictionary = {}
	if beatfire_defeated:
		bosses[BOSS_BEATFIRE] = true
	for k in _bosses_defeated.keys():
		if bool(_bosses_defeated[k]):
			bosses[str(k)] = true
	var weapons: Dictionary = {}
	for k in _weapons_unlocked.keys():
		if bool(_weapons_unlocked[k]):
			weapons[str(k)] = true
	var ach: Dictionary = {}
	for k in _achievements.keys():
		if bool(_achievements[k]):
			ach[str(k)] = true
	return {
		"version": SAVE_VERSION,
		"character": get_character_id(),
		"bosses_defeated": bosses,
		"weapons_unlocked": weapons,
		"armor_owned": _dup_armor_dict(_armor_owned),
		"armor_equipped": _dup_armor_dict(_armor_equipped),
		"energy_tanks": energy_tanks,
		"difficulty": "hard" if is_hard() else "normal",
		"achievements": ach,
	}


func apply_save_dict(data: Dictionary) -> void:
	reset_progress()
	var char_id := str(data.get("character", "miku"))
	if char_id == "teto":
		selected_character = Character.TETO
	else:
		selected_character = Character.MIKU
	character_changed.emit(get_character_id())

	var bosses = data.get("bosses_defeated", {})
	if typeof(bosses) == TYPE_DICTIONARY:
		for k in bosses.keys():
			if not bool(bosses[k]):
				continue
			var bid := str(k)
			if bid == BOSS_BEATFIRE:
				beatfire_defeated = true
			else:
				_bosses_defeated[bid] = true

	var weapons = data.get("weapons_unlocked", {})
	if typeof(weapons) == TYPE_DICTIONARY:
		for k in weapons.keys():
			if bool(weapons[k]):
				_weapons_unlocked[str(k)] = true

	var owned = data.get("armor_owned", {})
	if typeof(owned) == TYPE_DICTIONARY:
		_armor_owned = _dup_armor_dict(owned)
	var equipped = data.get("armor_equipped", {})
	if typeof(equipped) == TYPE_DICTIONARY:
		_armor_equipped = _dup_armor_dict(equipped)

	energy_tanks = clampi(int(data.get("energy_tanks", 0)), 0, MAX_ENERGY_TANKS)
	energy_tanks_changed.emit(energy_tanks)
	var diff := str(data.get("difficulty", "normal"))
	difficulty = Difficulty.HARD if diff == "hard" else Difficulty.NORMAL
	difficulty_changed.emit(is_hard())
	_achievements.clear()
	var ach_data = data.get("achievements", {})
	if typeof(ach_data) == TYPE_DICTIONARY:
		for k in ach_data.keys():
			if bool(ach_data[k]):
				_achievements[str(k)] = true
	armor_changed.emit(ARMOR_SET_FLIGHT)


func save_to_slot(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		push_warning("GameState.save_to_slot: slot inválido %d" % slot)
		return false
	var path := get_save_path(slot)
	var payload := to_save_dict()
	payload["slot"] = slot
	var json := JSON.stringify(payload)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("GameState: no se pudo escribir %s" % path)
		return false
	f.store_string(json)
	f.close()
	active_slot = slot
	save_written.emit(slot)
	print("GameState: guardado slot %d → %s" % [slot, path])
	return true


func load_from_slot(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: save corrupto en %s" % path)
		return false
	apply_save_dict(parsed)
	active_slot = slot
	save_loaded.emit(slot)
	print("GameState: cargado slot %d (%s, jefes=%d)" % [
		slot, get_character_id(), defeated_boss_count()
	])
	return true


func delete_slot(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	var path := get_save_path(slot)
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		# user:// paths: try relative via DirAccess.open("user://")
		var d := DirAccess.open("user://")
		if d:
			err = d.remove("save_%d.json" % slot)
	if active_slot == slot:
		active_slot = -1
	print("GameState: borrado slot %d (err=%s)" % [slot, str(err)])
	return err == OK or not FileAccess.file_exists(path)


func autosave() -> bool:
	## Autoguardado al volver al selector (requiere slot activo).
	if active_slot < 0 or active_slot >= SAVE_SLOT_COUNT:
		return false
	return save_to_slot(active_slot)


func begin_new_game(slot: int) -> void:
	active_slot = clampi(slot, 0, SAVE_SLOT_COUNT - 1)
	reset_progress()
	print("GameState: nueva partida slot %d" % active_slot)


func begin_continue(slot: int) -> bool:
	return load_from_slot(slot)


func get_slot_summary(slot: int) -> Dictionary:
	## Resumen para UI: exists, character, character_name, bosses_beaten, energy_tanks, empty.
	var empty := {
		"exists": false,
		"empty": true,
		"character": "",
		"character_name": "Vacío",
		"bosses_beaten": 0,
		"energy_tanks": 0,
		"difficulty": "normal",
	}
	if not slot_exists(slot):
		return empty
	var path := get_save_path(slot)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return empty
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return empty
	var char_id := str(parsed.get("character", "miku"))
	var bosses = parsed.get("bosses_defeated", {})
	var n := 0
	if typeof(bosses) == TYPE_DICTIONARY:
		for k in bosses.keys():
			if bool(bosses[k]):
				n += 1
	var char_name := "Kasane Teto" if char_id == "teto" else "Hatsune Miku"
	var diff_s := str(parsed.get("difficulty", "normal"))
	return {
		"exists": true,
		"empty": false,
		"character": char_id,
		"character_name": char_name,
		"bosses_beaten": n,
		"energy_tanks": int(parsed.get("energy_tanks", 0)),
		"difficulty": diff_s,
	}


## --- Dificultad / daño Hard ---

func is_hard() -> bool:
	return difficulty == Difficulty.HARD


func set_difficulty_hard(on: bool) -> void:
	difficulty = Difficulty.HARD if on else Difficulty.NORMAL
	difficulty_changed.emit(is_hard())
	print("GameState: dificultad → %s" % ("Hard" if on else "Normal"))


func set_difficulty_id(id: String) -> void:
	set_difficulty_hard(id == "hard")


func get_difficulty_id() -> String:
	return "hard" if is_hard() else "normal"


func get_difficulty_display_name() -> String:
	return "Difícil" if is_hard() else "Normal"


func get_hurt_invuln_time() -> float:
	return HURT_INVULN_HARD if is_hard() else HURT_INVULN_NORMAL


func scale_incoming_damage(amount: int) -> int:
	## Hard: +2 al daño de contacto / golpes (mín. amount).
	if amount <= 0:
		return amount
	if is_hard():
		return amount + HARD_CONTACT_BONUS
	return amount


## --- Logros ---

func has_achievement(ach_id: String) -> bool:
	return bool(_achievements.get(ach_id, false))


func get_unlocked_achievements() -> Array:
	var out: Array = []
	for d in ACHIEVEMENT_DEFS:
		var aid: String = str(d.get("id", ""))
		if has_achievement(aid):
			out.append(aid)
	return out


func get_achievement_defs() -> Array:
	return ACHIEVEMENT_DEFS.duplicate(true)


func unlock_achievement(ach_id: String) -> bool:
	## Desbloquea logro. Devuelve true si es nuevo.
	if ach_id.is_empty() or has_achievement(ach_id):
		return false
	var title := ach_id
	for d in ACHIEVEMENT_DEFS:
		if str(d.get("id", "")) == ach_id:
			title = str(d.get("title", ach_id))
			break
	_achievements[ach_id] = true
	achievement_unlocked.emit(ach_id, title)
	print("GameState: logro → %s (%s)" % [title, ach_id])
	_show_achievement_toast(title)
	if active_slot >= 0:
		autosave()
	return true


func robot_master_defeated_count() -> int:
	## Solo los 8 masters (sin CORE-9 / fortaleza).
	var masters := [
		BOSS_BEATFIRE, BOSS_GLITCH_ICE, BOSS_BASSQUAKE, BOSS_ECHO_WIND,
		BOSS_NEON_VOLT, BOSS_METRONOME, BOSS_CHORUS_BLOOM, BOSS_STATIC_SHADOW,
	]
	var n := 0
	for bid in masters:
		if is_boss_defeated(bid):
			n += 1
	return n


func has_all_armor_pieces() -> bool:
	var flight_ok := (
		has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_HEAD)
		and has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_TORSO)
		and has_armor_piece(ARMOR_SET_FLIGHT, ARMOR_PIECE_ARMS)
	)
	var encore_ok := (
		has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_HEAD)
		and has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_TORSO)
		and has_armor_piece(ARMOR_SET_ENCORE, ARMOR_PIECE_LEGS)
	)
	return flight_ok and encore_ok


func has_all_secrets_best_effort() -> bool:
	## Best-effort: 6 piezas de armadura + 4 Energy Tanks.
	return has_all_armor_pieces() and energy_tanks >= MAX_ENERGY_TANKS


func evaluate_achievements() -> void:
	if robot_master_defeated_count() >= 8:
		unlock_achievement(ACH_EIGHT_MASTERS)
	if has_all_armor_pieces():
		unlock_achievement(ACH_ALL_ARMOR)
	if has_all_secrets_best_effort():
		unlock_achievement(ACH_ALL_SECRETS)
	if is_boss_defeated(BOSS_CORE9):
		unlock_achievement(ACH_DEFEAT_CORE9)


func on_ending_reached() -> void:
	## Llamar desde EndingScreen — clear Miku/Teto + CORE-9.
	unlock_achievement(ACH_DEFEAT_CORE9)
	if is_teto():
		unlock_achievement(ACH_CLEAR_TETO)
	else:
		unlock_achievement(ACH_CLEAR_MIKU)
	evaluate_achievements()


func begin_boss_fight_track() -> void:
	_boss_fight_tracking = true
	_boss_fight_took_damage = false


func note_player_damaged() -> void:
	if _boss_fight_tracking:
		_boss_fight_took_damage = true


func complete_boss_fight_track() -> void:
	## Cierra pelea de jefe; desbloquea no-damage si no hubo golpes.
	if not _boss_fight_tracking:
		return
	var clean := not _boss_fight_took_damage
	_boss_fight_tracking = false
	if clean:
		unlock_achievement(ACH_NO_DAMAGE_BOSS)


func _finish_boss_fight_track() -> void:
	complete_boss_fight_track()


func cancel_boss_fight_track() -> void:
	_boss_fight_tracking = false
	_boss_fight_took_damage = false


func _show_achievement_toast(title: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.name = "AchievementToast"
	tree.root.add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.12, 0.2, 0.92)
	panel.position = Vector2(28, 8)
	panel.size = Vector2(200, 36)
	layer.add_child(panel)
	var border := ColorRect.new()
	border.color = Color(1.0, 0.85, 0.25, 1.0)
	border.position = Vector2(28, 8)
	border.size = Vector2(200, 2)
	layer.add_child(border)
	var hdr := Label.new()
	hdr.text = "¡LOGRO!"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 7)
	hdr.modulate = Color(1.0, 0.85, 0.3, 1.0)
	hdr.position = Vector2(28, 10)
	hdr.size = Vector2(200, 12)
	layer.add_child(hdr)
	var body := Label.new()
	body.text = title
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 9)
	body.modulate = Color(0.95, 0.98, 1.0, 1.0)
	body.position = Vector2(28, 24)
	body.size = Vector2(200, 14)
	layer.add_child(body)
	tree.create_timer(3.0).timeout.connect(Callable(layer, "queue_free"))


