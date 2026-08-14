@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var hint_lines: Array[DialogueLine] = []:
	set(value):
		hint_lines = DialogueLine.fill_blanks(value)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	await get_tree().process_frame

	if not hint_lines.is_empty():
		Dialogue.show_lines(
			hint_lines,
			portrait,
			speaker_name
		)


func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()
