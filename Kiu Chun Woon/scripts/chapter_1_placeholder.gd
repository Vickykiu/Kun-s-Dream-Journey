extends Control

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const RHYTHM_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_rhythm.tscn"
const MEI := preload("res://Kiu Chun Woon/assets/images/reactions/Teacher_Mei_Normal.png")
const KUNKUN := preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_great.png")
const KUNKUN_NERVOUS := preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_too_early.png")

@onready var chapter_dialogue = %ChapterDialogue


func _ready() -> void:
	chapter_dialogue.finished.connect(_on_dialogue_finished)
	%BeginButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _on_main_menu_pressed() -> void:
	_return_to_main_menu()


func _on_begin_pressed() -> void:
	if chapter_dialogue.active:
		return
	chapter_dialogue.start([
		{"speaker": "Teacher Mei", "portrait": MEI, "emotion": "happy", "mood": "Welcoming",
			"text": "Welcome to Starlight Training Camp, Kunkun. Your first lesson begins in the practice room."},
		{"speaker": "Kunkun", "portrait": KUNKUN, "emotion": "calm", "mood": "Hopeful",
			"text": "I have waited so long for this. What do I need to do?"},
		{"speaker": "Teacher Mei", "portrait": MEI, "emotion": "calm", "mood": "Explaining",
			"text": "Press the matching arrow key as each note reaches its target. Reach at least 50% accuracy to pass. Watch your timing, not just your score."},
		{"speaker": "Kunkun", "portrait": KUNKUN_NERVOUS, "emotion": "worried", "mood": "Nervous",
			"text": "Why does it feel like everyone is watching me? Never mind... I will follow the rhythm."},
	])


func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(RHYTHM_SCENE)


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
