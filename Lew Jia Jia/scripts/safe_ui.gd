@tool
extends CanvasLayer


# Signals sent to Chapter 3
signal safe_opened
signal file_taken


# Dialogue settings
@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var file_lines: Array[DialogueLine] = []:
	set(value):
		file_lines = DialogueLine.fill_blanks(value)


# Node references
@onready var display = $Label
@onready var sfx_button = $BtnSound
@onready var safe_bg = $TextureRect
@onready var folder_btn = $FolderBtn
@onready var file_detail = $FileDetail


const CORRECT_PASS: String = "31512"

var current_input: String = ""
var is_unlocked: bool = false
var has_read_file: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	display.text = ""
	folder_btn.visible = false
	file_detail.visible = false


# =========================
# Keypad input
# =========================
func add_digit(digit: String) -> void:
	if is_unlocked:
		return

	if sfx_button:
		sfx_button.play()

	if current_input.length() < 5:
		current_input += digit
		display.text = current_input


func _on_btn_1_pressed() -> void:
	add_digit("1")


func _on_btn_2_pressed() -> void:
	add_digit("2")


func _on_btn_3_pressed() -> void:
	add_digit("3")


func _on_btn_4_pressed() -> void:
	add_digit("4")


func _on_btn_5_pressed() -> void:
	add_digit("5")


func _on_btn_6_pressed() -> void:
	add_digit("6")


func _on_btn_7_pressed() -> void:
	add_digit("7")


func _on_btn_8_pressed() -> void:
	add_digit("8")


func _on_btn_9_pressed() -> void:
	add_digit("9")


func _on_btn_0_pressed() -> void:
	add_digit("0")


func _on_btn_clear_pressed() -> void:
	if is_unlocked:
		return

	current_input = ""
	display.text = ""


# =========================
# Enter password
# =========================
func _on_btn_enter_pressed() -> void:
	if is_unlocked:
		return

	if current_input == CORRECT_PASS:
		print("Password correct! Safe opened!")

		is_unlocked = true
		current_input = ""
		display.text = ""

		safe_bg.texture = preload(
			"res://Lew Jia Jia/assets/Safe_OpenEmpty.png"
		)

		folder_btn.visible = true
		safe_opened.emit()

	else:
		print("Incorrect password!")

		display.text = "ERROR"
		current_input = ""


# =========================
# Death-list file
# =========================
func _on_folder_btn_pressed() -> void:
	file_detail.visible = true

	if has_read_file:
		return

	has_read_file = true

	await get_tree().process_frame

	if not file_lines.is_empty():
		Dialogue.show_lines(
			file_lines,
			portrait,
			speaker_name
		)
		await Dialogue.finished

	file_taken.emit()


func _on_close_file_btn_pressed() -> void:
	if Dialogue.is_active():
		return

	file_detail.visible = false


# =========================
# Exit Safe UI
# =========================
func _on_btn_exit_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()
