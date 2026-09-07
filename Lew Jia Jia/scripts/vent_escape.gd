extends CanvasLayer


const HOSPITAL_SCENE = preload(
	"res://Lew Jia Jia/scenes/HospitalScene.tscn"
)


# ==================================================
# Node references
# ==================================================

@onready var story_label: Label = $StoryLabel
@onready var skip_button: Button = $SkipButton

@onready var continue_sound: AudioStreamPlayer = $ContinueSound
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var police_siren_sound: AudioStreamPlayer = $PoliceSirenSound


# ==================================================
# State
# ==================================================

var cutscene_skipped: bool = false
var story_finished: bool = false

var active_tween: Tween = null
var siren_tween: Tween = null


# ==================================================
# Initial state
# ==================================================

func _ready() -> void:
	skip_button.visible = false
	skip_button.disabled = true
	story_label.modulate.a = 0.0

	# Start background music.
	if background_music.stream:
		background_music.volume_db = -15.0
		background_music.play()

	# Start police siren at a very low volume.
	if police_siren_sound.stream:
		police_siren_sound.volume_db = -40.0
		police_siren_sound.play()

	play_vent_story()


# ==================================================
# Space Skip
# ==================================================

func _input(event: InputEvent) -> void:
	if cutscene_skipped or story_finished:
		return

	if event is InputEventKey:
		if (
			event.keycode == KEY_SPACE
			and event.pressed
			and not event.echo
		):
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

	# Police sirens gradually become louder.
	increase_police_siren()

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
# Fade Label In
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
# Fade Label Out
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
# Police Siren
# ==================================================

func increase_police_siren() -> void:
	if not police_siren_sound.stream:
		return

	if not police_siren_sound.playing:
		police_siren_sound.volume_db = -40.0
		police_siren_sound.play()

	if siren_tween:
		siren_tween.kill()

	siren_tween = create_tween()

	siren_tween.tween_property(
		police_siren_sound,
		"volume_db",
		-22.0,
		3.0
	)


# ==================================================
# Skip Story
# ==================================================

func skip_vent_story() -> void:
	cutscene_skipped = true

	if active_tween:
		active_tween.kill()
		active_tween = null

	# Make the siren audible when the story is skipped.
	increase_police_siren()

	show_final_message()


# ==================================================
# Final Vent Message
# ==================================================

func show_final_message() -> void:
	if story_finished:
		return

	story_finished = true

	story_label.text = (
		"I made it out...\n\n"
		+ "But what happened to everyone else?"
	)

	story_label.modulate.a = 1.0

	skip_button.visible = true
	skip_button.disabled = false


# ==================================================
# Continue to Hospital
# ==================================================

func _on_skip_button_pressed() -> void:
	if not story_finished:
		return

	if skip_button.disabled:
		return

	skip_button.disabled = true

	# Lower the background sounds so the button sound is clear.
	if background_music.playing:
		background_music.volume_db = -30.0

	if police_siren_sound.playing:
		police_siren_sound.volume_db = -30.0

	# Play Continue button sound.
	if continue_sound.stream:
		continue_sound.play()
		await continue_sound.finished

	get_tree().change_scene_to_packed(
		HOSPITAL_SCENE
	)
