@tool
extends CanvasLayer


# ==================================================
# Ending Scene
# ==================================================

const ENDING_3_SCENE = preload(
	"res://Lew Jia Jia/scenes/Ending3.tscn"
)


# ==================================================
# Portraits
# ==================================================

@export var kun_portrait: Texture2D
@export var police_portrait: Texture2D


# ==================================================
# Dialogue Lines
# ==================================================

@export var kun_opening_lines: Array[DialogueLine] = []:
	set(value):
		kun_opening_lines = DialogueLine.fill_blanks(value)


@export var police_lines: Array[DialogueLine] = []:
	set(value):
		police_lines = DialogueLine.fill_blanks(value)


@export var kun_final_lines: Array[DialogueLine] = []:
	set(value):
		kun_final_lines = DialogueLine.fill_blanks(value)


# ==================================================
# Nodes
# ==================================================

@onready var fade_screen: ColorRect = $FadeScreen


# ==================================================
# Hospital Sequence
# ==================================================

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Start with a completely black screen.
	fade_screen.color.a = 1.0
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await fade_from_black()

	await get_tree().create_timer(
		1.0
	).timeout

	# Kun wakes up.
	if not kun_opening_lines.is_empty():
		Dialogue.show_lines(
			kun_opening_lines,
			kun_portrait,
			"Kun"
		)

		await Dialogue.finished

	# Police officer speaks.
	if not police_lines.is_empty():
		Dialogue.show_lines(
			police_lines,
			police_portrait,
			"Police Officer"
		)

		await Dialogue.finished

	# Kun reacts to the news.
	if not kun_final_lines.is_empty():
		Dialogue.show_lines(
			kun_final_lines,
			kun_portrait,
			"Kun"
		)

		await Dialogue.finished

	print(
		"Hospital dialogue completed."
	)

	# Pause briefly after the final dialogue.
	await get_tree().create_timer(
		1.0
	).timeout

	# Fade the hospital scene to black.
	await fade_to_black()

	# Enter Ending 3.
	get_tree().change_scene_to_packed(
		ENDING_3_SCENE
	)


# ==================================================
# Fade From Black
# ==================================================

func fade_from_black() -> void:
	var tween := create_tween()

	tween.tween_property(
		fade_screen,
		"color:a",
		0.0,
		2.0
	)

	await tween.finished


# ==================================================
# Fade To Black
# ==================================================

func fade_to_black() -> void:
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()

	tween.tween_property(
		fade_screen,
		"color:a",
		1.0,
		2.0
	)

	await tween.finished
