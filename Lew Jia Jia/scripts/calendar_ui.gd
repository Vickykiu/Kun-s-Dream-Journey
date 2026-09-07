@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var calendar_lines: Array[DialogueLine] = []:
	set(value):
		calendar_lines = DialogueLine.fill_blanks(value)


@onready var close_button: Button = $CloseButton
@onready var close_sound: AudioStreamPlayer = $CloseSound


var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	await get_tree().process_frame

	if not calendar_lines.is_empty():
		Dialogue.show_lines(
			calendar_lines,
			portrait,
			speaker_name
		)


func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if is_closing:
		return

	is_closing = true
	close_button.disabled = true

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
