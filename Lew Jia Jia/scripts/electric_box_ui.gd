@tool
extends CanvasLayer


signal puzzle_solved


# =========================
# Dialogue settings
# =========================

@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var intro_lines: Array[DialogueLine] = []:
	set(value):
		intro_lines = DialogueLine.fill_blanks(value)

@export var wrong_lines: Array[DialogueLine] = []:
	set(value):
		wrong_lines = DialogueLine.fill_blanks(value)

@export var solved_lines: Array[DialogueLine] = []:
	set(value):
		solved_lines = DialogueLine.fill_blanks(value)

@export var need_tool_lines: Array[DialogueLine] = []:
	set(value):
		need_tool_lines = DialogueLine.fill_blanks(value)


# =========================
# Node references
# =========================

@onready var closed_image: TextureRect = $ClosedImage
@onready var open_image: TextureRect = $OpenImage
@onready var cut_1_image: TextureRect = $Cut1Image
@onready var cut_2_image: TextureRect = $Cut2Image
@onready var cut_3_image: TextureRect = $Cut3Image
@onready var solved_image: TextureRect = $SolvedImage

@onready var open_button: TextureButton = $OpenButton
@onready var blue_button: TextureButton = $BlueButton
@onready var red_button: TextureButton = $RedButton
@onready var green_button: TextureButton = $GreenButton
@onready var yellow_button: TextureButton = $YellowButton

@onready var close_hint: Label = $CloseHint
@onready var close_sound: AudioStreamPlayer = $CloseSound
@onready var wire_cut_sound: AudioStreamPlayer = $WireCutSound


# =========================
# Puzzle settings
# =========================

const CORRECT_ORDER: Array[String] = [
	"blue",
	"red",
	"green",
	"yellow"
]

var current_step: int = 0
var is_box_open: bool = false
var is_solved: bool = false
var can_close: bool = false
var is_closing: bool = false


# =========================
# Initial state
# =========================

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = false

	# Images and hint must not intercept clicks on the wire buttons.
	closed_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	open_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_1_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_2_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_3_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	solved_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	closed_image.visible = true
	_show_cut_progress(0)
	solved_image.visible = false

	open_button.visible = true
	open_button.disabled = false

	_set_wire_buttons_visible(false)

	_enable_wire_button(blue_button)
	_enable_wire_button(red_button)
	_enable_wire_button(green_button)
	_enable_wire_button(yellow_button)

	# Opening the UI with E must not immediately close it.
	await get_tree().process_frame
	can_close = true


# =========================
# Red E hint and E to close
# =========================

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = (
		can_close
		and not is_closing
		and not Dialogue.is_active()
	)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	# E belongs to Dialogue while a line is showing.
	if not can_close or is_closing or Dialogue.is_active():
		return

	get_viewport().set_input_as_handled()
	close_ui()


func close_ui() -> void:
	is_closing = true
	close_hint.visible = false

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()


# =========================
# Dialogue helper
# =========================

func _show_puzzle_dialogue(lines: Array[DialogueLine]) -> void:
	if lines.is_empty():
		return

	# The E used to finish dialogue must not also close this UI.
	can_close = false
	close_hint.visible = false

	Dialogue.show_lines(
		lines,
		portrait,
		speaker_name
	)

	await Dialogue.finished
	await get_tree().process_frame

	if not is_closing:
		can_close = true


# =========================
# Open electrical box
# =========================

func _on_open_button_pressed() -> void:
	if is_box_open or Dialogue.is_active():
		return

	is_box_open = true

	closed_image.visible = false
	_show_cut_progress(0)
	solved_image.visible = false

	open_button.visible = false
	open_button.disabled = true

	if GameState.has_item("wire_cutters"):
		_set_wire_buttons_visible(true)
		_show_puzzle_dialogue(intro_lines)
	else:
		_set_wire_buttons_visible(false)
		_show_puzzle_dialogue(need_tool_lines)


# =========================
# Wire button signals
# =========================

func _on_blue_button_pressed() -> void:
	_try_cut_wire("blue", blue_button)


func _on_red_button_pressed() -> void:
	_try_cut_wire("red", red_button)


func _on_green_button_pressed() -> void:
	_try_cut_wire("green", green_button)


func _on_yellow_button_pressed() -> void:
	_try_cut_wire("yellow", yellow_button)


# =========================
# Check selected wire
# =========================

func _try_cut_wire(
	wire_colour: String,
	wire_button: TextureButton
) -> void:
	if not is_box_open or is_solved or Dialogue.is_active():
		return

	if not GameState.has_item("wire_cutters"):
		_show_puzzle_dialogue(need_tool_lines)
		return

	if wire_cut_sound.stream:
		wire_cut_sound.play()

	var expected_colour: String = CORRECT_ORDER[current_step]

	if wire_colour == expected_colour:
		wire_button.disabled = true
		wire_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		current_step += 1

		print(
			"Correct wire: ",
			wire_colour,
			" (",
			current_step,
			"/4)"
		)

		if current_step >= CORRECT_ORDER.size():
			_complete_puzzle()
		else:
			_show_cut_progress(current_step)
	else:
		print(
			"Wrong wire. Expected: ",
			expected_colour,
			", selected: ",
			wire_colour
		)

		_reset_puzzle()


# =========================
# Show correct image
# =========================

func _show_cut_progress(step: int) -> void:
	open_image.visible = step == 0
	cut_1_image.visible = step == 1
	cut_2_image.visible = step == 2
	cut_3_image.visible = step == 3


# =========================
# Wrong wire selected
# =========================

func _reset_puzzle() -> void:
	current_step = 0
	_show_cut_progress(0)

	_enable_wire_button(blue_button)
	_enable_wire_button(red_button)
	_enable_wire_button(green_button)
	_enable_wire_button(yellow_button)

	_show_puzzle_dialogue(wrong_lines)


func _enable_wire_button(button: TextureButton) -> void:
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP


# =========================
# Puzzle completed
# =========================

func _complete_puzzle() -> void:
	is_solved = true

	_disable_all_wire_buttons()
	_set_wire_buttons_visible(false)

	open_image.visible = false
	cut_1_image.visible = false
	cut_2_image.visible = false
	cut_3_image.visible = false
	solved_image.visible = true

	if not solved_lines.is_empty():
		await _show_puzzle_dialogue(solved_lines)

	puzzle_solved.emit()


func _disable_all_wire_buttons() -> void:
	blue_button.disabled = true
	red_button.disabled = true
	green_button.disabled = true
	yellow_button.disabled = true

	blue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	green_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yellow_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


# =========================
# Show or hide wire buttons
# =========================

func _set_wire_buttons_visible(value: bool) -> void:
	blue_button.visible = value
	red_button.visible = value
	green_button.visible = value
	yellow_button.visible = value
