@tool
extends CanvasLayer


signal vent_entered


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var vent_lines: Array[DialogueLine] = []:
	set(value):
		vent_lines = DialogueLine.fill_blanks(value)


@onready var enter_vent_button: BaseButton = $EnterVentButton
@onready var enter_vent_sound: AudioStreamPlayer = $EnterVentSound

@onready var close_button: BaseButton = $CloseButton
@onready var close_sound: AudioStreamPlayer = $CloseSound


var is_entering_vent: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	await get_tree().process_frame

	if not vent_lines.is_empty():
		Dialogue.show_lines(
			vent_lines,
			portrait,
			speaker_name
		)

		await Dialogue.finished


# =========================
# Close Vent UI
# =========================

func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if is_closing or is_entering_vent:
		return

	is_closing = true
	close_button.disabled = true
	enter_vent_button.disabled = true

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()


# =========================
# Enter Vent
# =========================

func _on_enter_vent_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if is_entering_vent or is_closing:
		return

	is_entering_vent = true
	enter_vent_button.disabled = true
	close_button.disabled = true

	# Play the sound before changing scene.
	if enter_vent_sound.stream:
		enter_vent_sound.play()
		await enter_vent_sound.finished

	vent_entered.emit()
	queue_free()
