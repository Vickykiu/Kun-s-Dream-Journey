extends Node2D


# ==================================================
# UI Scenes
# ==================================================

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

const DESK_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/DeskUI.tscn"
)

const VENT_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/vent_ui.tscn"
)

const ELECTRIC_BOX_UI_SCENE = preload(
	"res://Lew Jia Jia/scenes/electric_box_ui.tscn"
)

const VENT_ESCAPE_SCENE = preload(
	"res://Lew Jia Jia/scenes/ventEscape.tscn"
)


# ==================================================
# State
# ==================================================

var is_safe_opened: bool = false
var is_vent_unlocked: bool = false

var safe_ui_instance: Node = null
var cabinet_ui_instance: Node = null
var colour_hint_ui_instance: Node = null
var clock_ui_instance: Node = null
var calendar_ui_instance: Node = null
var desk_ui_instance: Node = null
var vent_ui_instance: Node = null
var electric_box_ui_instance: Node = null


# ==================================================
# Safe Nodes
# ==================================================

@onready var safe_closed = $Safe
@onready var safe_open = $SafeOpen


# ==================================================
# Reject Hint
# ==================================================

var reject_hint_layer: CanvasLayer = null
var reject_hint_root: Control = null
var reject_hint_label: Label = null


# ==================================================
# Initialization
# ==================================================

func _ready() -> void:
	# Load the Vent unlock state.
	is_vent_unlocked = GameState.has_flag(
		"chapter3_vent_unlocked"
	)

	create_reject_hint_ui()

	if reject_hint_label:
		reject_hint_label.visible = false

	call_deferred(
		"check_reject_return"
	)


# ==================================================
# Create Reject Hint UI
# ==================================================

func create_reject_hint_ui() -> void:
	var existing_layer = get_node_or_null(
		"RejectHintLayer"
	)

	if existing_layer is CanvasLayer:
		reject_hint_layer = (
			existing_layer as CanvasLayer
		)
	else:
		reject_hint_layer = CanvasLayer.new()
		reject_hint_layer.name = "RejectHintLayer"
		reject_hint_layer.layer = 50

		add_child(
			reject_hint_layer
		)

	var existing_root = reject_hint_layer.get_node_or_null(
		"HintRoot"
	)

	if existing_root is Control:
		reject_hint_root = (
			existing_root as Control
		)
	else:
		reject_hint_root = Control.new()
		reject_hint_root.name = "HintRoot"

		reject_hint_layer.add_child(
			reject_hint_root
		)

		reject_hint_root.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)

		reject_hint_root.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

	var existing_label = reject_hint_root.get_node_or_null(
		"RejectHintLabel"
	)

	if existing_label is Label:
		reject_hint_label = (
			existing_label as Label
		)
	else:
		reject_hint_label = Label.new()
		reject_hint_label.name = "RejectHintLabel"

		reject_hint_root.add_child(
			reject_hint_label
		)

		setup_reject_hint_label()


# ==================================================
# Reject Hint Layout
# ==================================================

func setup_reject_hint_label() -> void:
	reject_hint_label.anchor_left = 0.0
	reject_hint_label.anchor_top = 1.0
	reject_hint_label.anchor_right = 0.0
	reject_hint_label.anchor_bottom = 1.0

	reject_hint_label.offset_left = 40.0
	reject_hint_label.offset_top = -170.0
	reject_hint_label.offset_right = 900.0
	reject_hint_label.offset_bottom = -40.0

	reject_hint_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	reject_hint_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	reject_hint_label.add_theme_font_size_override(
		"font_size",
		24
	)


# ==================================================
# Interaction UI Check
# ==================================================

func _is_interaction_ui_open() -> bool:
	return (
		is_instance_valid(safe_ui_instance)
		or is_instance_valid(cabinet_ui_instance)
		or is_instance_valid(colour_hint_ui_instance)
		or is_instance_valid(clock_ui_instance)
		or is_instance_valid(calendar_ui_instance)
		or is_instance_valid(desk_ui_instance)
		or is_instance_valid(vent_ui_instance)
		or is_instance_valid(electric_box_ui_instance)
	)


# ==================================================
# Cabinet Interaction
# ==================================================

func _on_cabinet_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	cabinet_ui_instance = (
		CABINET_UI_SCENE.instantiate()
	)

	add_child(
		cabinet_ui_instance
	)

	cabinet_ui_instance.tree_exited.connect(
		_on_cabinet_ui_closed
	)


func _on_cabinet_ui_closed() -> void:
	cabinet_ui_instance = null


# ==================================================
# Safe Interaction
# ==================================================

func _on_safe_interacted(
	_node: Variant
) -> void:
	if is_safe_opened:
		print(
			"The safe is already open."
		)
		return

	if _is_interaction_ui_open():
		return

	safe_ui_instance = (
		SAFE_UI_SCENE.instantiate()
	)

	add_child(
		safe_ui_instance
	)

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


# ==================================================
# Colour Hint Interaction
# ==================================================

func _on_colour_hint_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	colour_hint_ui_instance = (
		COLOUR_HINT_UI_SCENE.instantiate()
	)

	add_child(
		colour_hint_ui_instance
	)

	colour_hint_ui_instance.tree_exited.connect(
		_on_colour_hint_ui_closed
	)


func _on_colour_hint_ui_closed() -> void:
	colour_hint_ui_instance = null


# ==================================================
# Clock Interaction
# ==================================================

func _on_clock_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	clock_ui_instance = (
		CLOCK_UI_SCENE.instantiate()
	)

	add_child(
		clock_ui_instance
	)

	clock_ui_instance.tree_exited.connect(
		_on_clock_ui_closed
	)


func _on_clock_ui_closed() -> void:
	clock_ui_instance = null


# ==================================================
# Calendar Interaction
# ==================================================

func _on_calendar_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	calendar_ui_instance = (
		CALENDAR_UI_SCENE.instantiate()
	)

	add_child(
		calendar_ui_instance
	)

	calendar_ui_instance.tree_exited.connect(
		_on_calendar_ui_closed
	)


func _on_calendar_ui_closed() -> void:
	calendar_ui_instance = null


# ==================================================
# Desk Interaction
# ==================================================

func _on_desk_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	desk_ui_instance = (
		DESK_UI_SCENE.instantiate()
	)

	add_child(
		desk_ui_instance
	)

	desk_ui_instance.tree_exited.connect(
		_on_desk_ui_closed
	)


func _on_desk_ui_closed() -> void:
	desk_ui_instance = null


# ==================================================
# Vent Interaction
# ==================================================

func _on_vent_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	# Vent remains locked before solving the wire puzzle.
	if not is_vent_unlocked:
		Dialogue.show_text(
			"The ventilation cover is still locked.\n"
			+ "Something seems to be controlling it."
		)
		return

	# Open the Vent UI after unlocking it.
	vent_ui_instance = (
		VENT_UI_SCENE.instantiate()
	)

	add_child(
		vent_ui_instance
	)

	# Receive the Enter Vent result from VentUI.
	vent_ui_instance.vent_entered.connect(
		_on_vent_entered
	)

	vent_ui_instance.tree_exited.connect(
		_on_vent_ui_closed
	)


func _on_vent_entered() -> void:
	print(
		"Player entered the ventilation shaft."
	)

	get_tree().change_scene_to_packed(
		VENT_ESCAPE_SCENE
	)


func _on_vent_ui_closed() -> void:
	vent_ui_instance = null


# ==================================================
# Electric Box Interaction
# ==================================================

func _on_electric_box_interacted(
	_node: Variant
) -> void:
	if _is_interaction_ui_open():
		return

	electric_box_ui_instance = (
		ELECTRIC_BOX_UI_SCENE.instantiate()
	)

	add_child(
		electric_box_ui_instance
	)

	electric_box_ui_instance.puzzle_solved.connect(
		_on_wire_puzzle_solved
	)

	electric_box_ui_instance.tree_exited.connect(
		_on_electric_box_ui_closed
	)


func _on_wire_puzzle_solved() -> void:
	is_vent_unlocked = true

	GameState.set_flag(
		"chapter3_vent_unlocked"
	)

	print(
		"Wire puzzle solved! Vent unlocked."
	)


func _on_electric_box_ui_closed() -> void:
	electric_box_ui_instance = null


# ==================================================
# Reject Return
# ==================================================

func check_reject_return() -> void:
	print(
		"Reject hint pending: ",
		MinesweeperState.reject_hint_pending
	)

	if not MinesweeperState.reject_hint_pending:
		return

	print(
		"Reject return detected."
	)

	MinesweeperState.reject_hint_pending = false

	# Remove the black screen slowly.
	await fade_reject_transition()

	# Wait before showing the hint.
	await get_tree().create_timer(
		0.8
	).timeout

	await show_reject_hint()


# ==================================================
# Reject Transition
# ==================================================

func fade_reject_transition() -> void:
	var transition_layer = get_node_or_null(
		"/root/RejectTransitionLayer"
	)

	if transition_layer == null:
		print(
			"No RejectTransitionLayer found."
		)
		return

	var black_screen = transition_layer.get_node_or_null(
		"BlackScreen"
	)

	if black_screen == null:
		print(
			"No BlackScreen found."
		)

		transition_layer.queue_free()

		return

	print(
		"Fading reject black screen."
	)

	var fade_out: Tween = create_tween()

	fade_out.tween_property(
		black_screen,
		"color:a",
		0.0,
		1.5
	)

	await fade_out.finished

	transition_layer.queue_free()


# ==================================================
# Reject Hint
# ==================================================

func show_reject_hint() -> void:
	if reject_hint_label == null:
		print(
			"RejectHintLabel is null."
		)
		return

	print(
		"Showing reject hint."
	)

	reject_hint_label.text = (
		"...By the way, I tried breaking through "
		+ "the ventilation shaft too.\n"
		+ "I never made it to the end of that path."
	)

	reject_hint_label.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	reject_hint_label.visible = true

	# Fade in.
	var fade_in: Tween = create_tween()

	fade_in.tween_property(
		reject_hint_label,
		"modulate:a",
		1.0,
		1.0
	)

	await fade_in.finished

	# Stay visible.
	await get_tree().create_timer(
		5.0
	).timeout

	# Fade out.
	var fade_out: Tween = create_tween()

	fade_out.tween_property(
		reject_hint_label,
		"modulate:a",
		0.0,
		1.5
	)

	await fade_out.finished

	reject_hint_label.visible = false
