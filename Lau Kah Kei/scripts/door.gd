extends Area2D

# Set these per-door in the Inspector — no need to touch code.
@export var prompt_text: String = "Press E to enter"
@export var target_scene: String = ""   # e.g. "res://scenes/room_a01.tscn"
@export var requires_key: bool = false                    # tick this on for A05
@export var locked_text: String = "Locked — needs a key"

var player_inside := false
var _player: Node2D = null   # reference to the player currently on the door

func _ready():
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
	if Inventory.is_open():
		return
	if player_inside and event.is_action_pressed("interact"):
		if requires_key and not GameState.has_key:
			return   # still locked, do nothing
		if target_scene == "":
			print("No target_scene set for ", name)
			return
		# Remember where the player stood in THIS scene, so returning here
		# puts them back at this door instead of the default spawn.
		var current_path = get_tree().current_scene.scene_file_path
		if _player:
			GameState.spawn_points[current_path] = _player.global_position
		get_tree().change_scene_to_file(target_scene)

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
