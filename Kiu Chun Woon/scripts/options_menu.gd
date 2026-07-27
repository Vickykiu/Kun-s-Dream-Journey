extends Control

## Options screen for Master and Music bus volume controls.

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"

@onready var options_card: PanelContainer = %OptionsCard
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var back_button: Button = %BackButton


func _ready() -> void:
	MusicManager.play_menu_music()

	master_slider.set_value_no_signal(MusicManager.get_master_volume())
	music_slider.set_value_no_signal(MusicManager.get_music_volume())
	_update_percentage_labels()

	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	back_button.grab_focus()

	options_card.modulate.a = 0.0
	var intro := create_tween()
	intro.tween_property(options_card, "modulate:a", 1.0, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _on_master_volume_changed(value: float) -> void:
	MusicManager.set_master_volume(value)
	_update_percentage_labels()


func _on_music_volume_changed(value: float) -> void:
	MusicManager.set_music_volume(value)
	_update_percentage_labels()


func _on_back_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	MusicManager.save_settings()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _update_percentage_labels() -> void:
	master_value.text = "%d%%" % roundi(master_slider.value * 100.0)
	music_value.text = "%d%%" % roundi(music_slider.value * 100.0)
