extends CharacterBody2D


# ===== Appearance Settings =====

@export var appear_duration: float = 2.0

@export var appear_audio: AudioStream

@export var appear_audio_volume_db: float = -8.0


# ===== Interaction Settings =====

@export var interact_action: StringName = &"interact"


# ===== Kunkun Intro =====

@export var kunkun_speaker: String = "Kunkun"
@export var kunkun_portrait: Texture2D

@export var kunkun_intro_lines: Array[DialogueLine] = []:
	set(value):
		kunkun_intro_lines = DialogueLine.fill_blanks(value)


# ===== Mystery Intro =====

@export var mystery_speaker: String = "???"
@export var mystery_portrait: Texture2D

@export var mystery_intro_lines: Array[DialogueLine] = []:
	set(value):
		mystery_intro_lines = DialogueLine.fill_blanks(value)


# ===== Main Dialogue =====

@export var main_speaker: String = "???"
@export var main_portrait: Texture2D

@export var main_lines: Array[DialogueLine] = []:
	set(value):
		main_lines = DialogueLine.fill_blanks(value)


# ===== Choice =====

@export var choice_question: String = "Are you willing?"

@export var accept_text: String = (
	"Accept: Carry the memories into another life"
)

@export var reject_text: String = (
	"Refuse: I want to try on my own"
)


# ===== Reject Dialogue =====

@export var reject_lines: Array[DialogueLine] = []:
	set(value):
		reject_lines = DialogueLine.fill_blanks(value)


# ===== Disappear Settings =====

@export var disappear_frames: Array[Texture2D] = []

@export var disappear_frame_delay: float = 0.35


# ===== Accept Movement =====

@export var approach_duration: float = 1.0

@export var approach_offset_y: float = 40.0


# ===== Accept Ending =====

@export var ending_image: Texture2D

@export var ending_audio: AudioStream

@export var ending_audio_volume_db: float = -10.0

@export var ending_image_duration: float = 7.0

@export var credits_scene: PackedScene


# ===== Ending Text =====

@export var ending_title_text: String = "ENDING 2"

@export_multiline var ending_description_text: String = (
	"REINCARNATION\n"
	+ "Kunkun was reborn into a new life.\n"
	+ "He remembered nothing of his previous life,\n"
	+ "but a strange melody still remained within him."
)

@export var ending_title_font_size: int = 52

@export var ending_description_font_size: int = 28


# ===== Reject Ending =====

@export var reject_scene: PackedScene

@export var reject_black_duration: float = 1.0


# ===== Nodes =====

@onready var sprite: Sprite2D = $Sprite

@onready var body_collision: CollisionShape2D = (
	$CollisionShape2D
)

@onready var interaction_area: Area2D = (
	$InteractionArea
)

@onready var prompt_label: Label = (
	$PromptLabel
)


# ===== State =====

var player: CharacterBody2D = null

var player_in_area: bool = false

var unlocked: bool = false

var intro_started: bool = false

var conversation_started: bool = false

var ending_started: bool = false


# ===== Initialization =====

func _ready() -> void:
	visible = false

	prompt_label.visible = false

	interaction_area.monitoring = false

	body_collision.set_deferred(
		"disabled",
		true
	)

	interaction_area.body_entered.connect(
		_on_body_entered
	)

	interaction_area.body_exited.connect(
		_on_body_exited
	)

	call_deferred(
		"check_crystals"
	)


# ===== Update =====

func _process(_delta: float) -> void:
	if not unlocked:
		return

	if intro_started:
		hide_prompt()
		return

	if conversation_started:
		hide_prompt()
		return

	if ending_started:
		hide_prompt()
		return

	refresh_prompt()


# ===== Crystal Check =====

func check_crystals() -> void:
	if not MinesweeperState.is_crystal_completed(
		"Crystal1"
	):
		return

	if not MinesweeperState.is_crystal_completed(
		"Crystal2"
	):
		return

	if not MinesweeperState.is_crystal_completed(
		"Crystal3"
	):
		return

	unlocked = true

	player = get_player()

	set_player_movement(false)

	visible = true
	modulate.a = 0.0

	# Play appearance sound.
	play_appear_audio()

	# Slowly show the mystery person.
	var appear_tween: Tween = (
		create_tween()
	)

	appear_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		appear_duration
	)

	await appear_tween.finished

	body_collision.set_deferred(
		"disabled",
		false
	)

	interaction_area.set_deferred(
		"monitoring",
		true
	)

	if not MinesweeperState.mystery_intro_played:
		await start_intro_dialogue()

	else:
		set_player_movement(true)


# ===== Appearance Audio =====

func play_appear_audio() -> void:
	if appear_audio == null:
		return

	var audio_player: AudioStreamPlayer = (
		AudioStreamPlayer.new()
	)

	audio_player.stream = appear_audio

	audio_player.volume_db = (
		appear_audio_volume_db
	)

	add_child(
		audio_player
	)

	audio_player.finished.connect(
		audio_player.queue_free
	)

	audio_player.play()


# ===== Intro Dialogue =====

func start_intro_dialogue() -> void:
	if intro_started:
		return

	intro_started = true

	if player == null:
		player = get_player()

	# Kunkun speaks.
	if not kunkun_intro_lines.is_empty():
		Dialogue.show_lines(
			kunkun_intro_lines,
			kunkun_portrait,
			kunkun_speaker
		)

		await Dialogue.finished

	# Mystery person stays silent.
	if not mystery_intro_lines.is_empty():
		Dialogue.show_lines(
			mystery_intro_lines,
			mystery_portrait,
			mystery_speaker
		)

		await Dialogue.finished

	MinesweeperState.mystery_intro_played = true

	intro_started = false

	set_player_movement(true)


# ===== Player Detection =====

func _on_body_entered(
	body: Node2D
) -> void:
	if not unlocked:
		return

	if not body.is_in_group(
		"player"
	):
		return

	if not body is CharacterBody2D:
		return

	player = body as CharacterBody2D

	player_in_area = true

	refresh_prompt()


func _on_body_exited(
	body: Node2D
) -> void:
	if not body.is_in_group(
		"player"
	):
		return

	if body == player:
		player_in_area = false

	hide_prompt()


# ===== Get Player =====

func get_player() -> CharacterBody2D:
	return (
		get_tree().get_first_node_in_group(
			"player"
		) as CharacterBody2D
	)


# ===== Player Facing =====

func get_player_facing_direction() -> Vector2:
	if player == null:
		return Vector2.ZERO

	if not player.has_method(
		"get_last_movement_direction"
	):
		return Vector2.ZERO

	var result = player.call(
		"get_last_movement_direction"
	)

	if not result is Vector2:
		return Vector2.ZERO

	var direction: Vector2 = result

	if direction == Vector2.ZERO:
		return Vector2.ZERO

	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0.0:
			return Vector2.RIGHT

		return Vector2.LEFT

	if direction.y > 0.0:
		return Vector2.DOWN

	return Vector2.UP


# ===== Player Position =====

func is_player_below_person() -> bool:
	if player == null:
		return false

	var diff: Vector2 = (
		player.global_position
		- global_position
	)

	# Player must be below the person.
	if diff.y <= 0.0:
		return false

	# Player must mainly be below.
	if abs(diff.x) > abs(diff.y):
		return false

	return true


# ===== Interaction Check =====

func can_interact() -> bool:
	if not player_in_area:
		return false

	if player == null:
		return false

	if not is_player_below_person():
		return false

	# Player must face upward.
	if get_player_facing_direction() != Vector2.UP:
		return false

	return true


# ===== Prompt =====

func refresh_prompt() -> void:
	if not can_interact():
		hide_prompt()
		return

	prompt_label.text = "Press E to talk"

	prompt_label.visible = true


func hide_prompt() -> void:
	prompt_label.visible = false


# ===== Input =====

func _unhandled_input(
	event: InputEvent
) -> void:
	if not unlocked:
		return

	if intro_started:
		return

	if conversation_started:
		return

	if ending_started:
		return

	if not event.is_action_pressed(
		interact_action
	):
		return

	if not can_interact():
		return

	get_viewport().set_input_as_handled()

	start_main_dialogue()


# ===== Main Dialogue =====

func start_main_dialogue() -> void:
	if conversation_started:
		return

	conversation_started = true

	hide_prompt()

	# Play the mystery person's story.
	if not main_lines.is_empty():
		Dialogue.show_lines(
			main_lines,
			main_portrait,
			main_speaker
		)

		await Dialogue.finished

	# Show choice inside dialogue.
	Dialogue.show_choice(
		choice_question,
		accept_text,
		reject_text,
		main_portrait,
		main_speaker
	)

	var choice: String = (
		await Dialogue.choice_selected
	)

	conversation_started = false

	if choice == "accept":
		await play_accept_ending()

	elif choice == "reject":
		await play_reject_ending()


# ===== Accept Ending =====

func play_accept_ending() -> void:
	if ending_started:
		return

	ending_started = true

	hide_prompt()

	if player == null:
		player = get_player()

	set_player_movement(false)

	interaction_area.set_deferred(
		"monitoring",
		false
	)

	body_collision.set_deferred(
		"disabled",
		true
	)

	# Move Kunkun closer.
	await move_player_closer()

	# Play mystery person disappear frames.
	await play_disappear_animation()

	# Stop Chapter 4 BGM before ending.
	stop_scene_bgm()

	# Show baby ending image and audio.
	await show_ending_image()

	# Go to credits.
	if credits_scene == null:
		print(
			"Credits scene is not assigned."
		)
		return

	get_tree().change_scene_to_packed(
		credits_scene
	)


# ===== Move Player Closer =====

func move_player_closer() -> void:
	if player == null:
		return

	var target_position: Vector2 = (
		global_position
		+ Vector2(
			0.0,
			approach_offset_y
		)
	)

	var approach_tween: Tween = (
		create_tween()
	)

	approach_tween.set_trans(
		Tween.TRANS_SINE
	)

	approach_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	approach_tween.tween_property(
		player,
		"global_position",
		target_position,
		approach_duration
	)

	await approach_tween.finished

	# Face the mystery person.
	if player.has_method(
		"face_direction"
	):
		player.call(
			"face_direction",
			Vector2.UP
		)


# ===== Disappear Animation =====

func play_disappear_animation() -> void:
	for texture: Texture2D in disappear_frames:
		if texture == null:
			continue

		sprite.texture = texture

		await get_tree().create_timer(
			disappear_frame_delay
		).timeout

	visible = false


# ===== Scene BGM =====

func stop_scene_bgm() -> void:
	var current_scene: Node = (
		get_tree().current_scene
	)

	if current_scene == null:
		return

	if current_scene.has_method(
		"stop_bgm"
	):
		current_scene.call(
			"stop_bgm"
		)


# ===== Ending Image =====

func show_ending_image() -> void:
	if ending_image == null:
		print(
			"Ending image is not assigned."
		)
		return

	var ending_layer: CanvasLayer = (
		CanvasLayer.new()
	)

	ending_layer.layer = 300

	# Remove with Chapter 4.
	get_tree().current_scene.add_child(
		ending_layer
	)

	var ending_root: Control = (
		Control.new()
	)

	ending_layer.add_child(
		ending_root
	)

	ending_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	ending_root.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ===== Black Background =====

	var black_background: ColorRect = (
		ColorRect.new()
	)

	ending_root.add_child(
		black_background
	)

	black_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	black_background.color = Color.BLACK

	black_background.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ===== Baby Ending Image =====

	var ending_texture: TextureRect = (
		TextureRect.new()
	)

	ending_root.add_child(
		ending_texture
	)

	ending_texture.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# The baby photo is the ending screen.
	ending_texture.texture = ending_image

	ending_texture.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	# Keep ratio and do not crop.
	ending_texture.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	ending_texture.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	# ===== Dark Overlay =====

	var dark_overlay: ColorRect = (
		ColorRect.new()
	)

	ending_root.add_child(
		dark_overlay
	)

	dark_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Start completely dark.
	dark_overlay.color = Color(
		0.0,
		0.0,
		0.0,
		1.0
	)

	dark_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# ===== Ending Title =====

	var ending_title: Label = (
		Label.new()
	)

	ending_root.add_child(
		ending_title
	)

	ending_title.anchor_left = 0.0
	ending_title.anchor_right = 1.0

	ending_title.anchor_top = 0.28
	ending_title.anchor_bottom = 0.38

	ending_title.offset_left = 0.0
	ending_title.offset_right = 0.0
	ending_title.offset_top = 0.0
	ending_title.offset_bottom = 0.0

	ending_title.text = ending_title_text

	ending_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	ending_title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	ending_title.add_theme_font_size_override(
		"font_size",
		ending_title_font_size
	)

	ending_title.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	ending_title.modulate.a = 0.0

	ending_title.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# ===== Ending Description =====

	var ending_description: Label = (
		Label.new()
	)

	ending_root.add_child(
		ending_description
	)

	ending_description.anchor_left = 0.15
	ending_description.anchor_right = 0.85

	ending_description.anchor_top = 0.40
	ending_description.anchor_bottom = 0.75

	ending_description.offset_left = 0.0
	ending_description.offset_right = 0.0
	ending_description.offset_top = 0.0
	ending_description.offset_bottom = 0.0

	ending_description.text = (
		ending_description_text
	)

	ending_description.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	ending_description.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	ending_description.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	ending_description.add_theme_font_size_override(
		"font_size",
		ending_description_font_size
	)

	ending_description.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	ending_description.modulate.a = 0.0

	ending_description.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# ===== Ending Audio =====

	start_ending_bgm()


	# ===== Fade Baby Image =====

	# Same background reveal style
	# as Chapter 3.
	var background_tween: Tween = (
		create_tween()
	)

	background_tween.tween_property(
		dark_overlay,
		"color:a",
		0.65,
		2.0
	)

	await background_tween.finished


	# ===== Fade Title =====

	var title_tween: Tween = (
		create_tween()
	)

	title_tween.tween_property(
		ending_title,
		"modulate:a",
		1.0,
		1.0
	)

	await title_tween.finished


	# ===== Fade Description =====

	var description_tween: Tween = (
		create_tween()
	)

	description_tween.tween_property(
		ending_description,
		"modulate:a",
		1.0,
		1.0
	)

	await description_tween.finished


	# ===== Remaining Time =====

	# 2 sec image
	# + 1 sec title
	# + 1 sec description.
	var used_time: float = 4.0

	var remaining_time: float = (
		ending_image_duration
		- used_time
	)

	# Keep full description visible.
	if remaining_time > 0.0:
		await get_tree().create_timer(
			remaining_time
		).timeout


# ===== Ending BGM =====

func start_ending_bgm() -> void:
	if ending_audio == null:
		return

	# Remove old ending BGM if it exists.
	var old_bgm: Node = (
		get_tree().root.get_node_or_null(
			"EndingBGM"
		)
	)

	if old_bgm != null:
		old_bgm.queue_free()

		await get_tree().process_frame

	# Loop MP3 through ending and credits.
	if ending_audio is AudioStreamMP3:
		ending_audio.loop = true
		ending_audio.loop_offset = 0.0

	var audio_player: AudioStreamPlayer = (
		AudioStreamPlayer.new()
	)

	audio_player.name = "EndingBGM"

	audio_player.stream = ending_audio

	audio_player.volume_db = (
		ending_audio_volume_db
	)

	# Add to root so it survives scene changes.
	get_tree().root.add_child(
		audio_player
	)

	audio_player.play()


# ===== Reject Ending =====

func play_reject_ending() -> void:
	if ending_started:
		return

	ending_started = true

	hide_prompt()

	if player == null:
		player = get_player()

	set_player_movement(false)

	# Mystery person responds.
	if not reject_lines.is_empty():
		Dialogue.show_lines(
			reject_lines,
			mystery_portrait,
			mystery_speaker
		)

		await Dialogue.finished

	set_player_movement(false)

	interaction_area.set_deferred(
		"monitoring",
		false
	)

	body_collision.set_deferred(
		"disabled",
		true
	)

	# Play mystery person disappear frames.
	await play_disappear_animation()

	# Create black transition.
	var black_layer: CanvasLayer = (
		CanvasLayer.new()
	)

	black_layer.name = (
		"RejectTransitionLayer"
	)

	black_layer.layer = 300

	# Keep this during the scene change.
	get_tree().root.add_child(
		black_layer
	)

	var black_screen: ColorRect = (
		ColorRect.new()
	)

	black_screen.name = "BlackScreen"

	black_layer.add_child(
		black_screen
	)

	black_screen.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	black_screen.color = Color(
		0.0,
		0.0,
		0.0,
		0.0
	)

	black_screen.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	# Fade to black.
	var black_tween: Tween = (
		create_tween()
	)

	black_tween.tween_property(
		black_screen,
		"color:a",
		1.0,
		reject_black_duration
	)

	await black_tween.finished

	# Chapter 3 will use this flag.
	MinesweeperState.reject_hint_pending = true

	if reject_scene == null:
		print(
			"Reject scene is not assigned."
		)

		black_layer.queue_free()

		return

	# Remove saved Chapter 3 position.
	var reject_path: String = (
		reject_scene.resource_path
	)

	if GameState.spawn_points.has(
		reject_path
	):
		GameState.spawn_points.erase(
			reject_path
		)

	# Return to Chapter 3.
	get_tree().change_scene_to_packed(
		reject_scene
	)


# ===== Player Movement =====

func set_player_movement(
	enabled: bool
) -> void:
	if player == null:
		return

	if player.has_method(
		"set_can_move"
	):
		player.call(
			"set_can_move",
			enabled
		)
