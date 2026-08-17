@tool
extends CanvasLayer


signal vent_entered


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var vent_lines: Array[DialogueLine] = []:
	set(value):
		vent_lines = DialogueLine.fill_blanks(value)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	await get_tree().process_frame

	if not vent_lines.is_empty():
		Dialogue.show_lines(
			vent_lines,
			portrait,
			speaker_name
		)

		await Dialogue.finished


func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()


func _on_enter_vent_button_pressed() -> void:
	if Dialogue.is_active():
		return

	vent_entered.emit()

	queue_free()
