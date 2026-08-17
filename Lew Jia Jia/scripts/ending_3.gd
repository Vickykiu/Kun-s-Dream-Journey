extends CanvasLayer


@onready var ending_title: Label = $EndingTitle
@onready var ending_description: Label = $EndingDescription
@onready var dark_overlay: ColorRect = $DarkOverlay


func _ready() -> void:
	GameState.set_flag(
		"ending_3_survivor"
	)

	ending_title.modulate.a = 0.0
	ending_description.modulate.a = 0.0
	dark_overlay.color.a = 1.0

	await fade_in_ending()


func fade_in_ending() -> void:
	var background_tween := create_tween()

	background_tween.tween_property(
		dark_overlay,
		"color:a",
		0.65,
		2.0
	)

	await background_tween.finished

	var title_tween := create_tween()

	title_tween.tween_property(
		ending_title,
		"modulate:a",
		1.0,
		1.0
	)

	await title_tween.finished

	var description_tween := create_tween()

	description_tween.tween_property(
		ending_description,
		"modulate:a",
		1.0,
		1.0
	)

	await description_tween.finished
