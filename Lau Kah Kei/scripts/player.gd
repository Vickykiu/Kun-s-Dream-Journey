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

@onready var sprite: Sprite2D = $Sprite

var _walk_time := 0.0
var _bob_time := 0.0
var _sprite_base_y := 0.0
var _facing := Vector2.DOWN   # last direction we moved in

# Cutscenes / puzzles can freeze the character with set_can_move(false).
var can_move := true


func _ready():
	# If we've been in this scene before, spawn where we left it.
	var path = get_tree().current_scene.scene_file_path
	if GameState.spawn_points.has(path):
		global_position = GameState.spawn_points[path]

	# Default to facing front when a scene loads.
	if tex_front:
		sprite.texture = tex_front

	_sprite_base_y = sprite.position.y


func _physics_process(delta):
	var direction = Vector2.ZERO

	if player_controlled and can_move:
		if Input.is_key_pressed(KEY_W):
			direction.y -= 1

		if Input.is_key_pressed(KEY_S):
			direction.y += 1

		if Input.is_key_pressed(KEY_A):
			direction.x -= 1

		if Input.is_key_pressed(KEY_D):
			direction.x += 1

	velocity = direction.normalized() * speed

	move_and_slide()

	_update_sprite(direction, delta)
	_update_bob(direction, delta)


# Turn the character to face a direction without moving it. Usable from
# other scripts too, e.g. npc.face_direction(Vector2.LEFT).
func face_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	_facing = direction
	var standing = _poses_for(direction)[0]
	if standing:
		sprite.texture = standing


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
