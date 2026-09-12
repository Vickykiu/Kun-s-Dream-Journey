extends CanvasLayer


const CREDITS_SCENE_PATH: String = (
	"res://Tay Hong Fei/scene/Credits.tscn"
)


@onready var ending_title: Label = $EndingTitle
@onready var ending_description: Label = $EndingDescription
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var continue_hint: Label = $ContinueHint

@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var achievement_sound: AudioStreamPlayer = $AchievementSound


var can_continue: bool = false


func _ready() -> void:
	GameState.set_flag("ending_3_survivor")

	ending_title.modulate.a = 0.0
	ending_description.modulate.a = 0.0
	dark_overlay.color.a = 1.0
	continue_hint.visible = false
	continue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if background_music.stream:
		background_music.volume_db = -15.0
		background_music.play()

	if achievement_sound.stream:
		achievement_sound.volume_db = 0.0
		achievement_sound.play()

	await fade_in_ending()

	continue_hint.visible = true
	can_continue = true


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if not can_continue:
		return

	get_viewport().set_input_as_handled()

	can_continue = false
	continue_hint.visible = false
	go_to_credits()


func go_to_credits() -> void:
	await fade_out_ending()

	var result: Error = get_tree().change_scene_to_file(
		CREDITS_SCENE_PATH
	)

	if result != OK:
		push_error(
			"Could not open Credits scene: "
			+ CREDITS_SCENE_PATH
		)


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


func fade_out_ending() -> void:
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)

	fade_tween.tween_property(
		dark_overlay,
		"color:a",
		1.0,
		1.5
	)

	if background_music.playing:
		fade_tween.tween_property(
			background_music,
			"volume_db",
			-40.0,
			1.5
		)

	await fade_tween.finished
