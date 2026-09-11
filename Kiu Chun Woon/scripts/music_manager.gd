extends Node

##Music, SFX and volume settings

const MENU_MUSIC_PATH := "res://Kiu Chun Woon/assets/audio/menu_theme.mp3"
const DIALOGUE_CLICK_PATH := "res://Kiu Chun Woon/assets/audio/dialogue_click.mp3"
const HARD_MODE_WOW_PATH := "res://Kiu Chun Woon/assets/audio/hard_mode_wow.mp3"
const SFX_GAIN_DB := {&"dialogue": -3.0, &"hard_mode_clear": 0.0}
const SETTINGS_PATH := "user://audio_settings.cfg"
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.78
const DEFAULT_SFX_VOLUME := 0.70

var _player: AudioStreamPlayer
var _fade_tween: Tween
var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _hard_mode_clear_player: AudioStreamPlayer
var _last_cue_at: Dictionary = {}
var _next_sfx_player := 0


func _ready() -> void:
	_ensure_music_bus_exists()
	_ensure_sfx_bus_exists()

	_player = AudioStreamPlayer.new()
	_player.name = "MenuMusicPlayer"
	_player.bus = &"Music"

	var menu_music := load(MENU_MUSIC_PATH) as AudioStreamMP3
	_player.stream = menu_music
	add_child(_player)

	if menu_music:
		menu_music.loop = true

	load_settings()
	_prepare_sfx()
	get_tree().node_added.connect(_on_ui_node_added)


func set_sfx_volume(linear_value: float) -> void:
	_set_bus_volume(&"SFX", linear_value)


func get_sfx_volume() -> float:
	return _get_bus_volume(&"SFX")


func play_sfx(cue: StringName) -> void:
	if not _sfx_streams.has(cue) or _sfx_players.is_empty():
		return

	var now := Time.get_ticks_msec()
	var minimum_gap := 80 if cue != &"ui_confirm" else 140
	if now - int(_last_cue_at.get(cue, -10000)) < minimum_gap:
		return
	_last_cue_at[cue] = now

	var player: AudioStreamPlayer
	if cue == &"hard_mode_clear":
		player = _hard_mode_clear_player
	else:
		player = _sfx_players[_next_sfx_player]
		_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = _sfx_streams[cue]
	player.volume_db = float(SFX_GAIN_DB.get(cue, -10.0))
	player.play()


func _prepare_sfx() -> void:
	var tones := {
		&"ui_hover": [480.0, 580.0, 0.055],
		&"ui_confirm": [600.0, 900.0, 0.12],
		&"perfect": [880.0, 1320.0, 0.105],
		&"great": [660.0, 880.0, 0.09],
		&"miss": [160.0, 90.0, 0.13],
		&"early": [290.0, 220.0, 0.07],
		&"countdown": [700.0, 700.0, 0.08],
		&"success": [520.0, 1040.0, 0.35],
		&"fail": [260.0, 130.0, 0.28],
	}
	for cue in tones:
		var tone: Array = tones[cue]
		_sfx_streams[cue] = _make_tone(tone[0], tone[1], tone[2])
	_load_recorded_sfx(&"dialogue", DIALOGUE_CLICK_PATH)
	_load_recorded_sfx(&"hard_mode_clear", HARD_MODE_WOW_PATH)
	_hard_mode_clear_player = AudioStreamPlayer.new()
	_hard_mode_clear_player.name = "HardModeClearSFX"
	_hard_mode_clear_player.bus = &"SFX"
	add_child(_hard_mode_clear_player)
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = &"SFX"
		player.volume_db = -10.0
		add_child(player)
		_sfx_players.append(player)


func _load_recorded_sfx(cue: StringName, path: String) -> void:
	var recording := load(path) as AudioStreamMP3
	if recording == null:
		push_warning("Could not load sound effect: " + path)
		return
	var one_shot := recording.duplicate() as AudioStreamMP3
	one_shot.loop = false
	_sfx_streams[cue] = one_shot


func _make_tone(start_hz: float, end_hz: float, duration: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var sample_count := int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		phase += TAU * lerpf(start_hz, end_hz, progress) / SAMPLE_RATE
		var envelope := minf(progress * 20.0, 1.0) * pow(1.0 - progress, 1.8)
		var sample := (sin(phase) + 0.18 * sin(phase * 2.0)) * envelope * 0.5
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _on_ui_node_added(node: Node) -> void:
	if node is Button:
		_wire_ui_button.call_deferred(node)


func _wire_ui_button(button: Button) -> void:
	if not is_instance_valid(button) or button.get_meta("sfx_wired", false):
		return
	if button.get_meta("sfx_silent", false):
		return
	var ancestor: Node = button
	while ancestor != null:
		if ancestor.scene_file_path.begins_with("res://Kiu Chun Woon/"):
			button.set_meta("sfx_wired", true)
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.focus_entered.connect(_on_button_focus.bind(button))
			button.pressed.connect(play_sfx.bind(&"ui_confirm"))
			return
		ancestor = ancestor.get_parent()


func _on_button_hover(button: Button) -> void:
	if button.is_visible_in_tree() and not button.disabled:
		play_sfx(&"ui_hover")


func _on_button_focus(button: Button) -> void:
	if (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")
		or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")
		or Input.is_physical_key_pressed(KEY_TAB)):
		_on_button_hover(button)


func play_menu_music(fade_duration: float = 0.8) -> void:
	if _player.playing:
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_player.volume_db = -32.0
	_player.play()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", 0.0, fade_duration)


func stop_music(fade_duration: float = 0.35) -> void:
	if not _player.playing:
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -32.0, fade_duration)
	_fade_tween.tween_callback(_finish_stop)


func _finish_stop() -> void:
	_player.stop()
	_player.volume_db = 0.0


func set_master_volume(linear_value: float) -> void:
	_set_bus_volume(&"Master", linear_value)


func set_music_volume(linear_value: float) -> void:
	_set_bus_volume(&"Music", linear_value)


func get_master_volume() -> float:
	return _get_bus_volume(&"Master")


func get_music_volume() -> float:
	return _get_bus_volume(&"Music")


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", get_master_volume())
	config.set_value("audio", "music_volume", get_music_volume())
	config.set_value("audio", "sfx_volume", get_sfx_volume())
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save audio settings: error %s" % error)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error == OK:
		set_master_volume(
			float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME))
		)
		set_music_volume(
			float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME))
		)
		set_sfx_volume(float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)))
	else:
		set_master_volume(DEFAULT_MASTER_VOLUME)
		set_music_volume(DEFAULT_MUSIC_VOLUME)
		set_sfx_volume(DEFAULT_SFX_VOLUME)


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var safe_value := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, safe_value <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(safe_value, 0.001)))


func _get_bus_volume(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


func _ensure_music_bus_exists() -> void:
	if AudioServer.get_bus_index(&"Music") != -1:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, &"Music")
	AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")


func _ensure_sfx_bus_exists() -> void:
	if AudioServer.get_bus_index(&"SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, &"SFX")
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"SFX"), &"Master")
