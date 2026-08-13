extends Node2D

const SAFE_UI_SCENE = preload("res://Lew Jia Jia/scenes/safe_ui.tscn")

var is_safe_opened: bool = false
var safe_ui_instance: Node = null

@onready var safe_closed = $Safe
@onready var safe_open = $SafeOpen


# Only Safe > Area2D should connect to this function
func _on_safe_area_2d_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			# Do not reopen the password UI after the safe is unlocked
			if is_safe_opened:
				print("The safe is already open.")
				return

			# Prevent multiple Safe UIs from appearing
			if is_instance_valid(safe_ui_instance):
				return

			safe_ui_instance = SAFE_UI_SCENE.instantiate()
			add_child(safe_ui_instance)

			safe_ui_instance.safe_opened.connect(_on_safe_unlocked)
			safe_ui_instance.tree_exited.connect(_on_safe_ui_closed)


func _on_safe_unlocked() -> void:
	is_safe_opened = true

	if safe_closed:
		safe_closed.visible = false

	if safe_open:
		safe_open.visible = true


func _on_safe_ui_closed() -> void:
	safe_ui_instance = null
