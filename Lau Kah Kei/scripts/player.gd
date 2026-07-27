extends CharacterBody2D

@export var speed = 200

# Assign the 4 direction images in the Inspector (on player.tscn).
@export var tex_back: Texture2D    # W
@export var tex_front: Texture2D   # S
@export var tex_left: Texture2D    # A
@export var tex_right: Texture2D   # D

@onready var sprite: Sprite2D = $Sprite

# Walking bob (fake footsteps without extra art).
@export var bob_speed := 12.0    # how fast the little bounce is
@export var bob_height := 4.0    # how many pixels it bounces
var _bob_time := 0.0
var _sprite_base_y := 0.0


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

	_update_facing(direction)
	_update_bob(direction, delta)


func _update_facing(direction):
	if direction == Vector2.ZERO:
		return   # not moving: keep the last facing
	if direction.y < 0:
		sprite.texture = tex_back    # W
	elif direction.y > 0:
		sprite.texture = tex_front   # S
	elif direction.x < 0:
		sprite.texture = tex_left    # A
	elif direction.x > 0:
		sprite.texture = tex_right   # D


func _update_bob(direction, delta):
	if direction != Vector2.ZERO:
		# abs(sin) gives little upward hops, like footsteps.
		_bob_time += delta * bob_speed
		sprite.position.y = _sprite_base_y - abs(sin(_bob_time)) * bob_height
	else:
		# Standing still: settle back to the resting position.
		_bob_time = 0.0
		sprite.position.y = _sprite_base_y
