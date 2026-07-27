extends CharacterBody2D

@export var interact_action: StringName = &"interact"
@export var prompt_label: Label
@export var move_speed: float = 200.0
@export var min_x: float = 0.0
@export var max_x: float = 1920.0
@export var min_y: float = 0.0
@export var max_y: float = 1080.0

var is_attached: bool = false
var player: CharacterBody2D = null
var detection_area: Area2D = null
var offset_from_player: Vector2 = Vector2.ZERO

func _ready():
	if prompt_label:
		prompt_label.visible = false
	detection_area = $DetectionArea
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		if not is_attached:
			prompt_label.text = "Press E to push block"
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player") and not is_attached:
		player = null
		prompt_label.visible = false

func _unhandled_input(event):
	if not player:
		return
	if event.is_action_pressed(interact_action):
		if is_attached:
			detach()
		else:
			attach()
		get_viewport().set_input_as_handled()

func attach():
	is_attached = true
	offset_from_player = global_position - player.global_position
	player.set_can_move(false)
	velocity = Vector2.ZERO
	prompt_label.text = "WASD move | Press E to release"
	prompt_label.visible = true

func detach():
	is_attached = false
	offset_from_player = Vector2.ZERO
	player.set_can_move(true)
	prompt_label.text = "Press E to push block"
	prompt_label.visible = true

func _physics_process(delta):
	if not is_attached or not player:
		return

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir == Vector2.ZERO:
		return

	var movement = input_dir.normalized() * move_speed * delta
	var new_box_pos = global_position + movement
	new_box_pos.x = clamp(new_box_pos.x, min_x, max_x)
	new_box_pos.y = clamp(new_box_pos.y, min_y, max_y)
	var actual_movement = new_box_pos - global_position
	global_position += actual_movement
	player.global_position += actual_movement
