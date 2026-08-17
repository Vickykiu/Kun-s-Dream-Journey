extends Control


# ===== Board Settings =====

@export var rows: int = 14
@export var columns: int = 17
@export var mine_count: int = 18
@export var cell_scene: PackedScene

@export var restart_delay: float = 0.8
@export var memory_start_delay: float = 0.8


# ===== Memory Settings =====

@export var memory_image_size: Vector2 = Vector2(
	900,
	650
)


# ===== Memory 1 =====

@export var memory_image_1: Texture2D

@export var memory_1_speaker: String = "Kunkun"
@export var memory_1_portrait: Texture2D

@export var memory_1_lines: Array[DialogueLine] = []:
	set(value):
		memory_1_lines = DialogueLine.fill_blanks(value)


# ===== Memory 2 =====

@export var memory_image_2: Texture2D

@export var memory_2_speaker: String = "Kunkun"
@export var memory_2_portrait: Texture2D

@export var memory_2_lines: Array[DialogueLine] = []:
	set(value):
		memory_2_lines = DialogueLine.fill_blanks(value)


# ===== Nodes =====

@onready var grid: GridContainer = $BoardCenter/Grid

@onready var mine_counter_label: Label = (
	$MineCounterBackground/MineCounterLabel
)

@onready var flag_counter_label: Label = (
	$FlagCounterBackground/FlagCounterLabel
)

@onready var exit_button: Button = $ExitButton


# ===== Game State =====

var cells: Array = []

var flags_placed: int = 0

var mines_created: bool = false
var game_over: bool = false
var is_returning: bool = false


# ===== Memory State =====

var memory_started: bool = false


# ===== Memory Overlay =====

var memory_layer: CanvasLayer = null
var memory_background: ColorRect = null
var memory_texture_rect: TextureRect = null


# ===== Initialization =====

func _ready() -> void:
	randomize()

	exit_button.pressed.connect(
		_on_exit_button_pressed
	)

	create_board()
	restore_puzzle_progress()


# ===== Create Board =====

func create_board() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	cells.clear()

	flags_placed = 0

	mines_created = false
	game_over = false
	memory_started = false

	grid.columns = columns

	var total_cells: int = (
		rows * columns
	)

	for i: int in range(total_cells):
		var cell = cell_scene.instantiate()

		grid.add_child(cell)

		cell.setup(i)

		cell.reveal_requested.connect(
			_on_reveal_requested
		)

		cell.flag_requested.connect(
			_on_flag_requested
		)

		cells.append(cell)

	update_counters()


# ===== Reveal Request =====

func _on_reveal_requested(index: int) -> void:
	if game_over:
		return

	if memory_started:
		return

	if index < 0 or index >= cells.size():
		return

	var cell = cells[index]

	if cell.is_flagged:
		return

	# Create mines after the first click.
	if not mines_created:
		create_mines(index)
		calculate_numbers()

		mines_created = true

		# Recalculate correct flags after mines exist.
		update_counters()

	reveal_cell(index)

	# Save progress after revealing.
	if not game_over:
		save_puzzle_progress()


# ===== Create Mines =====

func create_mines(safe_index: int) -> void:
	var attempts: int = 0
	var valid_board: bool = false

	while not valid_board and attempts < 500:
		attempts += 1

		# Clear old mines.
		for cell in cells:
			cell.has_mine = false

		var available: Array[int] = []

		for i: int in range(cells.size()):
			if i != safe_index:
				available.append(i)

		available.shuffle()

		var amount: int = min(
			mine_count,
			available.size()
		)

		for i: int in range(amount):
			var mine_index: int = (
				available[i]
			)

			cells[mine_index].has_mine = true

		valid_board = board_is_valid()


# ===== Validate Board =====

func board_is_valid() -> bool:
	for i: int in range(cells.size()):
		if cells[i].has_mine:
			continue

		var nearby_mines: int = 0

		for neighbour_index: int in get_neighbours(i):
			if cells[neighbour_index].has_mine:
				nearby_mines += 1

		# Maximum number shown is 4.
		if nearby_mines > 4:
			return false

	return true


# ===== Calculate Numbers =====

func calculate_numbers() -> void:
	for i: int in range(cells.size()):
		if cells[i].has_mine:
			continue

		var nearby_mines: int = 0

		for neighbour_index: int in get_neighbours(i):
			if cells[neighbour_index].has_mine:
				nearby_mines += 1

		cells[i].adjacent_mines = (
			nearby_mines
		)


# ===== Reveal Cell =====

func reveal_cell(index: int) -> void:
	if game_over:
		return

	if index < 0 or index >= cells.size():
		return

	var cell = cells[index]

	if cell.is_revealed:
		return

	if cell.is_flagged:
		return

	# Mine clicked.
	if cell.has_mine:
		cell.show_mine(true)

		restart_after_mine()
		return

	# Reveal safe cell.
	cell.reveal()

	# Reveal nearby cells when empty.
	if cell.adjacent_mines == 0:
		for neighbour_index: int in get_neighbours(index):
			reveal_cell(
				neighbour_index
			)


# ===== Restart After Mine =====

func restart_after_mine() -> void:
	if game_over:
		return

	game_over = true

	# Delete saved progress after failure.
	MinesweeperState.clear_puzzle_progress(
		MinesweeperState.active_crystal_id
	)

	# Keep the red mine visible briefly.
	await get_tree().create_timer(
		restart_delay
	).timeout

	create_board()


# ===== Flag =====

func _on_flag_requested(index: int) -> void:
	if game_over:
		return

	if memory_started:
		return

	if index < 0 or index >= cells.size():
		return

	var cell = cells[index]

	if cell.is_revealed:
		return

	# Remove flag.
	if cell.is_flagged:
		cell.set_flagged(false)

		flags_placed -= 1

		update_counters()
		save_puzzle_progress()

		return

	# Stop when all flags are used.
	if flags_placed >= mine_count:
		return

	# Place flag.
	cell.set_flagged(true)

	flags_placed += 1

	update_counters()
	save_puzzle_progress()

	if mines_created:
		check_flag_win()


# ===== Counters =====

func update_counters() -> void:
	var correct_flags: int = 0

	# Count only flags placed on real mines.
	if mines_created:
		for cell in cells:
			if (
				cell.is_flagged
				and cell.has_mine
			):
				correct_flags += 1

	var remaining_mines: int = (
		mine_count - correct_flags
	)

	remaining_mines = max(
		remaining_mines,
		0
	)

	# Mine counter decreases only for correct flags.
	mine_counter_label.text = (
		"%03d" % remaining_mines
	)

	# Flag counter counts all placed flags.
	flag_counter_label.text = (
		"%03d" % flags_placed
	)


# ===== Flag Win =====

func check_flag_win() -> void:
	if not mines_created:
		return

	if flags_placed != mine_count:
		return

	var correct_flags: int = 0

	for cell in cells:
		if (
			cell.is_flagged
			and cell.has_mine
		):
			correct_flags += 1

	# All flags must be correct.
	if correct_flags == mine_count:
		complete_puzzle()


# ===== Complete Puzzle =====

func complete_puzzle() -> void:
	if game_over:
		return

	game_over = true

	# Change correct flags into mines.
	show_flagged_mines()

	await get_tree().create_timer(
		memory_start_delay
	).timeout

	start_memory_sequence()


# ===== Show Flagged Mines =====

func show_flagged_mines() -> void:
	for cell in cells:
		if (
			cell.is_flagged
			and cell.has_mine
		):
			cell.show_mine(false)


# ===== Neighbours =====

func get_neighbours(index: int) -> Array[int]:
	var neighbours: Array[int] = []

	var row: int = floori(
		float(index)
		/ float(columns)
	)

	var column: int = (
		index % columns
	)

	for row_offset: int in range(-1, 2):
		for column_offset: int in range(-1, 2):

			if (
				row_offset == 0
				and column_offset == 0
			):
				continue

			var new_row: int = (
				row + row_offset
			)

			var new_column: int = (
				column + column_offset
			)

			if new_row < 0:
				continue

			if new_row >= rows:
				continue

			if new_column < 0:
				continue

			if new_column >= columns:
				continue

			var neighbour_index: int = (
				new_row * columns
				+ new_column
			)

			neighbours.append(
				neighbour_index
			)

	return neighbours


# ===== Save Progress =====

func save_puzzle_progress() -> void:
	if MinesweeperState.active_crystal_id.is_empty():
		return

	if game_over:
		return

	var mine_indexes: Array[int] = []
	var revealed_indexes: Array[int] = []
	var flagged_indexes: Array[int] = []

	for i: int in range(cells.size()):
		var cell = cells[i]

		if cell.has_mine:
			mine_indexes.append(i)

		if cell.is_revealed:
			revealed_indexes.append(i)

		if cell.is_flagged:
			flagged_indexes.append(i)

	var data: Dictionary = {
		"rows": rows,
		"columns": columns,
		"mine_count": mine_count,
		"mines_created": mines_created,
		"mine_indexes": mine_indexes,
		"revealed_indexes": revealed_indexes,
		"flagged_indexes": flagged_indexes
	}

	MinesweeperState.save_puzzle_progress(
		MinesweeperState.active_crystal_id,
		data
	)


# ===== Restore Progress =====

func restore_puzzle_progress() -> void:
	var crystal_id: String = (
		MinesweeperState.active_crystal_id
	)

	if crystal_id.is_empty():
		return

	if not MinesweeperState.has_puzzle_progress(
		crystal_id
	):
		return

	var data: Dictionary = (
		MinesweeperState.get_puzzle_progress(
			crystal_id
		)
	)

	if data.is_empty():
		return

	# Check board size.
	if int(data.get("rows", rows)) != rows:
		return

	if int(
		data.get(
			"columns",
			columns
		)
	) != columns:
		return

	if int(
		data.get(
			"mine_count",
			mine_count
		)
	) != mine_count:
		return

	mines_created = bool(
		data.get(
			"mines_created",
			false
		)
	)

	var mine_indexes: Array = (
		data.get(
			"mine_indexes",
			[]
		)
	)

	var revealed_indexes: Array = (
		data.get(
			"revealed_indexes",
			[]
		)
	)

	var flagged_indexes: Array = (
		data.get(
			"flagged_indexes",
			[]
		)
	)

	# Restore mines.
	for value in mine_indexes:
		var mine_index: int = int(value)

		if (
			mine_index >= 0
			and mine_index < cells.size()
		):
			cells[mine_index].has_mine = true

	# Restore numbers.
	if mines_created:
		calculate_numbers()

	# Restore revealed cells.
	for value in revealed_indexes:
		var reveal_index: int = int(value)

		if (
			reveal_index >= 0
			and reveal_index < cells.size()
		):
			cells[reveal_index].reveal()

	# Restore flags.
	flags_placed = 0

	for value in flagged_indexes:
		var flag_index: int = int(value)

		if (
			flag_index >= 0
			and flag_index < cells.size()
		):
			cells[flag_index].set_flagged(
				true
			)

			flags_placed += 1

	update_counters()


# ===== Memory Sequence =====

func start_memory_sequence() -> void:
	memory_started = true

	exit_button.disabled = true

	create_memory_overlay()

	# Memory 1.
	show_memory_image(
		memory_image_1
	)

	await play_memory_dialogue(
		memory_1_lines,
		memory_1_portrait,
		memory_1_speaker
	)

	# Memory 2.
	show_memory_image(
		memory_image_2
	)

	await play_memory_dialogue(
		memory_2_lines,
		memory_2_portrait,
		memory_2_speaker
	)

	# Complete crystal only after both memories.
	MinesweeperState.clear_puzzle_progress(
		MinesweeperState.active_crystal_id
	)

	MinesweeperState.complete_active_crystal()

	memory_started = false

	return_to_saved_scene()


# ===== Create Memory Overlay =====

func create_memory_overlay() -> void:
	if memory_layer != null:
		return

	memory_layer = CanvasLayer.new()
	memory_layer.layer = 50

	add_child(
		memory_layer
	)

	# Dark background.
	memory_background = ColorRect.new()

	memory_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	memory_background.color = Color(
		0,
		0,
		0,
		0.85
	)

	memory_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	memory_layer.add_child(
		memory_background
	)

	# Center container.
	var center: CenterContainer = (
		CenterContainer.new()
	)

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	center.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	memory_layer.add_child(
		center
	)

	# Memory image.
	memory_texture_rect = (
		TextureRect.new()
	)

	memory_texture_rect.custom_minimum_size = (
		memory_image_size
	)

	memory_texture_rect.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	memory_texture_rect.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	memory_texture_rect.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	center.add_child(
		memory_texture_rect
	)


# ===== Show Memory Image =====

func show_memory_image(
	texture: Texture2D
) -> void:
	if memory_texture_rect == null:
		return

	memory_texture_rect.texture = texture


# ===== Memory Dialogue =====

func play_memory_dialogue(
	lines: Array[DialogueLine],
	portrait: Texture2D,
	speaker: String
) -> void:
	if lines.is_empty():
		return

	Dialogue.show_lines(
		lines,
		portrait,
		speaker
	)

	await get_tree().process_frame

	while Dialogue.is_active():
		await get_tree().process_frame


# ===== Exit =====

func _on_exit_button_pressed() -> void:
	if memory_started:
		return

	# Save current board before leaving.
	save_puzzle_progress()

	return_to_saved_scene()


# ===== Return =====

func return_to_saved_scene() -> void:
	if is_returning:
		return

	if (
		MinesweeperState
		.return_scene_path
		.is_empty()
	):
		print(
			"No return scene saved."
		)
		return

	is_returning = true

	get_tree().change_scene_to_file(
		MinesweeperState.return_scene_path
	)
