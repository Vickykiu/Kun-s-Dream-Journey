extends Node

## menu-music and volume-settings controller.

const MENU_MUSIC_PATH := "res://Kiu Chun Woon/assets/audio/menu_theme.mp3"
const SETTINGS_PATH := "user://audio_settings.cfg"
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.78

var _player: AudioStreamPlayer
var _fade_tween: Tween


func _ready() -> void:
	_ensure_music_bus_exists()

	_player = AudioStreamPlayer.new()
	_player.name = "MenuMusicPlayer"
	_player.bus = &"Music"

	var menu_music := load(MENU_MUSIC_PATH) as AudioStreamMP3
	_player.stream = menu_music
	add_child(_player)

	if menu_music:
		menu_music.loop = true

	load_settings()


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
	else:
		set_master_volume(DEFAULT_MASTER_VOLUME)
		set_music_volume(DEFAULT_MUSIC_VOLUME)


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
