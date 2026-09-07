extends CanvasLayer


@export var chapter_4_scene: PackedScene


@onready var story_label: Label = $StoryLabel
@onready var white_flash: ColorRect = $WhiteFlash


func _ready() -> void:
	story_label.modulate.a = 0.0
	white_flash.modulate.a = 0.0

	await play_transition()

	if chapter_4_scene:
		get_tree().change_scene_to_packed(
			chapter_4_scene
		)
	else:
		push_error(
			"Chapter 4 Scene has not been assigned."
		)


func play_transition() -> void:
	# First narrative line.
	story_label.text = (
		"The moment Kun opens the Death List,\n"
		+ "a blinding white light bursts from its pages."
	)

	await fade_text_in()

	await get_tree().create_timer(
		2.0
	).timeout

	await fade_text_out()

	# White light consumes the entire screen.
	var flash_tween := create_tween()

	flash_tween.tween_property(
		white_flash,
		"modulate:a",
		1.0,
		0.7
	)

	await flash_tween.finished

	await get_tree().create_timer(
		1.5
	).timeout


func fade_text_in() -> void:
	var tween := create_tween()

	tween.tween_property(
		story_label,
		"modulate:a",
		1.0,
		1.0
	)

	await tween.finished


func fade_text_out() -> void:
	var tween := create_tween()

	tween.tween_property(
		story_label,
		"modulate:a",
		0.0,
		0.8
	)

	await tween.finished
