extends CanvasLayer

signal sheet_music_selected
signal book_selected
signal metronome_selected


func _on_sheet_music_button_pressed() -> void:
	sheet_music_selected.emit()


func _on_book_button_pressed() -> void:
	book_selected.emit()


func _on_metronome_button_pressed() -> void:
	metronome_selected.emit()


func _on_close_button_pressed() -> void:
	queue_free()
