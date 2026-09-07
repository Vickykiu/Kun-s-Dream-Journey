extends CanvasLayer


@export var chapter_1_scene: PackedScene


@onready var ending_title: Label = $EndingTitle
@onready var ending_description: Label = $EndingDescription
@onready var background_music: AudioStreamPlayer = $BackgroundMusic


func _ready() -> void:
	ending_title.modulate.a = 0.0
	ending_description.modulate.a = 0.0

	# Start Ending 1 background music.
	if background_music.stream:
		background_music.volume_db = -15.0
		background_music.play()

	await show_loop_ending()

	await get_tree().create_timer(
		3.0
	).timeout

	await fade_out_music()

	restart_from_chapter_1()


func show_loop_ending() -> void:
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


func fade_out_music() -> void:
	if not background_music.playing:
		return

	var music_tween := create_tween()

	music_tween.tween_property(
		background_music,
		"volume_db",
		-40.0,
		1.5
	)

	await music_tween.finished


func restart_from_chapter_1() -> void:
	# Reset the current loop's progress.
	GameState.items.clear()
	GameState.spawn_points.clear()
	GameState.flags.clear()

	# Remember that Ending 1 was reached.
	GameState.set_flag(
		"ending_1_loop_seen"
	)

	if chapter_1_scene:
		get_tree().change_scene_to_packed(
			chapter_1_scene
		)
	else:
		push_error(
			"Chapter 1 Scene has not been assigned."
		)
