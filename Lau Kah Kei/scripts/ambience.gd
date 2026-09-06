@tool
extends Node

# The background sound of one room. Drop this on the room's root node, drag a
# track into `track`, done.
#
# Asking for a track that is already playing does nothing, so every room in
# the chapter can point at the same file and the ambience runs unbroken from
# the corridor through the doorway and back. Point one room at a different
# track — A-02 at the heartbeat — and it crossfades on the way in, and back
# again on the way out.

@export var track: AudioStream

# How loud it sits. 0 is the same level the menu music plays at, and both go
# out on the Music bus, so the chapter's ambience now matches the menu rather
# than sitting under it. This is the number to turn: none of the rooms
# override it, so changing it here changes the whole chapter.
@export_range(-40.0, 0.0) var volume_db := 0.0

@export var fade := 1.5

# Optional — a second loop on top of `track`, for a room that needs something
# of its own without giving up the ambience underneath: the heartbeat over
# A-02. Every other room leaves this empty, and walking into one of them is
# what fades the heartbeat back out.
@export var layer: AudioStream

# Goes above 0 because a quiet recording sometimes has to be pushed past the
# level it was made at. Decibels aren't a multiplier: +6 is roughly twice as
# loud, +12 roughly four times. Past about +12 a track starts to distort.
@export_range(-40.0, 24.0) var layer_volume_db := 0.0


func _ready():
	if Engine.is_editor_hint():
		return
	Audio.play_music(track, volume_db, fade)
	Audio.play_layer(layer, layer_volume_db, fade)
