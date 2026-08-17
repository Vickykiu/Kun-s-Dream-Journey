extends Control


# ===== Settings =====

@export var credits_duration: float = 10.0
@export var start_delay: float = 1.0
@export var end_delay: float = 1.0

@export var main_menu_scene: PackedScene


# ===== Nodes =====

@onready var credits_text: Label = (
	$CreditsText
)


# ===== Initialization =====

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	await get_tree().process_frame
	await get_tree().process_frame

	setup_credits()

	await get_tree().create_timer(
		start_delay
	).timeout

	play_credits()

	# Credits lasts 10 seconds.
	await get_tree().create_timer(
		credits_duration
	).timeout

	await get_tree().create_timer(
		end_delay
	).timeout

	return_to_main_menu()


# ===== Setup Credits =====

func setup_credits() -> void:
	var screen_size: Vector2 = (
		get_viewport_rect().size
	)

	# Use the full screen width.
	credits_text.position.x = 0.0

	credits_text.size.x = (
		screen_size.x
	)

	credits_text.reset_size()

	credits_text.size.x = (
		screen_size.x
	)

	# Start below the screen.
	credits_text.position.y = (
		screen_size.y
	)


# ===== Play Credits =====

func play_credits() -> void:
	var text_height: float = (
		credits_text.size.y
	)

	# Move all credits above the screen.
	var target_y: float = (
		-text_height
	)

	var tween: Tween = (
		create_tween()
	)

	tween.set_trans(
		Tween.TRANS_LINEAR
	)

	tween.tween_property(
		credits_text,
		"position:y",
		target_y,
		credits_duration
	)


# ===== Main Menu =====

func return_to_main_menu() -> void:
	get_tree().paused = false

	if main_menu_scene == null:
		print(
			"ERROR: Main Menu Scene is not assigned."
		)
		return

	get_tree().change_scene_to_packed(
		main_menu_scene
	)
