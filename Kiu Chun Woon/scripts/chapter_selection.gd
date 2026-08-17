extends Control

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const CHAPTER_ONE_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_rhythm.tscn"
const CHAPTER_TWO_SCENE := "res://Lau Kah Kei/scenes/corridor.tscn"
const CHAPTER_THREE_SCENE := "res://Lew Jia Jia/scenes/Chapter3_RoomB13.tscn"
const CHAPTER_FOUR_SCENE := "res://Tay Hong Fei/scene/Chapter 4-1.tscn"

@onready var chapter_one_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/ChapterGrid/ChapterOneButton
)
@onready var chapter_two_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/ChapterGrid/ChapterTwoButton
)
@onready var chapter_three_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/ChapterGrid/ChapterThreeButton
)
@onready var chapter_four_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/ChapterGrid/ChapterFourButton
)
@onready var back_button: Button = (
	$SafeMargin/Center/ChapterCard/Column/BackButton
)

@onready var hover_buttons: Array[Button] = [
	chapter_one_button,
	chapter_two_button,
	chapter_three_button,
	chapter_four_button,
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
	_open_chapter(CHAPTER_ONE_SCENE)


func _on_chapter_two_pressed() -> void:
	_open_chapter(CHAPTER_TWO_SCENE)


func _on_chapter_three_pressed() -> void:
	_open_chapter(CHAPTER_THREE_SCENE)


func _on_chapter_four_pressed() -> void:
	_open_chapter(CHAPTER_FOUR_SCENE)


func _open_chapter(scene_path: String) -> void:
	MusicManager.stop_music()
	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Unable to open chapter scene: " + scene_path)


func _on_back_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
