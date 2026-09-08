@tool
extends Area2D


# ===== Dialogue =====

@export var lines: Array[DialogueLine] = []:
	set(value):
		lines = DialogueLine.fill_blanks(value)

@export var lines_after: Array[DialogueLine] = []:
	set(value):
		lines_after = DialogueLine.fill_blanks(value)

@export var speaker_name: String = ""
@export var portrait: Texture2D


# ===== State =====

var player_inside: bool = false
var looked_at: bool = false
var interacting: bool = false


# ===== Initialization =====

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)


# ===== Update =====

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if PushableBlock.get_snapped_count() >= 3:
		player_inside = false

		if monitoring:
			set_deferred(
				"monitoring",
				false
			)


# ===== Player Detection =====

func _on_body_entered(
	body: Node2D
) -> void:
	if body.name != "Player":
		return

	if PushableBlock.get_snapped_count() >= 3:
		return

	player_inside = true

	call_deferred(
		"_start_interaction"
	)


func _on_body_exited(
	body: Node2D
) -> void:
	if body.name != "Player":
		return

	player_inside = false


# ===== Auto Interaction =====

func _start_interaction() -> void:
	if not player_inside:
		return

	if interacting:
		return

	if PushableBlock.get_snapped_count() >= 3:
		return

	while (
		player_inside
		and (
			ItemView.is_active()
			or Dialogue.is_active()
			or Inventory.is_open()
		)
	):
		await get_tree().process_frame

	if not player_inside:
		return

	if PushableBlock.get_snapped_count() >= 3:
		return

	await show_dialogue()


# ===== Dialogue =====

func show_dialogue() -> void:
	if interacting:
		return

	if PushableBlock.get_snapped_count() >= 3:
		return

	interacting = true

	var pages: Array = []

	if not looked_at or lines_after.is_empty():
		pages.append_array(
			lines
		)

	else:
		pages.append_array(
			lines_after
		)

	looked_at = true

	if not pages.is_empty():
		Dialogue.show_lines(
			pages,
			portrait,
			speaker_name
		)

		await Dialogue.finished

	interacting = false
