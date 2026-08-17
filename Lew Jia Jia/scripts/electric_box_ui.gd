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
@onready var solved_image: TextureRect = $SolvedImage

@onready var open_button: TextureButton = $OpenButton
@onready var blue_button: TextureButton = $BlueButton
@onready var red_button: TextureButton = $RedButton
@onready var green_button: TextureButton = $GreenButton
@onready var yellow_button: TextureButton = $YellowButton


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


# =========================
# Initial state
# =========================
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Initially display the closed electrical box
	closed_image.visible = true
	open_image.visible = false
	solved_image.visible = false
	
	open_button.visible = true
	open_button.disabled = false

	# Wire buttons only appear after opening the box
	_set_wire_buttons_visible(false)

	# Ensure all buttons start enabled
	_enable_wire_button(blue_button)
	_enable_wire_button(red_button)
	_enable_wire_button(green_button)
	_enable_wire_button(yellow_button)
	


# =========================
# Open electrical box
# =========================
func _on_open_button_pressed() -> void:
	if is_box_open:
		return

	if Dialogue.is_active():
		return

	is_box_open = true

	closed_image.visible = false
	open_image.visible = true
	solved_image.visible = false

	open_button.visible = false
	open_button.disabled = true

	if GameState.has_item("wire_cutters"):
		_set_wire_buttons_visible(true)

		if not intro_lines.is_empty():
			Dialogue.show_lines(
				intro_lines,
				portrait,
				speaker_name
			)
	else:
		_set_wire_buttons_visible(false)

		if not need_tool_lines.is_empty():
			Dialogue.show_lines(
				need_tool_lines,
				portrait,
				speaker_name
			)


# =========================
# Wire button signals
# =========================
func _on_blue_button_pressed() -> void:
	_try_cut_wire(
		"blue",
		blue_button
	)


func _on_red_button_pressed() -> void:
	_try_cut_wire(
		"red",
		red_button
	)


func _on_green_button_pressed() -> void:
	_try_cut_wire(
		"green",
		green_button
	)


func _on_yellow_button_pressed() -> void:
	_try_cut_wire(
		"yellow",
		yellow_button
	)


# =========================
# Check selected wire
# =========================
func _try_cut_wire(
	wire_colour: String,
	wire_button: TextureButton
) -> void:
	if not is_box_open:
		return

	if is_solved:
		return

	if Dialogue.is_active():
		return

	if not GameState.has_item("wire_cutters"):
		if not need_tool_lines.is_empty():
			Dialogue.show_lines(
				need_tool_lines,
				portrait,
				speaker_name
			)
		return

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
		print(
			"Wrong wire. Expected: ",
			expected_colour,
			", selected: ",
			wire_colour
		)

		_reset_puzzle()


# =========================
# Wrong wire selected
# =========================
func _reset_puzzle() -> void:
	current_step = 0

	_enable_wire_button(blue_button)
	_enable_wire_button(red_button)
	_enable_wire_button(green_button)
	_enable_wire_button(yellow_button)

	if not wrong_lines.is_empty():
		Dialogue.show_lines(
			wrong_lines,
			portrait,
			speaker_name
		)


func _enable_wire_button(
	button: TextureButton
) -> void:
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP


# =========================
# Puzzle completed
# =========================
func _complete_puzzle() -> void:
	is_solved = true

	_disable_all_wire_buttons()
	_set_wire_buttons_visible(false)

	# Display all wires in their cut state
	open_image.visible = false
	solved_image.visible = true

	if not solved_lines.is_empty():
		Dialogue.show_lines(
			solved_lines,
			portrait,
			speaker_name
		)
		await Dialogue.finished

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
func _set_wire_buttons_visible(
	value: bool
) -> void:
	blue_button.visible = value
	red_button.visible = value
	green_button.visible = value
	yellow_button.visible = value


# =========================
# Close ElectricBox UI
# =========================
func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()
