extends Node2D

const SAFE_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/safe_ui.tscn"
)

const CABINET_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/cabinet_ui.tscn"
)

const COLOUR_HINT_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/colour_hint_ui.tscn"
)

const CLOCK_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/clock_ui.tscn"
)

const CALENDAR_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/calendar_ui.tscn"
)

var is_safe_opened: bool = false
var safe_ui_instance: Node = null
var cabinet_ui_instance: Node = null
var colour_hint_ui_instance: Node = null
var clock_ui_instance: Node = null
var calendar_ui_instance: Node = null

@onready var safe_closed = $Safe
@onready var safe_open = $SafeOpen

func _is_interaction_ui_open() -> bool:
	return (
		is_instance_valid(safe_ui_instance)
		or is_instance_valid(cabinet_ui_instance)
		or is_instance_valid(colour_hint_ui_instance)
		or is_instance_valid(clock_ui_instance)
		or is_instance_valid(calendar_ui_instance)
	)

# Cabinet Interaction
func _on_cabinet_interacted(_node: Variant) -> void:
	if _is_interaction_ui_open():
		return

	cabinet_ui_instance = CABINET_UI_SCENE.instantiate()
	add_child(cabinet_ui_instance)

	cabinet_ui_instance.tree_exited.connect(
		_on_cabinet_ui_closed
	)

func _on_cabinet_ui_closed() -> void:
	cabinet_ui_instance = null

# Safe Interaction
func _on_safe_interacted(_node: Variant) -> void:
	if is_safe_opened:
		print("The safe is already open.")
		return
		
	if _is_interaction_ui_open():
		return

	safe_ui_instance = SAFE_UI_SCENE.instantiate()
	add_child(safe_ui_instance)

	safe_ui_instance.safe_opened.connect(
		_on_safe_unlocked
	)

	safe_ui_instance.tree_exited.connect(
		_on_safe_ui_closed
	)
	
func _on_safe_unlocked() -> void:
	is_safe_opened = true

	if safe_closed:
		safe_closed.visible = false

	if safe_open:
		safe_open.visible = true


func _on_safe_ui_closed() -> void:
	safe_ui_instance = null

# Colour Hint Interaction
func _on_colour_hint_interacted(_node: Variant) -> void:
	if _is_interaction_ui_open():
		return

	colour_hint_ui_instance = (
		COLOUR_HINT_UI_SCENE.instantiate()
	)
	add_child(colour_hint_ui_instance)

	colour_hint_ui_instance.tree_exited.connect(
		_on_colour_hint_ui_closed
	)
	
func _on_colour_hint_ui_closed() -> void:
	colour_hint_ui_instance = null

# Clock Interaction
func _on_clock_interacted(_node: Variant) -> void:
	if _is_interaction_ui_open():
		return

	clock_ui_instance = CLOCK_UI_SCENE.instantiate()
	add_child(clock_ui_instance)

	clock_ui_instance.tree_exited.connect(
		_on_clock_ui_closed
	)
	
func _on_clock_ui_closed() -> void:
	clock_ui_instance = null

# Calendar Interaction
func _on_calendar_interacted(_node: Variant) -> void:
	if _is_interaction_ui_open():
		return

	calendar_ui_instance = CALENDAR_UI_SCENE.instantiate()
	add_child(calendar_ui_instance)

	calendar_ui_instance.tree_exited.connect(
		_on_calendar_ui_closed
	)
	
func _on_calendar_ui_closed() -> void:
	calendar_ui_instance = null
