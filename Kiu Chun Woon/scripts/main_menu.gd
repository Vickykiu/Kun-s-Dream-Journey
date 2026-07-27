extends Control

## Main-menu navigation for Kiu Chun Woon's Chapter 1 foundation.

const CHAPTER_ONE_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_placeholder.tscn"
const CHAPTER_SELECTION_SCENE := "res://Kiu Chun Woon/scenes/chapter_selection.tscn"
const OPTIONS_SCENE := "res://Kiu Chun Woon/scenes/options_menu.tscn"

@onready var menu_card: PanelContainer = %MenuCard
@onready var start_button: Button = %StartButton


func _ready() -> void:
	MusicManager.play_menu_music()
	start_button.grab_focus()
	_play_intro_animation()


func _play_intro_animation() -> void:
	# Wait for the responsive containers to calculate their final positions.
	# Animating a container child before this point can make it jump on resize.
	await get_tree().process_frame
	var resting_x := menu_card.position.x

	# A short entrance animation keeps the menu polished without delaying input.
	menu_card.modulate.a = 0.0
	menu_card.position.x = resting_x + 26.0
	var intro := create_tween().set_parallel(true)
	intro.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro.tween_property(menu_card, "modulate:a", 1.0, 0.55)
	intro.tween_property(menu_card, "position:x", resting_x, 0.55)


func _on_start_pressed() -> void:
	MusicManager.stop_music()
	get_tree().change_scene_to_file(CHAPTER_ONE_SCENE)


func _on_chapter_selection_pressed() -> void:
	get_tree().change_scene_to_file(CHAPTER_SELECTION_SCENE)


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_quit_pressed() -> void:
	MusicManager.save_settings()
	get_tree().quit()
