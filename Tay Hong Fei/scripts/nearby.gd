@tool
extends Area2D


# ===== Signals =====

signal interacted(node)
signal finished(node)


# ===== Dialogue =====

@export var lines: Array[DialogueLine] = []:
	set(value):
		lines = DialogueLine.fill_blanks(value)

@export var lines_after: Array[DialogueLine] = []:
	set(value):
		lines_after = DialogueLine.fill_blanks(value)

@export var speaker_name: String = ""
@export var portrait: Texture2D


# ===== Item =====

@export var item_id: String = ""
@export var closeup_texture: Texture2D
@export var back_texture: Texture2D
@export var item_node: NodePath

@export var pickup_lines: Array[DialogueLine] = []:
	set(value):
		pickup_lines = DialogueLine.fill_blanks(value)

@export var announce_pickup: bool = true


# ===== Flags =====

@export var flag_id: String = ""
@export var requires_flag: String = ""


# ===== Behaviour =====

@export var one_shot: bool = false
@export var hide_after: bool = false


# ===== State =====

var _player_inside: bool = false
var _looked_at: bool = false
var _interacting: bool = false


# ===== Initialization =====

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if item_id != "" and GameState.has_item(item_id):
		_hide_item_node()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# ===== Player Detection =====

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	_player_inside = true

	if _is_used_up():
		return

	if _is_locked():
		return

	call_deferred("_start_interaction")


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return

	_player_inside = false


# ===== Auto Interaction =====

func _start_interaction() -> void:
	if not _player_inside:
		return

	if _interacting:
		return

	if _is_used_up():
		return

	if _is_locked():
		return

	# Wait until other UI is closed.
	while (
		_player_inside
		and (
			ItemView.is_active()
			or Dialogue.is_active()
			or Inventory.is_open()
		)
	):
		await get_tree().process_frame

	if not _player_inside:
		return

	if _interacting:
		return

	await _interact()


# ===== Interaction =====

func _interact() -> void:
	if _interacting:
		return

	_interacting = true

	var first_time: bool = not _was_looked_at()

	_looked_at = true

	if flag_id != "":
		GameState.set_flag(flag_id)

	var pages: Array = []

	if first_time or lines_after.is_empty():
		pages.append_array(lines)
	else:
		pages.append_array(lines_after)

	var handing_over: bool = (
		first_time
		and item_id != ""
	)

	interacted.emit(self)


	# Show dialogue.
	if not pages.is_empty():
		Dialogue.show_lines(
			pages,
			portrait,
			speaker_name
		)

		await Dialogue.finished


	# Show and collect the item.
	if handing_over:
		await ItemView.show_item(
			_item_texture(),
			back_texture
		)

		GameState.add_item(item_id)

		_hide_item_node()

		var after: Array = []

		after.append_array(
			pickup_lines
		)

		if announce_pickup:
			after.append(
				"(Added to inventory: %s)"
				% ItemDB.get_item(item_id)["name"]
			)

		if not after.is_empty():
			Dialogue.show_lines(
				after,
				portrait,
				speaker_name
			)

			await Dialogue.finished


	finished.emit(self)

	_interacting = false


	if hide_after:
		hide()

		set_deferred(
			"monitoring",
			false
		)


# ===== Item Helpers =====

func _hide_item_node() -> void:
	if item_node.is_empty():
		return

	var node: Node = get_node_or_null(
		item_node
	)

	if node is CanvasItem:
		node.hide()


func _item_texture() -> Texture2D:
	if closeup_texture:
		return closeup_texture

	var icon_path: String = (
		ItemDB
		.get_item(item_id)
		.get("icon", "")
	)

	if (
		icon_path != ""
		and ResourceLoader.exists(icon_path)
	):
		return load(icon_path)

	return null


# ===== Conditions =====

func _is_locked() -> bool:
	return (
		requires_flag != ""
		and not GameState.has_flag(
			requires_flag
		)
	)


func _was_looked_at() -> bool:
	if flag_id != "":
		return GameState.has_flag(
			flag_id
		)

	return _looked_at


func _is_used_up() -> bool:
	return (
		one_shot
		and _was_looked_at()
	)
