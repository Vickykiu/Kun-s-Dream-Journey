extends Area2D

# Set in the Inspector if you want different wording.
@export var prompt_text: String = "Press E to pick up the key"

var player_inside := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true
		_show_prompt(prompt_text)

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		_hide_prompt()

func _unhandled_input(event):
	if player_inside and event.is_action_pressed("interact"):
		GameState.has_key = true   # remember it globally, survives scene changes
		_hide_prompt()
		queue_free()               # remove the key from the room

func _show_prompt(text):
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.text = text
		label.show()

func _hide_prompt():
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.hide()
