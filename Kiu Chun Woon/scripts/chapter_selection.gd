extends Control

## Chapter select of 2-4. Chapters 2–4 remain locked.

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const CHAPTER_ONE_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_placeholder.tscn"

@onready var chapter_one_button: Button = %ChapterOneButton
@onready var back_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/BackButton
)

@onready var hover_buttons: Array[Button] = [
	chapter_one_button,
	back_button
]


func _ready() -> void:
	MusicManager.play_menu_music()

	for button in hover_buttons:
		button.mouse_entered.connect(
			_on_button_mouse_entered.bind(button)
		)
		button.mouse_exited.connect(
			_on_button_mouse_exited.bind(button)
		)


func _on_button_mouse_entered(button: Button) -> void:
	button.grab_focus()


func _on_button_mouse_exited(button: Button) -> void:
	if button.has_focus():
		button.release_focus()


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
