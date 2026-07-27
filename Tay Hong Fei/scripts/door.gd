extends Area2D

@export var interact_action: StringName = &"interact"
@export var next_scene_action: StringName = &"next_scene"
@export var prompt_label: Label
@export var image_to_show: Texture
@export var target_scene: PackedScene

var is_player_near: bool = false
var has_triggered_e: bool = false
var has_triggered_f: bool = false
var is_image_showing: bool = false
var overlay: TextureRect = null

func _ready():
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_near = true
		if prompt_label:
			prompt_label.text = "E: View image | F: Next scene"
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_near = false
		if prompt_label:
			prompt_label.visible = false
		has_triggered_e = false
		has_triggered_f = false

func _unhandled_input(event):
	if not is_player_near and not is_image_showing:
		return

	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		if is_image_showing:
			close_image()
			return
		if not has_triggered_e:
			has_triggered_e = true
			show_image()
		return

	if event.is_action_pressed(next_scene_action) and not has_triggered_f:
		has_triggered_f = true
		get_viewport().set_input_as_handled()
		go_to_next_scene()

func show_image():
	if prompt_label:
		prompt_label.visible = false

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

func close_image():
	if overlay:
		overlay.visible = false
	is_image_showing = false
	has_triggered_e = false

func go_to_next_scene():
	if prompt_label:
		prompt_label.visible = false
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
	else:
		has_triggered_f = false
		print("No target scene assigned for F key!")
