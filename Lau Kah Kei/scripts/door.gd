@tool
extends Area2D

# Set these per-door in the Inspector — no need to touch code.
@export var prompt_text: String = "Press E to enter"
@export var target_scene: String = ""   # e.g. "res://scenes/room_a01.tscn"
@export var requires_key: bool = false                    # tick this on for A05
@export var locked_text: String = "Locked — needs a key"

# Optional — what he says when he tries a door that won't open. Leave these
# empty and the door behaves exactly as it always did. Fill them in and the
# locked door answers back, which is the difference between "this is locked"
# and "this game is broken": pressing E and getting nothing at all is the
# most common way a player decides something is bugged.
@export var locked_lines: Array[DialogueLine] = []:
	set(value):
		locked_lines = DialogueLine.fill_blanks(value)

# Shown from the second try onwards, so rattling the same handle doesn't
# replay the whole speech. Leave empty to just repeat `locked_lines`.
@export var locked_lines_after: Array[DialogueLine] = []:
	set(value):
		locked_lines_after = DialogueLine.fill_blanks(value)

@export var speaker_name: String = ""
@export var portrait: Texture2D

# Remembered in GameState, so "he has tried this door before" survives
# walking off and coming back.
@export var flag_id: String = ""

var player_inside := false
var _player: Node2D = null   # reference to the player currently on the door

func _ready():
	# @tool is only here so the Inspector can fill in blank dialogue pages —
	# the door shouldn't watch for anyone while you're editing it.
	if Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true
		_player = body
		_show_prompt(_current_prompt())

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		_player = null
		_hide_prompt()

func _unhandled_input(event):
	if Inventory.is_open() or Dialogue.is_active() or ItemView.is_active():
		return
	if player_inside and event.is_action_pressed("interact"):
		if requires_key and not GameState.has_key:
			_rattle_the_handle()
			return
		if target_scene == "":
			print("No target_scene set for ", name)
			return
		# Remember where the player stood in THIS scene, so returning here
		# puts them back at this door instead of the default spawn.
		var current_path = get_tree().current_scene.scene_file_path
		if _player:
			GameState.spawn_points[current_path] = _player.global_position
		get_tree().change_scene_to_file(target_scene)

# He tries it, it doesn't open, and he says so. Silence here is what makes
# players think the button is broken rather than the door.
func _rattle_the_handle() -> void:
	var first := flag_id == "" or not GameState.has_flag(flag_id)
	if flag_id != "":
		GameState.set_flag(flag_id)

	var pages: Array = []
	pages.append_array(locked_lines if first or locked_lines_after.is_empty() else locked_lines_after)
	if pages.is_empty():
		return

	_hide_prompt()
	Dialogue.show_lines(pages, portrait, speaker_name)
	await Dialogue.finished

	if player_inside:
		_show_prompt(_current_prompt())


# Locked doors show the locked message until the player has the key.
func _current_prompt() -> String:
	if requires_key and not GameState.has_key:
		return locked_text
	return prompt_text

# Find whatever Label is in the "prompt" group in the current scene, and show/hide it.
func _show_prompt(text):
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.text = text
		label.show()

func _hide_prompt():
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.hide()
