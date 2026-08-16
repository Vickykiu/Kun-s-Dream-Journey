extends Node


# ===== Initialization =====

func _ready() -> void:
	call_deferred(
		"restore_player_position"
	)


# ===== Restore Player =====

func restore_player_position() -> void:
	if not MinesweeperState.has_return_position:
		return

	# Wait until the player is ready.
	await get_tree().process_frame
	await get_tree().physics_frame

	var player: Node2D = (
		get_tree().get_first_node_in_group(
			"player"
		) as Node2D
	)

	if player == null:
		print("Player not found.")
		return

	player.global_position = (
		MinesweeperState.return_position
	)

	# Stop movement after returning.
	if player is CharacterBody2D:
		var character: CharacterBody2D = (
			player as CharacterBody2D
		)

		character.velocity = Vector2.ZERO

	MinesweeperState.clear_return_position()
