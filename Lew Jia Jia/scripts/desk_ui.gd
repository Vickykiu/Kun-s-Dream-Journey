@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var sheet_music_lines: Array[DialogueLine] = []:
	set(value):
		sheet_music_lines = DialogueLine.fill_blanks(value)

@export var book_lines: Array[DialogueLine] = []:
	set(value):
		book_lines = DialogueLine.fill_blanks(value)

@export var metronome_lines: Array[DialogueLine] = []:
	set(value):
		metronome_lines = DialogueLine.fill_blanks(value)


func _on_sheet_music_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if sheet_music_lines.is_empty():
		return

	Dialogue.show_lines(
		sheet_music_lines,
		portrait,
		speaker_name
	)


func _on_book_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if book_lines.is_empty():
		return

	Dialogue.show_lines(
		book_lines,
		portrait,
		speaker_name
	)


func _on_metronome_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if metronome_lines.is_empty():
		return

	Dialogue.show_lines(
		metronome_lines,
		portrait,
		speaker_name
	)


func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()
