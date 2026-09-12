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
@onready var display: Label = $Label
@onready var sfx_button: AudioStreamPlayer = $BtnSound
@onready var safe_bg: TextureRect = $TextureRect
@onready var folder_btn: Button = $FolderBtn
@onready var file_detail: Control = $FileDetail

@onready var close_hint: Label = $CloseHint
@onready var safe_open_sound: AudioStreamPlayer = $SafeOpenSound
@onready var close_sound: AudioStreamPlayer = $CloseSound


const CORRECT_PASS: String = "31512"

var current_input: String = ""
var is_unlocked: bool = false
var is_opening: bool = false
var has_read_file: bool = false
var death_list_taken: bool = false
var can_use_e: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	display.text = ""
	folder_btn.visible = false
	file_detail.visible = false

	close_hint.visible = false
	close_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	death_list_taken = GameState.has_item("death_list")
	has_read_file = death_list_taken

	# 避免打开 Safe UI 的那次 E 立即把它关闭。
	await get_tree().process_frame
	can_use_e = true


# =========================
# E hint and closing
# =========================

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var show_hint: bool = (
		can_use_e
		and not is_closing
		and not Dialogue.is_active()
	)

	close_hint.visible = show_hint

	if show_hint:
		if file_detail.visible:
			close_hint.text = "Press E to close file"
		else:
			close_hint.text = "Press E to close"


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if (
		not can_use_e
		or is_closing
		or is_opening
		or Dialogue.is_active()
	):
		return

	get_viewport().set_input_as_handled()

	# First E closes the file; another E closes the Safe UI.
	if file_detail.visible:
		file_detail.visible = false
	else:
		close_ui()


func close_ui() -> void:
	is_closing = true
	can_use_e = false
	close_hint.visible = false

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()


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
	if is_unlocked or is_opening:
		return

	if current_input == CORRECT_PASS:
		await unlock_safe()
	else:
		show_password_error()


func unlock_safe() -> void:
	print("Password correct! Safe opened!")

	is_opening = true
	is_unlocked = true
	current_input = ""
	display.text = ""

	safe_bg.texture = preload(
		"res://Lew Jia Jia/assets/Safe_OpenEmpty.png"
	)

	folder_btn.visible = true

	if safe_open_sound.stream:
		safe_open_sound.play()
		await safe_open_sound.finished
	else:
		push_warning("SafeOpenSound has no audio file.")

	is_opening = false
	safe_opened.emit()


func show_password_error() -> void:
	print("Incorrect password!")
	display.text = "ERROR"
	current_input = ""


# =========================
# Death-list file
# =========================

func _on_folder_btn_pressed() -> void:
	if is_closing or Dialogue.is_active():
		return

	file_detail.visible = true

	# 避免用于关闭最后一句对白的 E 同时关闭文件。
	can_use_e = false
	close_hint.visible = false

	if has_read_file:
		await get_tree().process_frame
		can_use_e = true
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

	if not GameState.has_item("death_list"):
		GameState.add_item("death_list")

		death_list_taken = true
		file_taken.emit()

		Dialogue.show_text(
			"(Added to inventory: Death List)"
		)
		await Dialogue.finished

	# 最后一次推进对白的 E 处理完后，才显示关闭提示。
	await get_tree().process_frame
	can_use_e = true
