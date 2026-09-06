extends CharacterBody2D

# Shared character script. One script, many characters:
# duplicate player.tscn, drop in a different set of textures in the
# Inspector, and you have a new character with the same movement.

@export var speed = 200

# Set to false for NPCs / other characters that shouldn't read WASD.
# They can still be turned from code with face_direction().
@export var player_controlled := true

# Standing still: feet together. These 4 are the minimum a character
# needs — without any walk art they just don't animate.
@export var tex_back: Texture2D    # W
@export var tex_front: Texture2D   # S
@export var tex_left: Texture2D    # A
@export var tex_right: Texture2D   # D

# Walking, left foot forward.
@export var tex_back_step_1: Texture2D
@export var tex_front_step_1: Texture2D
@export var tex_left_step_1: Texture2D
@export var tex_right_step_1: Texture2D

# Walking, right foot forward. Leave a slot empty and that direction
# falls back to the standing pose for that half of the cycle, so the
# character still animates while the art is only half drawn.
@export var tex_back_step_2: Texture2D
@export var tex_front_step_2: Texture2D
@export var tex_left_step_2: Texture2D
@export var tex_right_step_2: Texture2D

# How fast the two feet swap over while walking.
@export var steps_per_second := 6.0

# Small bounce on top of the footsteps. Set bob_height to 0 to turn it off.
@export var bob_speed := 12.0    # how fast the little bounce is
@export var bob_height := 4.0    # how many pixels it bounces

# Optional — footsteps. This wants one continuous recording of someone
# walking, not a single step: it runs on a loop while there is input and
# pauses the moment there isn't, so it never has to line up with the walk
# frames. Leave it empty and the character walks in silence.
@export var walk_sound: AudioStream

# Footsteps play under everything else for as long as the player is moving,
# which is most of the chapter — this is the one to pull back if the walking
# starts wearing on you.
@export_range(-40.0, 0.0) var walk_volume_db := 0.0

# The part of `walk_sound` that actually sounds like walking. Everything
# before `walk_start` and after `walk_end` is skipped, and the sound runs
# round this window for as long as the character is moving — so a recording
# that wanders off, changes surface or fades out at the end can still be used
# by picking the good stretch out of the middle of it.
#
# walk_end = 0 means "play to the end of the file".
@export var walk_start := 1.5
@export var walk_end := 10.0

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _walk_time := 0.0
var _bob_time := 0.0
var _sprite_base_y := 0.0
var _facing := Vector2.DOWN   # last direction we moved in

var _steps: AudioStreamPlayer
var _stepping := false        # whether the footsteps are running right now

# Cutscenes / puzzles can freeze the character with set_can_move(false).
var can_move := true

var last_movement_dir := Vector2.DOWN
var external_direction := Vector2.ZERO


func _ready():
	# If we've been in this scene before, spawn where we left it.
	var path = get_tree().current_scene.scene_file_path
	if GameState.spawn_points.has(path):
		global_position = GameState.spawn_points[path]

	# Default to facing front when a scene loads.
	if tex_front:
		sprite.texture = tex_front

	_sprite_base_y = sprite.position.y
	_build_steps()


# Built in code so no scene has to wire it up: dropping a sound into
# `walk_sound` in the Inspector is the whole setup.
func _build_steps() -> void:
	if walk_sound == null:
		return
	# Godot doesn't loop an imported mp3 unless the stream is told to.
	# loop_offset is where it comes back to, so the dead air at the front is
	# skipped on the way round as well as on the first play.
	if walk_sound is AudioStreamMP3 or walk_sound is AudioStreamOggVorbis:
		walk_sound.loop = true
		walk_sound.loop_offset = walk_start
	_steps = AudioStreamPlayer.new()
	_steps.stream = walk_sound
	_steps.bus = &"SFX"
	_steps.volume_db = walk_volume_db
	add_child(_steps)


func _physics_process(delta):
	var direction = Vector2.ZERO

	if external_direction != Vector2.ZERO:
		direction = external_direction
	elif player_controlled and can_move:
		if Input.is_key_pressed(KEY_W):
			direction.y -= 1

		if Input.is_key_pressed(KEY_S):
			direction.y += 1

		if Input.is_key_pressed(KEY_A):
			direction.x -= 1

		if Input.is_key_pressed(KEY_D):
			direction.x += 1

	if direction != Vector2.ZERO:
		var normalized_direction = direction.normalized()

		if abs(normalized_direction.x) >= abs(normalized_direction.y):
			if normalized_direction.x > 0:
				last_movement_dir = Vector2.RIGHT
			else:
				last_movement_dir = Vector2.LEFT
		else:
			if normalized_direction.y > 0:
				last_movement_dir = Vector2.DOWN
			else:
				last_movement_dir = Vector2.UP

	velocity = direction.normalized() * speed

	move_and_slide()

	_update_sprite(direction, delta)
	_update_bob(direction, delta)
	_update_steps(direction)


# Turn the character to face a direction without moving it. Usable from
# other scripts too, e.g. npc.face_direction(Vector2.LEFT).
func face_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	_facing = direction
	var standing = _poses_for(direction)[0]
	if standing:
		sprite.texture = standing


func get_foot_position() -> Vector2:
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape

		if shape is RectangleShape2D:
			return global_position + Vector2(
				0,
				shape.size.y / 2.0
			)

		elif shape is CircleShape2D:
			return global_position + Vector2(
				0,
				shape.radius
			)

	return global_position


func get_last_movement_direction() -> Vector2:
	return last_movement_dir


func set_external_direction(direction: Vector2) -> void:
	external_direction = direction


func _update_sprite(direction, delta):
	var poses = _poses_for(_facing if direction == Vector2.ZERO else direction)

	if direction == Vector2.ZERO:
		# Stopped: feet together, still facing wherever we last walked.
		_walk_time = 0.0
		if poses[0]:
			sprite.texture = poses[0]
		return

	_facing = direction
	_walk_time += delta

	# standing, step 1, standing, step 2 — the standing pose comes back
	# between every stride, and that neutral frame is what reads as a
	# footfall. Flipping straight from one step to the other (which is what
	# this used to do) looks like rocking on the spot, not walking. Same
	# cycle the students in the corridor walk on, see npc_student.gd.
	var cycle := [poses[0], poses[1], poses[0], poses[2]]
	var tex = cycle[int(_walk_time * steps_per_second) % cycle.size()]
	if not tex:
		tex = poses[0]     # this direction has no step art yet
	if tex:
		sprite.texture = tex


# The 3 poses for this direction: [standing, step 1, step 2].
# Diagonals (W+A etc.) use the left/right art, which reads better than
# the back/front art when walking at an angle.
func _poses_for(direction: Vector2) -> Array:
	if direction.x < 0:
		return [tex_left, tex_left_step_1, tex_left_step_2]
	if direction.x > 0:
		return [tex_right, tex_right_step_1, tex_right_step_2]
	if direction.y < 0:
		return [tex_back, tex_back_step_1, tex_back_step_2]
	return [tex_front, tex_front_step_1, tex_front_step_2]


# Paused rather than stopped, so the recording carries on from where it left
# off. Restarting it every time would replay the same first footfall over and
# over, which is what makes tapping a key sound like a stutter rather than
# someone walking. Freezing the player for a dialogue box zeroes `direction`,
# so the feet go quiet on their own while someone is talking.
func _update_steps(direction: Vector2) -> void:
	if _steps == null:
		return

	# An imported mp3 has a loop start but no loop end, so the jump back at
	# walk_end is done by hand, every frame the feet are actually moving.
	if walk_end > walk_start and _steps.playing and not _steps.stream_paused:
		if _steps.get_playback_position() >= walk_end:
			_steps.seek(walk_start)

	var walking := direction != Vector2.ZERO
	if walking == _stepping:
		return
	_stepping = walking

	if not walking:
		_steps.stream_paused = true
	elif _steps.stream_paused:
		_steps.stream_paused = false
	else:
		_steps.play(walk_start)


func _update_bob(direction, delta):
	if direction != Vector2.ZERO:
		# abs(sin) gives little upward hops, like footsteps.
		_bob_time += delta * bob_speed
		sprite.position.y = _sprite_base_y - abs(sin(_bob_time)) * bob_height
	else:
		# Standing still: settle back to the resting position.
		_bob_time = 0.0
		sprite.position.y = _sprite_base_y


func set_can_move(value: bool) -> void:
	can_move = value
