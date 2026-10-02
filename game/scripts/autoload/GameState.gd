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
const ARMOR_SLOT_ORDER := [ARMOR_PIECE_HEAD, ARMOR_PIECE_TORSO, ARMOR_PIECE_LEGS]

const COLOR_FLIGHT := Color(0.35, 0.85, 1.0, 1.0)

signal character_changed(character_id: String)
signal armor_changed(set_id: String)

var selected_character: Character = Character.MIKU

## owned[set_id][piece_id] = true
var _armor_owned: Dictionary = {}
## equipped[set_id][piece_id] = true (proto: auto-equip on pickup)
var _armor_equipped: Dictionary = {}


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


func get_flight_armor_color() -> Color:
	return COLOR_FLIGHT
