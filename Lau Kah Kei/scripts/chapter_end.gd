extends CanvasLayer

# The end of a chapter: the screen fades to black, one line of text fades up
# over it, and then the next chapter loads.
#
# Drop this node anywhere in the last room and set `trigger_item` to the id
# of the thing the player has to find. It watches the inventory and fires by
# itself the moment that item is in the bag — after whatever dialogue the
# pickup started has finished, so the last line never gets cut off.
#
# Leave `next_scene` empty and it fades and holds without going anywhere,
# which is what you want while the chapter after this one is still being
# built.

# The item that ends the chapter, e.g. "key_b13" for Chapter 2.
@export var trigger_item: String = ""

@export_multiline var subtitle: String = ""

# Where to hand over to. Empty = stay on the black screen.
@export_file("*.tscn") var next_scene: String = ""

@export var fade_time := 2.5      # seconds for the room to go black
@export var text_fade_time := 1.2
@export var hold_time := 3.0      # seconds the line stays up before moving on

var _started := false
var _black: ColorRect
var _label: Label


func _ready():
	layer = 120                                  # over the dialogue box
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _process(_delta):
	if _started or trigger_item == "":
		return
	if not GameState.has_item(trigger_item):
		return
	# Let the pickup have its last word first.
	if Dialogue.is_active() or ItemView.is_active() or Inventory.is_open():
		return
	_start()


func _start() -> void:
	_started = true
	set_process(false)
	_freeze_player(true)
	_block_menu_overlay(true)

	var tween := create_tween()
	tween.tween_property(_black, "modulate:a", 1.0, fade_time)
	if subtitle != "":
		_label.text = subtitle
		tween.tween_property(_label, "modulate:a", 1.0, text_fade_time)
	tween.tween_interval(hold_time)
	await tween.finished

	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)


# Built in code so no scene has to wire it up — same as the inventory.
func _build_ui() -> void:
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.modulate.a = 0.0
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)

	_label = Label.new()
	_label.modulate.a = 0.0
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 44)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _freeze_player(frozen: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_can_move"):
			p.set_can_move(not frozen)


# Another chapter's autoload sits on top of everything with its own Esc
# handler — hide it so the fade can't be escaped past.
func _block_menu_overlay(blocked: bool) -> void:
	var overlay = get_node_or_null("/root/ChapterEscape")
	if overlay:
		overlay.visible = not blocked
		overlay.set_process_input(not blocked)
