extends CanvasLayer


# ==================================================
# Node references
# ==================================================

@onready var ending_title: Label = $EndingTitle
@onready var ending_description: Label = $EndingDescription
@onready var dark_overlay: ColorRect = $DarkOverlay

@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var achievement_sound: AudioStreamPlayer = $AchievementSound


# ==================================================
# Ending sequence
# ==================================================

func _ready() -> void:
	GameState.set_flag(
		"ending_3_survivor"
	)

	ending_title.modulate.a = 0.0
	ending_description.modulate.a = 0.0
	dark_overlay.color.a = 1.0

	# Start Ending background music.
	if background_music.stream:
		background_music.volume_db = -15.0
		background_music.play()

	# Play achievement sound once.
	if achievement_sound.stream:
		achievement_sound.volume_db = 0.0
		achievement_sound.play()

	await fade_in_ending()


# ==================================================
# Fade in Ending
# ==================================================

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
