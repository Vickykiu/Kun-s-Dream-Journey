extends CharacterBody2D

@export var speed = 200

var can_move: bool = true

func _physics_process(delta):
	if not can_move:
		return
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

func set_can_move(value: bool):
	can_move = value
