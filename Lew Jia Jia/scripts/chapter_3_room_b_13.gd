extends Node2D

const SAFE_UI_SCENE = preload("res://Lew Jia Jia/scenes/safe_ui.tscn")
var is_safe_opened: bool = false 

# --- Node References ---
# Reference to the original closed safe sprite
@onready var safe_closed = $Safe 

# Reference to the newly created open safe sprite
# (Make sure this node in your Scene Tree is named "SafeOpen")
@onready var safe_open = $SafeOpen 


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# If the safe is already unlocked, prevent opening the password UI again
		if is_safe_opened:
			print("The safe is already open.")
			return
		
		# Instantiate and show the Safe UI
		var safe_ui = SAFE_UI_SCENE.instantiate()
		add_child(safe_ui)
		
		# Listen to the 'safe_opened' signal from SafeUI
		safe_ui.safe_opened.connect(_on_safe_unlocked)


# Function triggered when the correct password is entered
func _on_safe_unlocked():
	is_safe_opened = true
	
	# Hide the closed safe sprite and display the open safe sprite
	if safe_closed:
		safe_closed.visible = false
	if safe_open:
		safe_open.visible = true
