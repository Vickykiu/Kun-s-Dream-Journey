@tool
extends Area2D

# One script for every object Kunkun can look at: beds, pillows, drawers,
# wardrobes, notes, the computer. Drop this on an Area2D, fill in the fields
# in the Inspector, done — no new script per object.
#
#   Walk up  ->  the prompt appears
#   Press E  ->  the dialogue box shows `lines`, one page at a time
#
# If you need something extra to happen (open a puzzle, play a sound),
# connect to the `interacted` signal instead of editing this file.

signal interacted(node)

@export var prompt_text: String = "Press E to look"

# What Kunkun sees. Each entry is one page of the dialogue box: press Add
# Element, type the line, and drag a face into the slot beside it if this
# page needs a different expression. Leave that slot empty and the page uses
# `portrait` below, so most pages need nothing but text.
@export var lines: Array[DialogueLine] = []:
	set(value):
		lines = DialogueLine.fill_blanks(value)

# Optional — shown instead of `lines` when the player looks a second time.
# Leave empty to just repeat `lines`.
@export var lines_after: Array[DialogueLine] = []:
	set(value):
		lines_after = DialogueLine.fill_blanks(value)

# Optional — who is talking, and the face they wear by default. The portrait
# shows on the left of the dialogue box, the name in the tag above it. Any
# page that doesn't set its own expression uses this one. Leave both empty
# for furniture: plain text with no face is right for "you look at a bed".
@export var speaker_name: String = ""
@export var portrait: Texture2D

# Optional — an id from ItemDB. Set it and the first look hands the player
# that item: the lines play, then the item is held up on screen and the next
# E pockets it, exactly like picking one up off the floor (see pickup.gd).
# Evidence items count toward the ending.
@export var item_id: String = ""

# What gets held up. Left empty it uses the item's icon from ItemDB, and if
# the item has no icon yet the close-up step is simply skipped.
@export var closeup_texture: Texture2D

# The other side of it, for something with writing on the back — the photo
# on Ricardo's bed. Leave it empty and one press puts the item away instead
# of turning it over first.
@export var back_texture: Texture2D

# Optional — the item as it sits in the room: the photo lying on the bed,
# the key at the back of the drawer. It disappears once it has been handed
# over, and is still gone on a later visit. Point it at the Sprite2D, or at
# a whole branch if the thing is made of several nodes.
@export var item_node: NodePath

# What Kunkun says with the thing in his hand, i.e. after the close-up. His
# reaction to the item belongs here, not in `lines` above — those are read
# while he is still only looking at the drawer.
@export var pickup_lines: Array[DialogueLine] = []:
	set(value):
		pickup_lines = DialogueLine.fill_blanks(value)

# Adds a "(Added to inventory: ...)" page once it's pocketed. Only with item_id.
@export var announce_pickup: bool = true

# Optional — remembered in GameState, so "already searched" survives a
# scene change. Needed for anything that hands out an item or a key clue.
@export var flag_id: String = ""

# Can only be looked at once. After that the prompt stops appearing.
@export var one_shot: bool = false

# Disappear after the first look, e.g. an item lying on the floor.
@export var hide_after: bool = false

var _player_inside := false
var _looked_at := false   # fallback when flag_id is empty


func _ready():
	# @tool is only here for the Inspector convenience above — the object
	# shouldn't actually listen for the player while you're editing it.
	if Engine.is_editor_hint():
		set_process_unhandled_input(false)
		return

	# Handed over on an earlier visit — don't lay it out in the room again.
	if item_id != "" and GameState.has_item(item_id):
		_hide_item_node()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.name != "Player":
		return
	_player_inside = true
	if not _is_used_up():
		_show_prompt(prompt_text)


func _on_body_exited(body):
	if body.name != "Player":
		return
	_player_inside = false
	_hide_prompt()


func _unhandled_input(event):
	if not _player_inside:
		return
	if not event.is_action_pressed("interact"):
		return
	if ItemView.is_active() or Dialogue.is_active() or Inventory.is_open():
		return
	if _is_used_up():
		return
	_interact()


func _interact():
	var first_time := not _was_looked_at()

	_hide_prompt()
	_looked_at = true
	if flag_id != "":
		GameState.set_flag(flag_id)

	var pages: Array = []
	pages.append_array(lines if first_time or lines_after.is_empty() else lines_after)

	var handing_over := first_time and item_id != ""

	interacted.emit(self)

	if not pages.is_empty():
		Dialogue.show_lines(pages, portrait, speaker_name)
		await Dialogue.finished

	# Nothing goes into the bag unseen: whatever this object was hiding is
	# held up on screen first, and the next press of E is what pockets it.
	if handing_over:
		await ItemView.show_item(_item_texture(), back_texture)
		GameState.add_item(item_id)
		_hide_item_node()

		var after: Array = []
		after.append_array(pickup_lines)
		if announce_pickup:
			after.append("(Added to inventory: %s)" % ItemDB.get_item(item_id)["name"])
		if not after.is_empty():
			Dialogue.show_lines(after, portrait, speaker_name)
			await Dialogue.finished

	if hide_after:
		hide()
		set_deferred("monitoring", false)
		return

	# Still standing on it? Put the prompt back.
	if _player_inside and not _is_used_up():
		_show_prompt(prompt_text)


func _hide_item_node() -> void:
	if item_node.is_empty():
		return
	var node = get_node_or_null(item_node)
	if node is CanvasItem:
		node.hide()


func _item_texture() -> Texture2D:
	if closeup_texture:
		return closeup_texture
	var icon_path: String = ItemDB.get_item(item_id).get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		return load(icon_path)
	return null


func _was_looked_at() -> bool:
	if flag_id != "":
		return GameState.has_flag(flag_id)
	return _looked_at


func _is_used_up() -> bool:
	return one_shot and _was_looked_at()


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
