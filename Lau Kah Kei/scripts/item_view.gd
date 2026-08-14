extends CanvasLayer

# Autoload singleton, built from scenes/item_view.tscn. One object filling
# the screen, the way the photo on Ricardo's bed does — dimmed background,
# the thing itself in the middle, a line at the bottom telling the player
# which key gets them out of it.
#
#     await ItemView.show_item(front_texture)                 # one look
#     await ItemView.show_item(front_texture, back_texture)   # E turns it over first
#
# It owns the keyboard while it is up: E turns the object over or puts it
# away, and every other key dies here so it can't reach the inventory, the
# main menu, or the object standing behind the close-up.
#
# LAYOUT IS EDITED IN THE EDITOR, NOT HERE. Open scenes/item_view.tscn and
# drag things around; what you see there is what you get in game. The
# placeholder texture in that scene is only so there is something to look at
# while positioning — it is replaced the moment a real item is shown.

signal finished

# What the bottom line says. Kept here rather than in every caller so all
# the items in the game word it the same way.
const HINT_FLIP := "Press E to turn it over"
const HINT_CLOSE := "Press E to put it away"

@onready var _root: Control = $Root
@onready var _image: TextureRect = $Root/Item
@onready var _hint: Label = $Root/Hint

var _back: Texture2D = null
var _showing_back := false
var _active := false


func _ready():
	layer = 95                                   # over the inventory, under the dialogue box
	process_mode = Node.PROCESS_MODE_ALWAYS      # keeps working if the game is paused
	_root.hide()


# --- public API ---------------------------------------------------------

# Awaitable: the call returns once the player has put the object away.
# `back` is optional — leave it out and one press closes the close-up
# instead of turning it over.
func show_item(front: Texture2D, back: Texture2D = null) -> void:
	if front == null:
		front = back                             # only a back? then that is the front
	if front == null:
		await get_tree().process_frame           # nothing to show, but still yield
		return                                   # once so `await` callers carry on

	_back = back if back != front else null
	_showing_back = false
	_active = true

	_image.texture = front
	_hint.text = HINT_FLIP if _back else HINT_CLOSE
	_root.show()
	_freeze_player(true)
	_block_menu_overlay(true)

	await finished


func is_active() -> bool:
	return _active


# --- input --------------------------------------------------------------

func _input(event):
	if not _active:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _back and not _showing_back:
			_turn_over()
		else:
			_close()

	# Mouse events are left alone so on-screen buttons still work.
	if event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


func _turn_over():
	_showing_back = true
	_image.texture = _back
	_hint.text = HINT_CLOSE


func _close():
	_active = false
	_root.hide()
	# Handing the game back is deferred to the end of the frame on purpose:
	# whoever is awaiting `finished` usually opens the dialogue box next, and
	# doing that inside this same input event would feed the box the very key
	# press that closed the close-up — skipping its first page.
	_finish.call_deferred()


func _finish():
	_back = null
	_freeze_player(false)
	_block_menu_overlay(false)
	finished.emit()


# The "ESC MAIN MENU" overlay is another chapter's autoload (ChapterEscape,
# listed in project.godot) sitting on top of everything with its own Esc
# handler and a clickable button. Hiding the whole layer takes out both at
# once, so the close-up can't be escaped past by keyboard or by mouse.
func _block_menu_overlay(blocked: bool) -> void:
	var overlay = get_node_or_null("/root/ChapterEscape")
	if overlay:
		overlay.visible = not blocked
		overlay.set_process_input(not blocked)


# Player nodes are in the "player" group (see player.tscn).
func _freeze_player(frozen: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_can_move"):
			p.set_can_move(not frozen)
