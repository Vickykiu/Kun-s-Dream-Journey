extends Control


# ===== Settings =====

@export var scroll_speed: float = 80.0

@export var start_delay: float = 0.5

@export var end_delay: float = 0.2

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

	# Short delay before credits.
	await get_tree().create_timer(
		start_delay
	).timeout

	# Wait until credits finish.
	await play_credits()

	# Very short black screen.
	await get_tree().create_timer(
		end_delay
	).timeout

	return_to_main_menu()


# ===== Setup Credits =====

func setup_credits() -> void:
	var screen_size: Vector2 = (
		get_viewport_rect().size
	)

	# Remove empty space at the end.
	credits_text.text = (
		credits_text.text.strip_edges()
	)

	# Use full screen width.
	credits_text.position.x = 0.0

	credits_text.size.x = (
		screen_size.x
	)

	credits_text.vertical_alignment = (
		VERTICAL_ALIGNMENT_TOP
	)

	# Start below screen.
	credits_text.position.y = (
		screen_size.y
	)


# ===== Play Credits =====

func play_credits() -> void:
	var screen_size: Vector2 = (
		get_viewport_rect().size
	)

	var line_count: int = (
		credits_text.get_line_count()
	)

	var line_height: int = (
		credits_text.get_line_height()
	)

	var text_height: float = (
		float(line_count)
		* float(line_height)
	)

	# Stop when last line leaves screen.
	var target_y: float = (
		-text_height
	)

	var distance: float = (
		screen_size.y
		+ text_height
	)

	var duration: float = (
		distance
		/ scroll_speed
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
		duration
	)

	await tween.finished


# ===== Ending BGM =====

func stop_ending_bgm() -> void:
	var ending_bgm: Node = (
		get_tree().root.get_node_or_null(
			"EndingBGM"
		)
	)

	if ending_bgm == null:
		return

	ending_bgm.queue_free()


# ===== Main Menu =====

func return_to_main_menu() -> void:
	get_tree().paused = false

	# Stop ending BGM only after credits.
	stop_ending_bgm()

	if main_menu_scene == null:
		print(
			"ERROR: Main Menu Scene is not assigned."
		)
		return

	get_tree().change_scene_to_packed(
		main_menu_scene
	)
