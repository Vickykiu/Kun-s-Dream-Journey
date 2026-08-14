extends Label

# Words that drift up over somebody's head and fade again — muttering, not
# conversation. Nothing to press, nothing to close: the player just walks past
# and catches it.
#
# Put it on a Label under whoever is talking, type the lines into `Text Lines`
# (one per row), done. They cycle forever in order.
#
# Use it for background chatter only. Anything the player NEEDS to read goes
# in the dialogue box (Dialogue.show_lines), which stops the game and waits.
#
# The lines are one multi-line string rather than an array on purpose: Godot
# keeps blanking exported arrays on instanced scenes (it can't tell whether
# you edited them), and three silent students is a hard bug to spot.

@export_multiline var text_lines: String = ""

@export var show_time := 2.5     # seconds a line stays up
@export var gap_time := 3.5      # seconds of silence between lines
@export var fade_speed := 3.0    # how fast it fades in and out

# Stagger several mutterers so they don't all speak in chorus.
@export var start_delay := 0.0

var _lines: PackedStringArray = []
var _index := 0
var _timer := 0.0
var _speaking := false


func _ready():
	modulate.a = 0.0
	text = ""
	say(text_lines, start_delay)


# Swap in a different set of lines at runtime. `block` is one string with a
# line per row; blank rows are dropped.
func say(block: String, delay := 0.0) -> void:
	_lines = PackedStringArray()
	for line in block.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed != "":
			_lines.append(trimmed)

	_index = 0
	_speaking = false
	_timer = -delay
	text = ""
	modulate.a = 0.0


func _process(delta):
	if _lines.is_empty():
		return

	_timer += delta

	if _speaking:
		if _timer >= show_time:
			_speaking = false
			_timer = 0.0
	elif _timer >= gap_time:
		_speaking = true
		_timer = 0.0
		text = _lines[_index % _lines.size()]
		_index += 1

	modulate.a = move_toward(modulate.a, 1.0 if _speaking else 0.0, delta * fade_speed)
