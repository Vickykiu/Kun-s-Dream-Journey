extends Area2D

@export var interact_action: StringName = &"interact"
@export var prompt_label: Label
@export var image_to_show: Texture

var overlay: TextureRect = null
var is_image_showing: bool = false
var has_triggered: bool = false

func _ready():
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") and not has_triggered:
		if prompt_label:
			prompt_label.text = "Press E to see memory"
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event):
	if not event.is_action_pressed(interact_action):
		return

	if is_image_showing:
		close_image()
		get_viewport().set_input_as_handled()
		return

	if prompt_label and prompt_label.visible and not has_triggered:
		show_image()
		get_viewport().set_input_as_handled()

func show_image():
	if prompt_label:
		prompt_label.visible = false

	# 隐藏所有 Sprite2D 子节点（无论名字是什么）
	for child in get_children():
		if child is Sprite2D:
			child.visible = false

	if overlay == null:
		overlay = TextureRect.new()
		overlay.size = Vector2(1920, 1080)
		overlay.position = Vector2.ZERO
		var bg = ColorRect.new()
		bg.size = Vector2(1920, 1080)
		bg.color = Color(0, 0, 0, 0.7)
		overlay.add_child(bg)
		var img = TextureRect.new()
		img.texture = image_to_show
		img.size = Vector2(800, 600)
		img.position = Vector2(560, 240)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		overlay.add_child(img)
		var label = Label.new()
		label.text = "Press E to close"
		label.position = Vector2(860, 900)
		overlay.add_child(label)
		get_tree().current_scene.add_child(overlay)

	overlay.visible = true
	is_image_showing = true
	has_triggered = true
	monitoring = false

func close_image():
	if overlay:
		overlay.visible = false
	is_image_showing = false
