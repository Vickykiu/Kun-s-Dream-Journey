extends CanvasLayer

# Autoload singleton. Press I anywhere in the game to see what Kunkun is
# carrying; press I or Esc to close. The player can't walk while it's open.
#
# Nothing to set up per scene — this builds its own UI on start, and reads
# whatever GameState.items holds. To make an item show up here, add it to
# ItemDB and call GameState.add_item("its_id") where it gets picked up.

const TITLE_SIZE := 40
const NAME_SIZE := 28
const BODY_SIZE := 20

var _root: Control
var _panel: PanelContainer
var _list: VBoxContainer
var _counter: Label

var _open := false


func _ready():
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()


# --- public API ---------------------------------------------------------

func open() -> void:
	if _open:
		return
	_open = true
	_refresh()
	_root.show()
	_freeze_player(true)
	_block_menu_overlay(true)


func close() -> void:
	if not _open:
		return
	_open = false
	_root.hide()
	_freeze_player(false)
	_block_menu_overlay(false)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func is_open() -> bool:
	return _open


# --- input --------------------------------------------------------------

func _input(event):
	# The dialogue box and the close-up own the screen while they're up — no
	# rummaging through the bag in the middle of someone's sentence, and no
	# opening it on top of an item the player is still holding up.
	if Dialogue.is_active() or ItemView.is_active():
		return

	var was_open := _open

	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		toggle()
	elif was_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif was_open and (event is InputEventKey or event is InputEventJoypadButton):
		# Nothing else gets through until it's closed with I or Esc. Mouse
		# events are deliberately not swallowed, or the item list would stop
		# scrolling.
		get_viewport().set_input_as_handled()


# --- contents -----------------------------------------------------------

func _refresh():
	for child in _list.get_children():
		child.queue_free()

	if GameState.items.is_empty():
		_list.add_child(_make_body_label("Your pockets are empty."))
	else:
		for id in GameState.items:
			_list.add_child(_make_entry(id))

	_counter.text = "Evidence  %d / %d" % [
		GameState.evidence_count(),
		ItemDB.total_evidence(),
	]


# One row: icon on the left (if the item has one), name + description right.
func _make_entry(id: String) -> Control:
	var item = ItemDB.get_item(id)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var icon_path = item.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon = TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

	var text_column = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 4)
	row.add_child(text_column)

	var title = Label.new()
	title.text = item["name"]
	if item.get("evidence", false):
		title.text += "   [EVIDENCE]"
	title.add_theme_font_size_override("font_size", NAME_SIZE)
	title.add_theme_color_override(
		"font_color",
		Color(0.95, 0.85, 0.5) if item.get("evidence", false) else Color(0.92, 0.92, 0.92)
	)
	text_column.add_child(title)

	text_column.add_child(_make_body_label(item["description"]))
	return row


func _make_body_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", BODY_SIZE)
	label.modulate = Color(1, 1, 1, 0.75)
	return label


# The "ESC MAIN MENU" overlay is another chapter's autoload (ChapterEscape,
# listed in project.godot) sitting on top of everything with its own Esc
# handler and a clickable button. Hiding the whole layer takes out both at
# once — a hidden CanvasLayer doesn't draw, and its button stops receiving
# clicks — so Esc closes the bag instead of quitting to the menu. Done from
# this side on purpose: their script needs no changes.
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


# --- UI, built in code so no scene has to wire it up --------------------

func _build_ui():
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 360
	_panel.offset_right = -360
	_panel.offset_top = 140
	_panel.offset_bottom = -140
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.04, 0.07, 0.96)
	box.border_color = Color(0.75, 0.72, 0.55, 0.8)
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(36)
	_panel.add_theme_stylebox_override("panel", box)
	_root.add_child(_panel)

	var rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	_panel.add_child(rows)

	var title = Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	rows.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 24)
	scroll.add_child(_list)

	var footer = HBoxContainer.new()
	rows.add_child(footer)

	_counter = Label.new()
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter.add_theme_font_size_override("font_size", BODY_SIZE)
	_counter.modulate = Color(1, 1, 1, 0.75)
	footer.add_child(_counter)

	var hint = Label.new()
	hint.text = "[I] or [Esc] to close"
	hint.add_theme_font_size_override("font_size", BODY_SIZE)
	hint.modulate = Color(1, 1, 1, 0.45)
	footer.add_child(hint)
