extends Control

## Chapter-select foundation. Chapters 2-4 are deliberately locked placeholders.

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const CHAPTER_ONE_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_placeholder.tscn"


func _ready() -> void:
	MusicManager.play_menu_music()
	%ChapterOneButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _on_chapter_one_pressed() -> void:
	MusicManager.stop_music()
	get_tree().change_scene_to_file(CHAPTER_ONE_SCENE)


func _on_back_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

