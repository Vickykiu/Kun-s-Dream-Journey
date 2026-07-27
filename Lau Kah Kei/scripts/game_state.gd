extends Node

# Global state that survives scene changes (autoload singleton).
# Access from anywhere as GameState.has_key, etc.

var has_key := false
var has_photo := false

# Remembers where the player was in each scene, keyed by scene path.
# e.g. spawn_points["res://scenes/corridor.tscn"] = Vector2(918, 400)
var spawn_points := {}

# Sound effects live on the autoload so they survive change_scene_to_file --
# a player inside the old scene would get freed mid-sound and cut off.
const DOOR_OPEN_SFX := preload("res://Lau Kah Kei/assets/audio/dooropen.mp3")

var _sfx: AudioStreamPlayer

func _ready():
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	add_child(_sfx)

func play_door_open():
	_sfx.stream = DOOR_OPEN_SFX
	_sfx.play()
