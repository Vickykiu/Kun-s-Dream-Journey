extends Control

## Temporary Chapter 1 hand-off scene.
## Replace this scene with the rhythm-training level when Chapter 1 is implemented.

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"


func _ready() -> void:
	%MainMenuButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _on_main_menu_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
