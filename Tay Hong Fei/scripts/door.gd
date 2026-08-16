extends Area2D


# ===== Settings =====

@export var interact_action: StringName = &"interact"

@export var prompt_label: Label
@export var clue_image: Texture2D
@export var target_scene: PackedScene


# ===== Door Sprites =====

@export var door_closed: Sprite2D
@export var door_open_1: Sprite2D
@export var door_open_2: Sprite2D

@export var open_start_delay: float = 0.5
@export var open_frame_delay: float = 0.3


# ===== Door Lights =====

@export var light_1: Sprite2D
@export var light_2: Sprite2D
@export var light_3: Sprite2D


# ===== Clue Image =====

@export var clue_image_size: Vector2 = Vector2(900, 650)


# ===== State =====

var is_player_near: bool = false
var is_image_showing: bool = false

var door_opening: bool = false
var door_opened: bool = false

var last_block_count: int = -1

var player: CharacterBody2D = null
var overlay_layer: CanvasLayer = null


# ===== Initialization =====

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

	# Show only the closed door at the start.
	if door_closed:
		door_closed.visible = true

	if door_open_1:
		door_open_1.visible = false

	if door_open_2:
		door_open_2.visible = false

	# Hide all lights at the start.
	if light_1:
		light_1.visible = false

	if light_2:
		light_2.visible = false

	if light_3:
		light_3.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	update_door_progress()


# ===== Door Progress =====

func _process(_delta: float) -> void:
	var current_count: int = PushableBlock.get_snapped_count()

	if current_count != last_block_count:
		update_door_progress()


func update_door_progress() -> void:
	var count: int = PushableBlock.get_snapped_count()

	last_block_count = count

	# Turn on lights based on completed blocks.
	if light_1:
		light_1.visible = count >= 1

	if light_2:
		light_2.visible = count >= 2

	if light_3:
		light_3.visible = count >= 3

	# Open the door after all blocks are completed.
	if count >= 3:
		if not door_opening and not door_opened:
			open_door()

	update_prompt()


# ===== Door Opening =====

func open_door() -> void:
	if door_opening or door_opened:
		return

	door_opening = true

	update_prompt()

	# Wait after the third light turns on.
	await get_tree().create_timer(
		open_start_delay
	).timeout

	# First opening image.
	if door_closed:
		door_closed.visible = false

	if door_open_1:
		door_open_1.visible = true

	await get_tree().create_timer(
		open_frame_delay
	).timeout

	# Final opening image.
	if door_open_1:
		door_open_1.visible = false

	if door_open_2:
		door_open_2.visible = true

	door_opening = false
	door_opened = true

	update_prompt()


# ===== Player Detection =====

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	is_player_near = true

	if body is CharacterBody2D:
		player = body as CharacterBody2D

	update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	is_player_near = false

	if body == player:
		player = null

	if prompt_label:
		prompt_label.visible = false


# ===== Prompt =====

func update_prompt() -> void:
	if prompt_label == null:
		return

	if not is_player_near:
		prompt_label.visible = false
		return

	if is_image_showing:
		prompt_label.visible = false
		return

	if door_opening:
		prompt_label.visible = false
		return

	# Enter after the door is opened.
	if door_opened:
		prompt_label.text = "Press E to enter"

	else:

		prompt_label.text = "Press E to view"

	prompt_label.visible = true


# ===== Input =====

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action):
		return

	# Close the clue image.
	if is_image_showing:
		get_viewport().set_input_as_handled()

		close_image()

		return

	if not is_player_near:
		return

	get_viewport().set_input_as_handled()

	# Enter the next scene after the door opens.
	if door_opened:
		go_to_next_scene()
		return

	# View clue before the door opens.
	if not door_opening:
		show_image()


# ===== Clue Image =====

func show_image() -> void:
	if clue_image == null:
		return

	if prompt_label:
		prompt_label.visible = false

	# Stop player movement.
	if player != null:
		if player.has_method("set_external_direction"):
			player.call(
				"set_external_direction",
				Vector2.ZERO
			)

		if player.has_method("set_can_move"):
			player.call(
				"set_can_move",
				false
			)

	if overlay_layer == null:
		create_image_overlay()

	overlay_layer.visible = true
	is_image_showing = true


func create_image_overlay() -> void:
	# Keep the clue above the game.
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100

	get_tree().current_scene.add_child(
		overlay_layer
	)

	# Full-screen container.
	var root: Control = Control.new()

	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	overlay_layer.add_child(root)

	# Dark background.
	var background: ColorRect = ColorRect.new()

	background.anchor_right = 1.0
	background.anchor_bottom = 1.0

	background.color = Color(
		0.0,
		0.0,
		0.0,
		0.75
	)

	root.add_child(background)

	# Centre container.
	var center: CenterContainer = CenterContainer.new()

	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	root.add_child(center)

	# Clue image.
	var image: TextureRect = TextureRect.new()

	image.texture = clue_image
	image.custom_minimum_size = clue_image_size

	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	image.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	image.mouse_filter = Control.MOUSE_FILTER_IGNORE

	center.add_child(image)

	# Close instruction.
	var close_label: Label = Label.new()

	close_label.text = "Press E to close"

	close_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	close_label.anchor_left = 0.5
	close_label.anchor_right = 0.5
	close_label.anchor_top = 1.0
	close_label.anchor_bottom = 1.0

	close_label.offset_left = -200.0
	close_label.offset_right = 200.0
	close_label.offset_top = -80.0
	close_label.offset_bottom = -30.0

	close_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.add_child(close_label)


# ===== Close Clue =====

func close_image() -> void:
	if overlay_layer:
		overlay_layer.visible = false

	is_image_showing = false

	# Restore player movement.
	if player != null:
		if player.has_method("set_external_direction"):
			player.call(
				"set_external_direction",
				Vector2.ZERO
			)

		if player.has_method("set_can_move"):
			player.call(
				"set_can_move",
				true
			)

	update_prompt()


# ===== Next Scene =====

func go_to_next_scene() -> void:
	if not door_opened:
		return

	if prompt_label:
		prompt_label.visible = false

	if target_scene:
		get_tree().change_scene_to_packed(
			target_scene
		)

	else:
		print("No target scene assigned.")
