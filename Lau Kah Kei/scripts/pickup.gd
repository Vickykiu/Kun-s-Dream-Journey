@tool
extends Area2D

# One script for every item Kunkun can take: the photo on Ricardo's bed, the
# rusty key in the storeroom, the USB, the B-13 key. Drop this on an Area2D
# with a Sprite2D and a CollisionShape2D under it, set `item_id` in the
# Inspector, done — no new script per item.
#
#   Walk up  ->  the prompt appears
#   Press E  ->  the item fills the screen (ItemView)
#   Press E  ->  turns it over, but only if `back_texture` is set
#   Press E  ->  into the bag; the object disappears and Kunkun reacts
#
# Every item gets that look-at-it step, so nothing goes into the bag without
# the player seeing what it is.
#
# Picked-up items stay picked up: GameState remembers the id, so walking back
# into the room doesn't lay the item out on the floor again.
#
# If you need something extra to happen (unlock a door, start a cutscene),
# connect to the `collected` signal instead of editing this file.

signal collected(node)

# An id from ItemDB — that is where the item's name, description and icon
# live. Adding a new item means one entry there and one of these in a room.
@export var item_id: String = ""

@export var prompt_text: String = "Press E to pick up"

# What fills the screen. Left empty it uses the item's icon from ItemDB, and
# failing that the texture of the Sprite2D under this node — so most items
# need nothing here at all.
@export var closeup_texture: Texture2D

# The other side, for things with something written on the back. Leave it
# empty and the turn-over step is skipped: one look, then into the bag.
@export var back_texture: Texture2D

# What Kunkun says once it is in his pocket. Press Add Element, type the
# line, drag a face into the slot beside it. Leave a face empty and that page
# uses `portrait` below.
@export var lines: Array[DialogueLine] = []:
	set(value):
		lines = DialogueLine.fill_blanks(value)

@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

# Adds a "(Added to inventory: ...)" page after `lines`. Only with item_id.
@export var announce_pickup: bool = true

var _player_inside := false
var _taken := false


func _ready():
	# @tool is only here so the Inspector can fill in blank dialogue pages —
	# the item shouldn't watch for the player while you're editing it.
	if Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return

	# Already in the bag from an earlier visit to this room.
	if _already_taken():
		_taken = true
		hide()
		set_deferred("monitoring", false)
		set_process_unhandled_input(false)
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name != "Player":
		return
	_player_inside = true
	if not _taken:
		_show_prompt(prompt_text)


func _on_body_exited(body):
	if body.name != "Player":
		return
	_player_inside = false
	_hide_prompt()


# Opening waits its turn in _unhandled_input, so an open close-up, dialogue
# box or inventory gets first refusal on the key.
func _unhandled_input(event):
	if _taken or not _player_inside:
		return
	if not event.is_action_pressed("interact"):
		return
	if ItemView.is_active() or Dialogue.is_active() or Inventory.is_open():
		return
	_pick_up()


func _pick_up():
	_taken = true
	_hide_prompt()

	# The close-up owns the screen until the player presses E again — that
	# press is what actually pockets the item.
	await ItemView.show_item(_front_texture(), back_texture)

	GameState.add_item(item_id)
	hide()                             # the object is gone from the room
	set_deferred("monitoring", false)  # and stops detecting the player
	collected.emit(self)

	# Reacting after the close-up is gone, not during it, so the words land
	# on the empty bed rather than covering what the player is looking at.
	var pages: Array = []
	pages.append_array(lines)
	if announce_pickup and item_id != "":
		pages.append("(Added to inventory: %s)" % ItemDB.get_item(item_id)["name"])
	if not pages.is_empty():
		Dialogue.show_lines(pages, portrait, speaker_name)


func _already_taken() -> bool:
	return item_id != "" and GameState.has_item(item_id)


func _front_texture() -> Texture2D:
	if closeup_texture:
		return closeup_texture

	var icon_path: String = ItemDB.get_item(item_id).get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		return load(icon_path)

	for child in get_children():
		if child is Sprite2D and child.texture:
			return child.texture

	return null


# Same shared prompt Label as the doors — a Label in the "prompt" group.
func _show_prompt(text: String) -> void:
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.text = text
		label.show()


func _hide_prompt() -> void:
	var label = get_tree().get_first_node_in_group("prompt")
	if label:
		label.hide()
