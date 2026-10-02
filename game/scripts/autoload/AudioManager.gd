extends Node
## AudioManager — BGM / SFX, mute, duck al pausar.
## Autoload. Chiptune original (sin Vocaloid/Capcom).

const SETTINGS_PATH := "user://audio_settings.cfg"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const SFX_POOL := 6
const BGM_VOL := -6.0
const SFX_VOL := -4.0
const DUCK_DB := -18.0

const BGM_PATHS := {
	"title": "res://audio/bgm/title.ogg",
	"boss_select": "res://audio/bgm/boss_select.ogg",
	"stage_beatfire": "res://audio/bgm/stage_beatfire.ogg",
	"stage_echo_wind": "res://audio/bgm/stage_echo_wind.ogg",
	"stage_neon_volt": "res://audio/bgm/stage_neon_volt.ogg",
	"stage_glitch_ice": "res://audio/bgm/stage_glitch_ice.ogg",
	"stage_chorus_bloom": "res://audio/bgm/stage_chorus_bloom.ogg",
	"stage_bassquake": "res://audio/bgm/stage_bassquake.ogg",
	"stage_metronome": "res://audio/bgm/stage_metronome.ogg",
	"stage_static_shadow": "res://audio/bgm/stage_static_shadow.ogg",
	"fortress": "res://audio/bgm/fortress.ogg",
	"victory": "res://audio/bgm/victory.ogg",
}

const SFX_PATHS := {
	"jump": "res://audio/sfx/jump.ogg",
	"shoot": "res://audio/sfx/shoot.ogg",
	"hit": "res://audio/sfx/hit.ogg",
	"hurt": "res://audio/sfx/hurt.ogg",
	"ui_confirm": "res://audio/sfx/ui_confirm.ogg",
	"boss_hit": "res://audio/sfx/boss_hit.ogg",
	"pickup": "res://audio/sfx/pickup.ogg",
	"slide": "res://audio/sfx/slide.ogg",
	"wall_jump": "res://audio/sfx/wall_jump.ogg",
	"charge_tick": "res://audio/sfx/charge_tick.ogg",
	"charge_full": "res://audio/sfx/charge_full.ogg",
	"explosion": "res://audio/sfx/explosion.ogg",
	"menu_move": "res://audio/sfx/menu_move.ogg",
	"boss_intro": "res://audio/sfx/boss_intro.ogg",
}

## Mapeo etapa → BGM id
const STAGE_BGM := {
	"beatfire": "stage_beatfire",
	"echo_wind": "stage_echo_wind",
	"neon_volt": "stage_neon_volt",
	"glitch_ice": "stage_glitch_ice",
	"chorus_bloom": "stage_chorus_bloom",
	"bassquake": "stage_bassquake",
	"metronome": "stage_metronome",
	"static_shadow": "stage_static_shadow",
	"fortress": "fortress",
	"core9": "fortress",
}

signal mute_changed(is_muted: bool)

var muted: bool = false
var _bgm: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var _streams_bgm: Dictionary = {}
var _streams_sfx: Dictionary = {}
var _current_bgm := ""
var _ducked := false
var _bgm_base_db := BGM_VOL


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_streams()
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BGMPlayer"
	_bgm.bus = BUS_BGM
	_bgm.volume_db = BGM_VOL
	_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm)
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.name = "SFX%d" % i
		p.bus = BUS_SFX
		p.volume_db = SFX_VOL
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)
	_load_settings()
	_apply_mute()


func _ensure_buses() -> void:
	## Crea buses BGM/SFX bajo Master si no existen.
	if AudioServer.get_bus_index(BUS_BGM) < 0:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_BGM)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index(BUS_SFX) < 0:
		var idx2 := AudioServer.bus_count
		AudioServer.add_bus(idx2)
		AudioServer.set_bus_name(idx2, BUS_SFX)
		AudioServer.set_bus_send(idx2, "Master")


func _load_streams() -> void:
	for id in BGM_PATHS:
		var path: String = BGM_PATHS[id]
		if not ResourceLoader.exists(path):
			push_warning("AudioManager: BGM file missing %s → %s" % [id, path])
			continue
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			push_warning("AudioManager: BGM failed to load %s → %s" % [id, path])
			continue
		# Loop all BGM except victory jingle
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = id != "victory"
		_streams_bgm[id] = stream
	for id in SFX_PATHS:
		var path2: String = SFX_PATHS[id]
		if not ResourceLoader.exists(path2):
			push_warning("AudioManager: SFX file missing %s → %s" % [id, path2])
			continue
		var stream2: AudioStream = load(path2) as AudioStream
		if stream2 == null:
			push_warning("AudioManager: SFX failed to load %s → %s" % [id, path2])
			continue
		_streams_sfx[id] = stream2


func play_bgm(id: String, pitch: float = 1.0) -> void:
	if id.is_empty():
		return
	if _bgm == null:
		push_warning("AudioManager: BGM player not ready (id=%s)" % id)
		return
	if id == _current_bgm and _bgm.playing:
		_bgm.pitch_scale = pitch
		return
	if not _streams_bgm.has(id):
		push_warning("AudioManager: BGM missing %s" % id)
		return
	var stream: Variant = _streams_bgm[id]
	if stream == null or not (stream is AudioStream):
		push_warning("AudioManager: BGM stream invalid %s" % id)
		_streams_bgm.erase(id)
		return
	_current_bgm = id
	_bgm.stream = stream
	_bgm.pitch_scale = pitch
	_bgm.volume_db = DUCK_DB if _ducked else _bgm_base_db
	if not muted:
		_bgm.play()


func play_stage_bgm(stage_id: String) -> void:
	var bgm_id: String = str(STAGE_BGM.get(stage_id, "stage_beatfire"))
	play_bgm(bgm_id)


func stop_bgm() -> void:
	_current_bgm = ""
	if _bgm:
		_bgm.stop()


func play_victory() -> void:
	## Jingle de victoria (sustituye BGM brevemente).
	play_bgm("victory", 1.0)


func play_boss_intro() -> void:
	## Sting al activar un jefe (no corta el BGM de etapa).
	play_sfx("boss_intro")


func play_sfx(id: String, pitch: float = 1.0) -> void:
	if muted:
		return
	if id.is_empty():
		return
	if _sfx_pool.is_empty():
		push_warning("AudioManager: SFX pool empty (id=%s)" % id)
		return
	if not _streams_sfx.has(id):
		# Missing asset — warn once-ish, never crash
		push_warning("AudioManager: SFX missing %s" % id)
		return
	var stream: Variant = _streams_sfx[id]
	if stream == null or not (stream is AudioStream):
		push_warning("AudioManager: SFX stream invalid %s" % id)
		_streams_sfx.erase(id)
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	if p == null or not is_instance_valid(p):
		return
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = SFX_VOL
	p.play()


func set_paused_duck(paused_now: bool) -> void:
	_ducked = paused_now
	if _bgm == null:
		return
	_bgm.volume_db = DUCK_DB if _ducked else _bgm_base_db


func set_muted(value: bool) -> void:
	muted = value
	_apply_mute()
	_save_settings()
	mute_changed.emit(muted)


func toggle_mute() -> bool:
	set_muted(not muted)
	return muted


func is_muted() -> bool:
	return muted


func _apply_mute() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, muted)
	if muted:
		if _bgm and _bgm.playing:
			_bgm.stop()
	else:
		if _bgm and _bgm.stream and _current_bgm != "" and not _bgm.playing:
			_bgm.play()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)
