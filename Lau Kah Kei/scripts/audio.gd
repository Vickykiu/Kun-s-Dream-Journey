extends Node

# Autoload singleton. Every sound in the chapter goes through here.
#
#     Audio.play("door_open")            # one of the named sounds below
#     Audio.play_stream(some_stream)     # anything dragged into an Inspector
#     Audio.play_music(track)            # loops, and survives a scene change
#
# Effects go out on the SFX bus and music on the Music bus, so both volume
# sliders in the options menu reach them. Effects are played through a small
# pool of players, so a second sound doesn't cut the first one off.
#
# TUNING THE LEVELS IS DONE IN `VOLUME` BELOW, not by re-exporting the files.
# Every number is in decibels: -6 is about half as loud, -12 is quiet
# background, 0 is the file as it was recorded.

# The named sounds. Add a file to assets/audio, add a line here, and it can be
# played from anywhere by name.
const SFX := {
	"dialogue_page": "res://Lau Kah Kei/assets/audio/dialog click.mp3",
	"inventory": "res://Lau Kah Kei/assets/audio/Inventory Grab.mp3",
	"door_open": "res://Lau Kah Kei/assets/audio/dooropen.mp3",
	"door_locked": "res://Lau Kah Kei/assets/audio/doorknob jiggle.mp3",
	"caught": "res://Lau Kah Kei/assets/audio/jumpscare hit.mp3",
	"puzzle_right": "res://Lau Kah Kei/assets/audio/correct notification.mp3",
	"puzzle_wrong": "res://Lau Kah Kei/assets/audio/Error Notification.mp3",
	"boom": "res://Lau Kah Kei/assets/audio/low boom.mp3",
	"chapter_end": "res://Lau Kah Kei/assets/audio/ending chap2.mp3",
	"item_show": "res://Lau Kah Kei/assets/audio/card flip.mp3",
	"item_flip": "res://Lau Kah Kei/assets/audio/turn page.mp3",
}

# How loud each one sits. 0 is the file played as it was recorded, which is
# also what the menu music runs at — so 0 here matches the level the rest of
# the game is already at, and anything below 0 is deliberately pulled back.
#
# The dialogue click is the one exception. It fires on every single page, so
# at the same level as everything else it becomes the sound of the game.
const VOLUME := {
	"dialogue_page": -6.0,
	"inventory": 0.0,
	"door_open": 0.0,
	"door_locked": 0.0,
	"caught": 0.0,
	"puzzle_right": 0.0,
	"puzzle_wrong": 0.0,
	"boom": 0.0,
	"chapter_end": 0.0,
	"item_show": 0.0,
	"item_flip": 0.0,
}

const DEFAULT_VOLUME := 0.0

# The part of a file that's worth hearing, as [start, end] in seconds. Silence
# at the front, a tail that outstays the moment it plays over — trimmed here
# rather than in the file, so the numbers stay adjustable and the original is
# never re-exported. It fades out over the last fraction of a second rather
# than cutting dead, which is audible as a click.
#
# Keyed by file, so a sound used in two rooms only needs the numbers once.
# An end of 0 means "play to the end of the file", so a sound that only needs
# its silent front trimmed off just gets a start.
const CLIP := {
	"res://Lau Kah Kei/assets/audio/key pick up.mp3": [0.4, 1.4],
	"res://Lau Kah Kei/assets/audio/jumpscare hit.mp3": [0.18, 0.0],
	"res://Lau Kah Kei/assets/audio/doorknob jiggle.mp3": [0.25, 0.0],
	"res://Lau Kah Kei/assets/audio/dooropen.mp3": [0.0, 1.3],
	"res://Lau Kah Kei/assets/audio/turn page.mp3": [0.0, 0.85],
}

const CUT_FADE := 0.15

# How many effects can be heard at the same time.
const VOICES := 8

const MUSIC_FADE := 1.5

var _pool: Array[AudioStreamPlayer] = []
var _next := 0

# Bumped on every sound played, so a cut-off timer can tell whether the voice
# it was watching is still playing the sound it started with.
var _serial := 0

var _music: AudioStreamPlayer
var _music_tween: Tween

# A second continuous track riding on top of the first: the heartbeat over the
# monitor room's ambience. Same rules as the music — asking for what is
# already playing does nothing, asking for null fades it out.
var _layer: AudioStreamPlayer
var _layer_tween: Tween


func _ready():
	# Sounds keep playing while the game is paused — the dialogue box and the
	# close-up both run on a paused tree.
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_pool.append(player)

	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)

	_layer = AudioStreamPlayer.new()
	_layer.bus = &"Music"
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)


# --- effects ------------------------------------------------------------

# One of the names in SFX above. An unknown name is ignored rather than
# crashing the game in front of an audience.
func play(id: String, volume_db := INF) -> void:
	if not SFX.has(id):
		push_warning("Audio.play: no sound called '%s'" % id)
		return
	if volume_db == INF:
		volume_db = VOLUME.get(id, DEFAULT_VOLUME)
	play_stream(load(SFX[id]), volume_db)


# For sounds dragged into a scene rather than named here — the creak of one
# particular drawer, the sound of one particular item.
func play_stream(stream: AudioStream, volume_db := DEFAULT_VOLUME) -> void:
	if stream == null:
		return

	var player := _free_player()

	# This voice may still be counting down a cut-off from the last sound it
	# played. Stamping a new serial on it makes that one give up.
	_serial += 1
	player.set_meta("serial", _serial)
	_kill_cut(player)

	player.stream = stream
	player.volume_db = volume_db

	var window: Array = CLIP.get(stream.resource_path, [])
	var from: float = window[0] if window.size() == 2 else 0.0
	var until: float = window[1] if window.size() == 2 else 0.0

	player.play(from)
	if until > from:
		_cut_off(player, _serial, volume_db, until - from)


# Lets a sound run for `cap` seconds, then fades the last CUT_FADE of it out.
# Every step checks the voice is still playing what it was handed, so a
# later sound on the same voice is never faded or stopped by an old timer.
func _cut_off(player: AudioStreamPlayer, serial: int, volume_db: float, cap: float) -> void:
	await get_tree().create_timer(maxf(cap - CUT_FADE, 0.0)).timeout
	if player.get_meta("serial", -1) != serial:
		return

	var tween := create_tween()
	player.set_meta("cut", tween)
	tween.tween_property(player, "volume_db", volume_db - 40.0, CUT_FADE)
	tween.tween_callback(_stop_if_unchanged.bind(player, serial))


func _stop_if_unchanged(player: AudioStreamPlayer, serial: int) -> void:
	if player.get_meta("serial", -1) == serial:
		player.stop()


func _kill_cut(player: AudioStreamPlayer) -> void:
	if not player.has_meta("cut"):
		return
	var tween = player.get_meta("cut")
	if tween is Tween and tween.is_valid():
		tween.kill()
	player.remove_meta("cut")


# Round-robin: the oldest voice is the one that gets taken, so a burst of
# sounds overlaps instead of cutting itself off.
func _free_player() -> AudioStreamPlayer:
	for i in _pool.size():
		var player: AudioStreamPlayer = _pool[(_next + i) % _pool.size()]
		if not player.playing:
			_next = (_next + i + 1) % _pool.size()
			return player
	var oldest: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	return oldest


# --- music and ambience -------------------------------------------------

# Starts a looping track. Asking for the track that is already playing does
# nothing, which is the whole point: the corridor and the rooms share one
# ambience, so walking through a door doesn't restart it.
func play_music(stream: AudioStream, volume_db := -12.0, fade := MUSIC_FADE) -> void:
	if stream == null:
		stop_music(fade)
		return
	if _music.stream == stream and _music.playing:
		return

	_kill_tween()

	# Godot doesn't loop an imported mp3 unless the stream is told to.
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true

	if _music.playing:
		# Out with the old first, so the two don't play over each other.
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -40.0, fade * 0.5)
		_music_tween.tween_callback(_swap_to.bind(stream, volume_db, fade))
		return

	_swap_to(stream, volume_db, fade)


func stop_music(fade := MUSIC_FADE) -> void:
	if not _music.playing:
		return
	_kill_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -40.0, fade)
	_music_tween.tween_callback(_music.stop)


func _swap_to(stream: AudioStream, volume_db: float, fade: float) -> void:
	_kill_tween()
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", volume_db, fade)


func _kill_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()


# --- the second layer ---------------------------------------------------

# Rides on top of whatever play_music is doing, so a room can have both an
# ambience and something of its own over it. Passing null fades the layer out
# and leaves the music alone — which is what every room that isn't A-02 does,
# so walking out takes the heartbeat with you.
func play_layer(stream: AudioStream, volume_db := 0.0, fade := MUSIC_FADE) -> void:
	if stream == null:
		stop_layer(fade)
		return
	if _layer.stream == stream and _layer.playing:
		return

	_kill_layer_tween()

	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true

	_layer.stream = stream
	_layer.volume_db = -40.0
	_layer.play()
	_layer_tween = create_tween()
	_layer_tween.tween_property(_layer, "volume_db", volume_db, fade)


func stop_layer(fade := MUSIC_FADE) -> void:
	if not _layer.playing:
		return
	_kill_layer_tween()
	_layer_tween = create_tween()
	_layer_tween.tween_property(_layer, "volume_db", -40.0, fade)
	_layer_tween.tween_callback(_layer.stop)


func _kill_layer_tween() -> void:
	if _layer_tween and _layer_tween.is_valid():
		_layer_tween.kill()
