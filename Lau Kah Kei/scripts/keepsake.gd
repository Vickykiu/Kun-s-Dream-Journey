extends Area2D

# The keepsake photo. Walk up -> prompt. Press E -> show a big centered
# close-up. Press E again -> pocket it (the small photo disappears and
# GameState remembers we have it).

@export var prompt_text: String = "Press E to pick up"

var player_inside := false
var showing := false      # is the big close-up currently on screen?
var collected := false    # already pocketed?

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" and not collected:
		player_inside = true
		_show_prompt(prompt_text)

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		if not showing:
			_hide_prompt()

func _unhandled_input(event):
	if not event.is_action_pressed("interact"):
		return
	if showing:
		_close()                       # second press: put it away
	elif player_inside and not collected:
		_open()                        # first press: look at it

func _open():
	showing = true
	_hide_prompt()
	var closeup = get_tree().get_first_node_in_group("closeup")
	if closeup:
		closeup.show()

func _close():
	showing = false
	collected = true
	GameState.has_photo = true         # remember it, survives scene changes
	var closeup = get_tree().get_first_node_in_group("closeup")
	if closeup:
		closeup.hide()
	hide()                             # hide the small photo (and its sprite)
	set_deferred("monitoring", false)  # stop detecting the player

# Same shared prompt Label as the doors (group "prompt").
func _show_prompt(text):
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.text = text
		label.show()

func _hide_prompt():
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.hide()
