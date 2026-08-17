extends CanvasLayer


const HOSPITAL_SCENE = preload(
	"res://Lew Jia Jia/scenes/HospitalScene.tscn"
)


@onready var story_label: Label = $StoryLabel
@onready var skip_button: Button = $SkipButton


var cutscene_skipped: bool = false
var story_finished: bool = false
var active_tween: Tween = null


func _ready() -> void:
	skip_button.visible = false
	story_label.modulate.a = 0.0

	play_vent_story()


# ==================================================
# Space Skip
# ==================================================

func _input(event: InputEvent) -> void:
	if cutscene_skipped or story_finished:
		return

	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			get_viewport().set_input_as_handled()

			skip_vent_story()


# ==================================================
# Vent Story
# ==================================================

func play_vent_story() -> void:
	await show_story_line(
		"Kun crawls into the narrow ventilation shaft."
	)

	if cutscene_skipped:
		return

	await show_story_line(
		"The passage is dark, cold, and barely wide enough to move through."
	)

	if cutscene_skipped:
		return

	await show_story_line(
		"After what feels like an eternity, a faint light appears ahead."
	)

	if cutscene_skipped:
		return

	await show_story_line(
		"From somewhere outside, the sound of police sirens grows louder."
	)

	if cutscene_skipped:
		return

	show_final_message()


# ==================================================
# Story Line
# ==================================================

func show_story_line(text: String) -> void:
	story_label.text = text
	story_label.modulate.a = 0.0

	await fade_label_in()

	if cutscene_skipped:
		return

	await get_tree().create_timer(
		2.5
	).timeout

	if cutscene_skipped:
		return

	await fade_label_out()


# ==================================================
# Fade In
# ==================================================

func fade_label_in() -> void:
	if active_tween:
		active_tween.kill()

	active_tween = create_tween()

	active_tween.tween_property(
		story_label,
		"modulate:a",
		1.0,
		1.0
	)

	await active_tween.finished


# ==================================================
# Fade Out
# ==================================================

func fade_label_out() -> void:
	if active_tween:
		active_tween.kill()

	active_tween = create_tween()

	active_tween.tween_property(
		story_label,
		"modulate:a",
		0.0,
		1.0
	)

	await active_tween.finished


# ==================================================
# Skip Story
# ==================================================

func skip_vent_story() -> void:
	cutscene_skipped = true

	if active_tween:
		active_tween.kill()
		active_tween = null

	show_final_message()


# ==================================================
# Final Vent Message
# ==================================================

func show_final_message() -> void:
	story_finished = true

	story_label.text = (
		"I made it out...\n\n"
		+ "But what happened to everyone else?"
	)

	story_label.modulate.a = 1.0
	skip_button.visible = true


# ==================================================
# Continue to Hospital
# ==================================================

func _on_skip_button_pressed() -> void:
	if not story_finished:
		return

	skip_button.disabled = true

	get_tree().change_scene_to_packed(
		HOSPITAL_SCENE
	)
