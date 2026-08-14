@tool
extends Node

# Kunkun looking around a room the first time he walks into it. Drop this on
# the room's root node, fill in the lines, done.
#
# It only ever plays once — the flag is remembered in GameState, so walking
# back in through the door doesn't make him say it all over again. Hearing
# the same three lines every time you cross a doorway is the fastest way to
# make a player start mashing E through your writing.
#
# What belongs in here is a nudge, not an answer:
#
#     "Something metal is glinting in the corner."     <- room intro
#     "The rusty key is behind the piano."             <- not a room intro
#
# The player should still be the one who finds it. Anything that describes a
# specific object belongs on that object instead (see interactable.gd).

@export var lines: Array[DialogueLine] = []:
	set(value):
		lines = DialogueLine.fill_blanks(value)

@export var speaker_name: String = "Kun"

# The face used by any page that doesn't set its own.
@export var portrait: Texture2D

# Remembered in GameState. Leave it empty and the lines play on every single
# visit — only ever right for a room the player can't come back to.
@export var flag_id: String = ""

# A short beat before the box opens, so the room is on screen for a moment
# first instead of being covered the instant the door shuts.
@export var delay: float = 0.4


func _ready():
	if Engine.is_editor_hint():
		return
	if lines.is_empty():
		return
	if flag_id != "" and GameState.has_flag(flag_id):
		return

	GameState.set_flag(flag_id)
	_play.call_deferred()


func _play():
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	Dialogue.show_lines(lines, portrait, speaker_name)
