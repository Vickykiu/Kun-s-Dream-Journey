extends TextureButton


# ===== Signals =====

signal reveal_requested(index: int)
signal flag_requested(index: int)


# ===== Cell Textures =====

@export var texture_covered: Texture2D
@export var texture_empty: Texture2D

@export var texture_1: Texture2D
@export var texture_2: Texture2D
@export var texture_3: Texture2D
@export var texture_4: Texture2D

@export var texture_flag: Texture2D
@export var texture_mine: Texture2D
@export var texture_exploded: Texture2D


# ===== State =====

var cell_index: int = -1

var has_mine: bool = false
var adjacent_mines: int = 0

var is_revealed: bool = false
var is_flagged: bool = false


# ===== Initialization =====

func _ready() -> void:
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE

	if texture_covered:
		texture_normal = texture_covered


func setup(index: int) -> void:
	cell_index = index

	has_mine = false
	adjacent_mines = 0

	is_revealed = false
	is_flagged = false

	mouse_filter = Control.MOUSE_FILTER_STOP

	if texture_covered:
		texture_normal = texture_covered


# ===== Mouse Input =====

func _gui_input(event: InputEvent) -> void:
	if is_revealed:
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if not mouse_event.pressed:
		return

	# Left-click reveals the cell.
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if not is_flagged:
			reveal_requested.emit(cell_index)

		accept_event()
		return

	# Right-click places or removes a flag.
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		flag_requested.emit(cell_index)

		accept_event()


# ===== Flag =====

func set_flagged(value: bool) -> void:
	if is_revealed:
		return

	is_flagged = value

	if is_flagged:
		if texture_flag:
			texture_normal = texture_flag

	else:
		if texture_covered:
			texture_normal = texture_covered


# ===== Reveal =====

func reveal() -> void:
	if is_revealed:
		return

	is_revealed = true
	is_flagged = false

	if has_mine:
		if texture_mine:
			texture_normal = texture_mine

	else:
		texture_normal = get_number_texture(
			adjacent_mines
		)

	mouse_filter = Control.MOUSE_FILTER_IGNORE


# ===== Mine =====

func show_mine(exploded: bool = false) -> void:
	is_revealed = true
	is_flagged = false

	if exploded and texture_exploded:
		texture_normal = texture_exploded

	elif texture_mine:
		texture_normal = texture_mine

	mouse_filter = Control.MOUSE_FILTER_IGNORE


# ===== Number Texture =====

func get_number_texture(number: int) -> Texture2D:
	match number:
		0:
			return texture_empty

		1:
			return texture_1

		2:
			return texture_2

		3:
			return texture_3

		4:
			return texture_4

	return texture_empty
