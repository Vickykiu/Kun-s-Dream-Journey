extends Node
class_name RhythmConductor

signal song_started
signal song_finished

@export_range(30.0, 300.0, 0.1) var bpm: float = 128.0
@export_range(0.0, 10.0, 0.01) var first_beat_offset: float = 2.0

@onready var music: AudioStreamPlayer = %Music

var _last_song_position := 0.0


func play_song() -> void:
	_last_song_position = 0.0
	music.play(0.0)
	song_started.emit()


func stop_song() -> void:
	music.stop()
	_last_song_position = 0.0


func get_song_position() -> float:
	if not music.playing:
		return _last_song_position

	var position := (
		music.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
		- AudioServer.get_output_latency()
	)
	position = maxf(position, 0.0)

	_last_song_position = maxf(_last_song_position, position)
	return _last_song_position


func get_song_length() -> float:
	if music.stream == null:
		return 0.0
	return music.stream.get_length()


func seconds_per_beat() -> float:
	return 60.0 / bpm


func time_for_beat(beat_index: int) -> float:
	return first_beat_offset + float(beat_index) * seconds_per_beat()


func _on_music_finished() -> void:
	_last_song_position = get_song_length()
	song_finished.emit()
