extends Area2D


# ===== Settings =====

@export var interact_action: StringName = &"interact"
@export var minesweeper_scene: PackedScene


# ===== Nodes =====

@onready var crystal_label: Label = $CrystalLabel


# ===== State =====

var player_near: bool = false
var is_entering: bool = false
var current_player: Node2D = null


# ===== Initialization =====

func _ready() -> void:
	# Remove this crystal only after its puzzle is completed.
	if MinesweeperState.is_crystal_completed(
		String(name)
	):
		queue_free()
		return

	crystal_label.visible = false

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)


# ===== Player Detection =====

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if is_entering:
		return

	player_near = true
	current_player = body

	crystal_label.text = "Press E to interact"
	crystal_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_near = false
	current_player = null

	crystal_label.visible = false


# ===== Input =====

func _unhandled_input(event: InputEvent) -> void:
	if is_entering:
		return

	if not player_near:
		return

	if current_player == null:
		return

	if not event.is_action_pressed(
		interact_action
	):
		return

	get_viewport().set_input_as_handled()

	enter_minesweeper()


# ===== Enter Minesweeper =====

func enter_minesweeper() -> void:
	if minesweeper_scene == null:
		print("No Minesweeper scene assigned.")
		return

	if current_player == null:
		print("Player not found.")
		return

	var current_scene: Node = (
		get_tree().current_scene
	)

	if current_scene == null:
		print("Current scene not found.")
		return

	if current_scene.scene_file_path.is_empty():
		print("Current scene has no file path.")
		return

	is_entering = true
	player_near = false
	crystal_label.visible = false

	# Save the current scene, player position and crystal name.
	MinesweeperState.save_entry_data(
		current_scene.scene_file_path,
		current_player.global_position,
		String(name)
	)

	# Open the Minesweeper scene.
	get_tree().change_scene_to_packed(
		minesweeper_scene
	)
