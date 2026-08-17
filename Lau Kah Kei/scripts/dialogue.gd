extends CanvasLayer

# Autoload singleton, built from scenes/dialogue.tscn. A text box at the
# bottom of the screen that any script can use to say something:
#
#     Dialogue.show_lines(["The bed is made.", "Nobody slept here."])
#     Dialogue.show_lines(lines, portrait_texture, "Teacher Mei")
#     await Dialogue.finished        # optional, waits until the box closes
#
# A page can be a plain String, or a DialogueLine resource when it needs its
# own expression (see dialogue_line.gd). Mixing both in one array is fine —
# anything without a face of its own falls back to the `portrait` argument.
#
# The player is frozen while it's open, and E / Space / Enter turns the page.
#
# LAYOUT IS EDITED IN THE EDITOR, NOT HERE. Open scenes/dialogue.tscn and
# drag things around; what you see there is what you get in game. NameRow
# and Rows live inside Panel, so moving or resizing the frame carries the
# name tag and the words along with it. Portrait is a separate sibling and
# stays put on its own. The placeholder art and sample text in that scene
# are only there so there's something to look at while positioning; both
# get replaced the moment a real line of dialogue plays.

signal finished
signal choice_selected(choice: String)

@onready var _root: Control = $Root
@onready var _panel: Panel = $Root/Panel
@onready var _name_tag: Control = $Root/Panel/NameRow
@onready var _name: Label = $Root/Panel/NameRow/NameBox/Name
@onready var _rows: VBoxContainer = $Root/Panel/Rows
@onready var _label: Label = $Root/Panel/Rows/Text
@onready var _hint: Label = $Root/Panel/Rows/Hint
@onready var _portrait: TextureRect = $Root/Portrait

@onready var _choices: HBoxContainer = (
	$Root/Panel/Rows/Choices
)

@onready var _accept_button: Button = (
	$Root/Panel/Rows/Choices/AcceptButton
)

@onready var _reject_button: Button = (
	$Root/Panel/Rows/Choices/RejectButton
)

var _lines: Array = []
var _default_portrait: Texture2D = null      # what a page without its own face falls back to
var _index := 0
var _active := false
var _choice_active := false

# Where the text block was left in the editor, i.e. clear of the portrait.
var _rows_left := 0.0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS      # keeps working if the game is paused
	_rows_left = _rows.offset_left

	_choices.hide()

	_accept_button.pressed.connect(
		_on_accept_pressed
	)

	_reject_button.pressed.connect(
		_on_reject_pressed
	)

	_root.hide()


# --- public API ---------------------------------------------------------

# `portrait` and `speaker` are optional — leave them out and the box is
# plain text with no face and no name tag, which is what looking at
# furniture wants.
func show_lines(
	lines: Array,
	portrait: Texture2D = null,
	speaker: String = ""
) -> void:
	if lines.is_empty():
		return

	_lines = lines
	_default_portrait = portrait
	_index = 0
	_active = true
	_choice_active = false

	_choices.hide()

	# Whether there's a face at all is decided once, for the whole
	# conversation, because the text is indented around it — deciding it
	# per page would shove the words sideways mid-sentence.
	_portrait.visible = (
		portrait != null
		or _any_page_has_a_face(lines)
	)

	_name.text = speaker
	_name_tag.visible = speaker != ""       # hides the whole tag, not just the word

	_root.show()
	_place_text()
	_freeze_player(true)
	_block_menu_overlay(true)
	_draw_current_line()


func show_text(
	text: String,
	portrait: Texture2D = null,
	speaker: String = ""
) -> void:
	show_lines(
		[text],
		portrait,
		speaker
	)


func show_choice(
	text: String,
	accept_text: String,
	reject_text: String,
	portrait: Texture2D = null,
	speaker: String = ""
) -> void:
	_lines = []
	_default_portrait = portrait
	_index = 0

	_active = true
	_choice_active = true

	_portrait.visible = portrait != null

	if portrait:
		_portrait.texture = portrait

	_name.text = speaker
	_name_tag.visible = speaker != ""

	_label.text = text

	_accept_button.text = accept_text
	_reject_button.text = reject_text

	_choices.show()

	_hint.text = ""

	_root.show()

	_place_text()
	_freeze_player(true)
	_block_menu_overlay(true)

	_accept_button.grab_focus()


func is_active() -> bool:
	return _active


# --- input --------------------------------------------------------------

# _input runs before _unhandled_input, so eating the key here stops the
# interactable underneath from immediately re-triggering itself.
func _input(event):
	if not _active:
		return

	if _choice_active:
		if event.is_action_pressed("ui_left"):
			_accept_button.grab_focus()

		elif event.is_action_pressed("ui_right"):
			_reject_button.grab_focus()

		elif (
			event.is_action_pressed("interact")
			or event.is_action_pressed("ui_accept")
		):
			var focused = (
				get_viewport().gui_get_focus_owner()
			)

			if focused == _accept_button:
				_on_accept_pressed()

			elif focused == _reject_button:
				_on_reject_pressed()

		if (
			event is InputEventKey
			or event is InputEventJoypadButton
		):
			get_viewport().set_input_as_handled()

		return

	if (
		event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
	):
		_advance()

	# Every other key dies here too. While the box is up, E is the only thing
	# that does anything — no opening the inventory mid-sentence, no Esc to
	# the main menu, no setting off the next object through the text. Mouse
	# events are left alone so on-screen buttons still work.
	if (
		event is InputEventKey
		or event is InputEventJoypadButton
	):
		get_viewport().set_input_as_handled()


func _advance():
	if _choice_active:
		return

	_index += 1

	if _index >= _lines.size():
		_close()

	else:
		_draw_current_line()


func _draw_current_line():
	var page = _lines[_index]

	_label.text = (
		page.text
		if page is DialogueLine
		else str(page)
	)

	# Only assign when this page actually has a face, so a page with no
	# expression and no default leaves the previous one up rather than
	# flashing an empty gap.
	var face := _portrait_of(page)

	if face:
		_portrait.texture = face

	var on_last_line = (
		_index == _lines.size() - 1
	)

	_hint.text = (
		"[E] Close"
		if on_last_line
		else "[E] Next"
	)


func _portrait_of(page) -> Texture2D:
	if (
		page is DialogueLine
		and page.portrait
	):
		return page.portrait

	return _default_portrait


func _any_page_has_a_face(
	pages: Array
) -> bool:
	for page in pages:
		if (
			page is DialogueLine
			and page.portrait
		):
			return true

	return false


# ===== Choice Result =====

func _on_accept_pressed() -> void:
	if not _choice_active:
		return

	_finish_choice(
		"accept"
	)


func _on_reject_pressed() -> void:
	if not _choice_active:
		return

	_finish_choice(
		"reject"
	)


func _finish_choice(
	choice: String
) -> void:
	if not _choice_active:
		return

	_choice_active = false
	_active = false

	_lines = []
	_default_portrait = null

	_choices.hide()
	_root.hide()

	_accept_button.release_focus()
	_reject_button.release_focus()

	_freeze_player(false)
	_block_menu_overlay(false)

	choice_selected.emit(
		choice
	)


func _close():
	_active = false
	_choice_active = false

	_lines = []
	_default_portrait = null

	_choices.hide()
	_root.hide()

	_accept_button.release_focus()
	_reject_button.release_focus()

	_freeze_player(false)
	_block_menu_overlay(false)

	finished.emit()


# The only layout still done from code. With a portrait, the words sit
# wherever they were dragged to in the editor. With no portrait there is no
# face to clear, so they slide back to the frame's inner left edge instead
# of leaving a hole where the character would have been. Rows is a child of
# Panel now, so these are offsets from the frame's own left edge.
func _place_text() -> void:
	if _portrait.visible:
		_rows.offset_left = _rows_left
		return

	var padding := 0.0
	var style := _panel.get_theme_stylebox("panel")

	if style:
		padding = style.content_margin_left

	_rows.offset_left = padding


# The "ESC MAIN MENU" overlay is another chapter's autoload (ChapterEscape,
# listed in project.godot) sitting on top of everything with its own Esc
# handler and a clickable button. Hiding the whole layer takes out both at
# once — a hidden CanvasLayer doesn't draw, and its button stops receiving
# clicks — so the box can't be escaped past by keyboard or by mouse. Done
# from this side on purpose: their script needs no changes.
func _block_menu_overlay(
	blocked: bool
) -> void:
	var overlay = (
		get_node_or_null(
			"/root/ChapterEscape"
		)
	)

	if overlay:
		overlay.visible = not blocked

		overlay.set_process_input(
			not blocked
		)


# Player nodes are in the "player" group (see player.tscn).
func _freeze_player(
	frozen: bool
) -> void:
	for p in get_tree().get_nodes_in_group(
		"player"
	):
		if p.has_method(
			"set_can_move"
		):
			p.set_can_move(
				not frozen
			)
