extends Node


# ===== Return Data =====

var return_scene_path: String = ""
var return_position: Vector2 = Vector2.ZERO
var has_return_position: bool = false


# ===== Crystal Data =====

var active_crystal_id: String = ""
var completed_crystals: Dictionary = {}


# ===== Puzzle Progress =====

var puzzle_progress: Dictionary = {}


# ===== Save Entry Data =====

func save_entry_data(
	scene_path: String,
	player_position: Vector2,
	crystal_id: String
) -> void:
	return_scene_path = scene_path
	return_position = player_position
	has_return_position = true

	active_crystal_id = crystal_id


# ===== Complete Crystal =====

func complete_active_crystal() -> void:
	if active_crystal_id.is_empty():
		return

	completed_crystals[
		active_crystal_id
	] = true

	clear_puzzle_progress(
		active_crystal_id
	)


# ===== Check Crystal =====

func is_crystal_completed(
	crystal_id: String
) -> bool:
	return completed_crystals.get(
		crystal_id,
		false
	)


# ===== Save Puzzle Progress =====

func save_puzzle_progress(
	crystal_id: String,
	data: Dictionary
) -> void:
	if crystal_id.is_empty():
		return

	puzzle_progress[
		crystal_id
	] = data.duplicate(true)


# ===== Get Puzzle Progress =====

func get_puzzle_progress(
	crystal_id: String
) -> Dictionary:
	if not puzzle_progress.has(
		crystal_id
	):
		return {}

	return puzzle_progress[
		crystal_id
	].duplicate(true)


# ===== Check Puzzle Progress =====

func has_puzzle_progress(
	crystal_id: String
) -> bool:
	return puzzle_progress.has(
		crystal_id
	)


# ===== Clear Puzzle Progress =====

func clear_puzzle_progress(
	crystal_id: String
) -> void:
	if puzzle_progress.has(
		crystal_id
	):
		puzzle_progress.erase(
			crystal_id
		)


# ===== Clear Return Position =====

func clear_return_position() -> void:
	has_return_position = false
