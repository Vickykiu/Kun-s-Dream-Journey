extends CharacterBody2D

# Shared character script. One script, many characters:
# duplicate player.tscn, drop in a different set of textures in the
# Inspector, and you have a new character with the same movement.

@export var speed = 200

# Set to false for NPCs / other characters that shouldn't read WASD.
# They can still be turned from code with face_direction().
@export var player_controlled := true

@export_group("Facing textures")
# The 4 basics. These are the minimum a character needs.
@export var tex_back: Texture2D    # W
@export var tex_front: Texture2D   # S
@export var tex_left: Texture2D    # A
@export var tex_right: Texture2D   # D
# The 4 diagonals. Optional — leave them empty and the character falls
# back to the nearest basic direction, so nothing breaks before the art
# is drawn.
@export var tex_back_left: Texture2D    # W + A
@export var tex_back_right: Texture2D   # W + D
@export var tex_front_left: Texture2D   # S + A
@export var tex_front_right: Texture2D  # S + D

@onready var sprite: Sprite2D = $Sprite

# Walking bob (fake footsteps without extra art).
@export_group("Walk bob")
@export var bob_speed := 12.0    # how fast the little bounce is
@export var bob_height := 4.0    # how many pixels it bounces
var _bob_time := 0.0
var _sprite_base_y := 0.0

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

	face_direction(direction)
	_update_bob(direction, delta)


# Turn the character to face a direction. Also usable from other scripts,
# e.g. npc.face_direction(Vector2.LEFT).
func face_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return   # not moving: keep the last facing
	var tex = _texture_for(direction)
	if tex:
		sprite.texture = tex


# Split the full circle into 8 slices of 45 degrees. Slice 0 is right,
# and the angle grows clockwise on screen because +Y points down in 2D.
func _texture_for(direction: Vector2) -> Texture2D:
	var slice = int(round(direction.angle() / (PI / 4.0))) % 8
	if slice < 0:
		slice += 8
	match slice:
		0: return tex_right
		1: return _or(tex_front_right, tex_right)
		2: return tex_front
		3: return _or(tex_front_left, tex_left)
		4: return tex_left
		5: return _or(tex_back_left, tex_left)
		6: return tex_back
		7: return _or(tex_back_right, tex_right)
	return null


# Use the diagonal art if it exists, otherwise the nearest basic one.
func _or(diagonal: Texture2D, basic: Texture2D) -> Texture2D:
	if diagonal:
		return diagonal
	return basic


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
