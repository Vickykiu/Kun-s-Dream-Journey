extends CharacterBody2D
class_name PushableBlock


# ===== Settings =====

@export var interact_action: StringName = &"interact"
@export var prompt_label: Label
@export var move_speed: float = 200.0

@export var min_x: float = 0.0
@export var max_x: float = 1920.0
@export var min_y: float = 0.0
@export var max_y: float = 1080.0

@export var interactable: bool = true


# ===== Linked Blocks =====

@export var linked_blocks: Array[NodePath] = []

@export var mirror_x: bool = false
@export var mirror_y: bool = false


# ===== Interaction =====

# Optional node used as the centre of the block.
@export var interaction_anchor: Node2D


# ===== Snap Settings =====

@export var snap_enabled: bool = true

# Block snaps when it is within this distance.
@export var snap_distance: float = 10.0


# ===== Snap Targets =====

# Main block target positions.
const MAIN_SNAP_TARGETS = [
	Vector2(20.0, -181.0),
	Vector2(-129.0, -39.0),
	Vector2(20.0, 108.0)
]

# Matching linked block target positions.
const LINKED_SNAP_TARGETS = [
	Vector2(264.0, -180.0),
	Vector2(412.0, -41.0),
	Vector2(263.0, 109.0)
]


# ===== Snap Progress =====

# Number of completed block pairs.
static var snapped_pair_count: int = 0

# Prevents the same target from being counted twice.
static var snapped_slots: Array[bool] = [
	false,
	false,
	false
]


static func get_snapped_count() -> int:
	return snapped_pair_count


static func all_blocks_snapped() -> bool:
	return snapped_pair_count >= 3


static func reset_snap_progress() -> void:
	snapped_pair_count = 0

	snapped_slots = [
		false,
		false,
		false
	]


# ===== State =====

var is_attached: bool = false
var is_locked: bool = false

var player: CharacterBody2D = null
var detection_area: Area2D = null

var push_direction: Vector2 = Vector2.ZERO
var offset_from_player: Vector2 = Vector2.ZERO

var _is_syncing: bool = false
var _is_applying_external: bool = false

# Only one block can be attached at a time.
static var _attached_block: CharacterBody2D = null

# Prevents multiple blocks from using the same input.
static var _input_lock: bool = false


# ===== Initialization =====

func _ready() -> void:
	detection_area = get_node_or_null("DetectionArea") as Area2D

	if not is_in_group("pushable_blocks"):
		add_to_group("pushable_blocks")

	if prompt_label:
		prompt_label.visible = false

	if interactable:

		if detection_area:

			detection_area.body_entered.connect(
				_on_body_entered
			)

			detection_area.body_exited.connect(
				_on_body_exited
			)

	else:

		if detection_area:
			detection_area.monitoring = false


# ===== Detection =====

func _on_body_entered(body: Node2D) -> void:
	if is_locked or not interactable:
		return

	if not body.is_in_group("player"):
		return

	if not body is CharacterBody2D:
		return

	player = body as CharacterBody2D

	call_deferred(
		"refresh_all_prompts"
	)


func _on_body_exited(body: Node2D) -> void:
	if is_locked or not interactable:
		return

	if not body.is_in_group("player"):
		return

	# Keep player reference while pushing.
	if is_attached:
		return

	if body == player:
		player = null

	hide_prompt()

	call_deferred(
		"refresh_all_prompts"
	)


# ===== Player Direction =====

func get_player_facing_direction() -> Vector2:
	if player == null:
		return Vector2.ZERO

	if not player.has_method(
		"get_last_movement_direction"
	):
		return Vector2.ZERO

	var result = player.call(
		"get_last_movement_direction"
	)

	if not result is Vector2:
		return Vector2.ZERO

	var direction: Vector2 = result

	if direction == Vector2.ZERO:
		return Vector2.ZERO

	# Convert direction into four directions.
	if abs(direction.x) >= abs(direction.y):

		if direction.x > 0.0:
			return Vector2.RIGHT

		return Vector2.LEFT

	else:

		if direction.y > 0.0:
			return Vector2.DOWN

		return Vector2.UP


# ===== Visual Position =====

func get_player_visual_position() -> Vector2:
	if player == null:
		return Vector2.ZERO

	var player_collision: Node2D = (
		player.get_node_or_null(
			"CollisionShape2D"
		) as Node2D
	)

	if player_collision != null:

		return (
			player_collision
			.get_global_transform_with_canvas()
			.origin
		)

	return (
		player
		.get_global_transform_with_canvas()
		.origin
	)


func get_block_visual_position() -> Vector2:

	# Use manual anchor first.
	if interaction_anchor != null:

		return (
			interaction_anchor
			.get_global_transform_with_canvas()
			.origin
		)


	# Use detection collision centre.
	if detection_area != null:

		var detection_collision: Node2D = (
			detection_area.get_node_or_null(
				"CollisionShape2D"
			) as Node2D
		)

		if detection_collision != null:

			return (
				detection_collision
				.get_global_transform_with_canvas()
				.origin
			)


	# Use main collision.
	var main_collision: Node2D = (
		get_node_or_null(
			"CollisionShape2D"
		) as Node2D
	)

	if main_collision != null:

		return (
			main_collision
			.get_global_transform_with_canvas()
			.origin
		)


	# Use sprite position.
	var sprite_node: Node2D = (
		get_node_or_null(
			"Sprite2D"
		) as Node2D
	)

	if sprite_node != null:

		return (
			sprite_node
			.get_global_transform_with_canvas()
			.origin
		)


	return (
		get_global_transform_with_canvas()
		.origin
	)


# ===== Player Side =====

func get_player_side_direction() -> Vector2:
	if player == null:
		return Vector2.ZERO

	var player_pos: Vector2 = (
		get_player_visual_position()
	)

	var block_pos: Vector2 = (
		get_block_visual_position()
	)

	var diff: Vector2 = (
		block_pos - player_pos
	)

	if diff.length() < 0.001:
		return Vector2.ZERO


	# Player is on left or right side.
	if abs(diff.x) > abs(diff.y):

		# Player is left of the block.
		if diff.x > 0.0:
			return Vector2.RIGHT

		# Player is right of the block.
		return Vector2.LEFT


	# Player is above or below the block.
	else:

		# Player is above the block.
		if diff.y > 0.0:
			return Vector2.DOWN

		# Player is below the block.
		return Vector2.UP


func is_player_facing_this_block() -> bool:
	if is_locked or player == null:
		return false

	var facing: Vector2 = (
		get_player_facing_direction()
	)

	var required: Vector2 = (
		get_player_side_direction()
	)

	if facing == Vector2.ZERO:
		return false

	if required == Vector2.ZERO:
		return false

	return facing == required


# ===== Closest Block =====

func is_closest_facing_block() -> bool:
	if player == null:
		return false

	var player_pos: Vector2 = (
		get_player_visual_position()
	)

	var my_pos: Vector2 = (
		get_block_visual_position()
	)

	var my_distance: float = (
		player_pos.distance_to(my_pos)
	)


	for block in get_tree().get_nodes_in_group(
		"pushable_blocks"
	):

		if block == self:
			continue

		if not block is Node2D:
			continue

		var other_block: Node2D = (
			block as Node2D
		)


		var other_locked = (
			other_block.get("is_locked")
		)

		if (
			other_locked != null
			and bool(other_locked)
		):
			continue


		var other_player = (
			other_block.get("player")
		)

		if other_player != player:
			continue


		var other_interactable = (
			other_block.get("interactable")
		)

		if other_interactable == null:
			continue

		if not bool(other_interactable):
			continue


		if not other_block.has_method(
			"is_player_facing_this_block"
		):
			continue


		if not other_block.has_method(
			"get_block_visual_position"
		):
			continue


		var other_facing = (
			other_block.call(
				"is_player_facing_this_block"
			)
		)

		if not bool(other_facing):
			continue


		var other_position_result = (
			other_block.call(
				"get_block_visual_position"
			)
		)

		if not other_position_result is Vector2:
			continue


		var other_position: Vector2 = (
			other_position_result
		)

		var other_distance: float = (
			player_pos.distance_to(
				other_position
			)
		)


		if other_distance < my_distance:
			return false


	return true


# ===== Input =====

func _unhandled_input(
	event: InputEvent
) -> void:

	if is_locked or not interactable:
		return

	if not event.is_action_pressed(
		interact_action
	):
		return

	if _input_lock:
		return


	# Press E again to release the current block.
	if _attached_block != null:

		if (
			_attached_block == self
			and is_attached
		):

			_input_lock = true

			detach()

			get_viewport().set_input_as_handled()

			call_deferred(
				"_release_input_lock"
			)

		return


	if player == null:
		return

	if not is_player_facing_this_block():
		return

	if not is_closest_facing_block():
		return


	_input_lock = true

	attach()

	get_viewport().set_input_as_handled()

	call_deferred(
		"_release_input_lock"
	)


func _release_input_lock() -> void:
	_input_lock = false


# ===== Attach =====

func attach() -> void:
	if is_locked or not interactable:
		return

	if player == null:
		return


	if (
		_attached_block != null
		and _attached_block != self
	):
		return


	if not is_player_facing_this_block():
		return

	if not is_closest_facing_block():
		return


	# Set push direction from player position.
	push_direction = (
		get_player_side_direction()
	)

	if push_direction == Vector2.ZERO:
		return


	is_attached = true
	_attached_block = self


	offset_from_player = (
		global_position
		- player.global_position
	)


	# Hide prompts from other blocks.
	for block in get_tree().get_nodes_in_group(
		"pushable_blocks"
	):

		if block == self:
			continue

		if block.has_method("hide_prompt"):
			block.call("hide_prompt")


	# Stop normal player movement.
	if player.has_method("set_can_move"):

		player.call(
			"set_can_move",
			false
		)


	velocity = Vector2.ZERO


	if prompt_label:

		prompt_label.text = (
			get_push_instruction()
		)

		prompt_label.visible = true


# ===== Detach =====

func detach() -> void:
	if _attached_block == self:
		_attached_block = null

	is_attached = false


	if player != null:

		if player.has_method(
			"set_external_direction"
		):

			player.call(
				"set_external_direction",
				Vector2.ZERO
			)


		if player.has_method(
			"set_can_move"
		):

			player.call(
				"set_can_move",
				true
			)


	push_direction = Vector2.ZERO
	offset_from_player = Vector2.ZERO


	hide_prompt()


	call_deferred(
		"refresh_all_prompts"
	)


# ===== Snap Detection =====

func find_nearby_snap_target() -> int:
	if not snap_enabled:
		return -1


	var closest_index: int = -1
	var closest_distance: float = INF


	for i: int in range(
		MAIN_SNAP_TARGETS.size()
	):

		# Skip targets that are already completed.
		if snapped_slots[i]:
			continue


		var target: Vector2 = (
			MAIN_SNAP_TARGETS[i]
		)


		var distance: float = (
			position.distance_to(
				target
			)
		)


		if (
			distance <= snap_distance
			and distance < closest_distance
		):

			closest_distance = distance
			closest_index = i


	return closest_index


func check_snap_target() -> bool:
	if is_locked:
		return true

	if not snap_enabled:
		return false


	# Only main blocks use snap targets.
	if linked_blocks.is_empty():
		return false


	var snap_index: int = (
		find_nearby_snap_target()
	)


	if snap_index == -1:
		return false


	var main_target: Vector2 = (
		MAIN_SNAP_TARGETS[
			snap_index
		]
	)


	var linked_target: Vector2 = (
		LINKED_SNAP_TARGETS[
			snap_index
		]
	)


	# Release player before snapping.
	release_player_for_lock()


	# Snap the main block.
	position = main_target


	# Lock the main block.
	lock_block()


	# Snap the linked block.
	for path: NodePath in linked_blocks:

		var linked_node: Node = (
			get_node_or_null(path)
		)


		if linked_node == null:
			continue


		if linked_node == self:
			continue


		if not linked_node is CharacterBody2D:
			continue


		if linked_node.has_method(
			"force_snap_and_lock"
		):

			linked_node.call(
				"force_snap_and_lock",
				linked_target
			)


	# Record this completed target.
	if not snapped_slots[snap_index]:

		snapped_slots[snap_index] = true

		snapped_pair_count += 1


		print(
			"Snapped blocks: ",
			snapped_pair_count,
			"/3"
		)


	return true


# ===== Linked Snap =====

func force_snap_and_lock(
	target: Vector2
) -> void:

	if is_locked:
		return


	release_player_for_lock()


	position = target


	lock_block()


# ===== Lock Block =====

func release_player_for_lock() -> void:
	if _attached_block == self:
		_attached_block = null


	is_attached = false


	if player != null:

		if player.has_method(
			"set_external_direction"
		):

			player.call(
				"set_external_direction",
				Vector2.ZERO
			)


		if player.has_method(
			"set_can_move"
		):

			player.call(
				"set_can_move",
				true
			)


	push_direction = Vector2.ZERO
	offset_from_player = Vector2.ZERO


	hide_prompt()


func lock_block() -> void:
	is_locked = true
	interactable = false

	velocity = Vector2.ZERO

	push_direction = Vector2.ZERO
	offset_from_player = Vector2.ZERO


	# Disable interaction after snapping.
	if detection_area != null:

		detection_area.set_deferred(
			"monitoring",
			false
		)


	hide_prompt()


# ===== Prompt =====

func get_push_instruction() -> String:
	if push_direction == Vector2.RIGHT:
		return "D to push | E to release"

	if push_direction == Vector2.LEFT:
		return "A to push | E to release"

	if push_direction == Vector2.DOWN:
		return "S to push | E to release"

	if push_direction == Vector2.UP:
		return "W to push | E to release"

	return "E to release"


func show_prompt() -> void:
	if is_locked or not interactable:
		return

	if prompt_label == null:
		return


	if is_attached:

		prompt_label.text = (
			get_push_instruction()
		)

	else:

		prompt_label.text = (
			"Press E to push block"
		)


	prompt_label.visible = true


func hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false


func refresh_prompt() -> void:
	if is_locked or not interactable:

		hide_prompt()
		return


	# Only attached block shows a prompt while pushing.
	if _attached_block != null:

		if (
			_attached_block == self
			and is_attached
		):

			if prompt_label:

				prompt_label.text = (
					get_push_instruction()
				)

				prompt_label.visible = true

		else:

			hide_prompt()


		return


	if player == null:

		hide_prompt()
		return


	# Player must face the block.
	if not is_player_facing_this_block():

		hide_prompt()
		return


	if not is_closest_facing_block():

		hide_prompt()
		return


	show_prompt()


func refresh_all_prompts() -> void:
	for block in get_tree().get_nodes_in_group(
		"pushable_blocks"
	):

		if block.has_method(
			"refresh_prompt"
		):

			block.call(
				"refresh_prompt"
			)


# ===== Block Movement =====

func _physics_process(
	delta: float
) -> void:

	if is_locked:

		velocity = Vector2.ZERO
		hide_prompt()
		return


	# Check if the player is still inside the area.
	if (
		interactable
		and not is_attached
		and player != null
	):

		var still_inside: bool = false


		if detection_area != null:

			var bodies = (
				detection_area
				.get_overlapping_bodies()
			)


			for body in bodies:

				if body == player:

					still_inside = true
					break


		if not still_inside:

			player = null
			hide_prompt()


	if not is_attached:

		refresh_prompt()


	# Only the attached block can move.
	if not (
		interactable
		and is_attached
		and player != null
		and _attached_block == self
	):

		return


	var input_dir: Vector2 = Vector2.ZERO


	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0

	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0


	# Only allow forward pushing.
	var projection: float = (
		input_dir.dot(
			push_direction
		)
	)


	input_dir = (
		push_direction
		* max(
			0.0,
			projection
		)
	)


	if input_dir == Vector2.ZERO:

		if player.has_method(
			"set_external_direction"
		):

			player.call(
				"set_external_direction",
				Vector2.ZERO
			)

		return


	var effective_speed: float = (
		move_speed
	)


	var player_speed = (
		player.get("speed")
	)


	if player_speed != null:

		if player_speed is float:

			effective_speed = (
				player_speed
			)

		elif player_speed is int:

			effective_speed = float(
				player_speed
			)


	var movement: Vector2 = (
		input_dir.normalized()
		* effective_speed
		* delta
	)


	var new_pos: Vector2 = (
		global_position
		+ movement
	)


	new_pos.x = clamp(
		new_pos.x,
		min_x,
		max_x
	)


	new_pos.y = clamp(
		new_pos.y,
		min_y,
		max_y
	)


	var desired_movement: Vector2 = (
		new_pos
		- global_position
	)


	if desired_movement == Vector2.ZERO:

		if player.has_method(
			"set_external_direction"
		):

			player.call(
				"set_external_direction",
				Vector2.ZERO
			)

		return


	# Update player push animation.
	if player.has_method(
		"set_external_direction"
	):

		player.call(
			"set_external_direction",
			push_direction
		)


	var old_position: Vector2 = (
		global_position
	)


	move_and_collide(
		desired_movement
	)


	var actual_movement: Vector2 = (
		global_position
		- old_position
	)


	# Keep player beside the block.
	if actual_movement != Vector2.ZERO:

		player.global_position = (
			global_position
			- offset_from_player
		)

	else:

		if player.has_method(
			"set_external_direction"
		):

			player.call(
				"set_external_direction",
				Vector2.ZERO
			)


	# Check the three snap targets.
	if check_snap_target():
		return


	# Move the linked block.
	if (
		linked_blocks.size() > 0
		and actual_movement != Vector2.ZERO
	):

		sync_linked_blocks(
			actual_movement
		)


# ===== Linked Movement =====

func sync_linked_blocks(
	movement: Vector2
) -> void:

	if _is_syncing:
		return


	_is_syncing = true


	var mirrored: Vector2 = movement


	if mirror_x:
		mirrored.x = -mirrored.x


	if mirror_y:
		mirrored.y = -mirrored.y


	for path: NodePath in linked_blocks:

		var node: Node = (
			get_node_or_null(path)
		)


		if node == null:
			continue


		if node == self:
			continue


		if not node is CharacterBody2D:
			continue


		if node.has_method(
			"apply_external_movement"
		):

			node.call(
				"apply_external_movement",
				mirrored
			)


	_is_syncing = false


func apply_external_movement(
	movement: Vector2
) -> void:

	if is_locked:
		return


	if _is_applying_external:
		return


	_is_applying_external = true


	move_and_collide(
		movement
	)


	_is_applying_external = false
