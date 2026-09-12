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
@onready var close_hint: Label = $CloseHint
@onready var close_sound: AudioStreamPlayer = $CloseSound


var can_close: bool = false
var is_entering_vent: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = false
	close_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().process_frame

	if not vent_lines.is_empty():
		Dialogue.show_lines(
			vent_lines,
			portrait,
			speaker_name
		)
		await Dialogue.finished

	# 最后一次推进对白的 E 不会同时关闭窗口。
	await get_tree().process_frame
	can_close = true
	close_hint.visible = true


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if (
		not can_close
		or is_closing
		or is_entering_vent
		or Dialogue.is_active()
	):
		return

	get_viewport().set_input_as_handled()
	close_ui()


func close_ui() -> void:
	is_closing = true
	can_close = false
	close_hint.visible = false
	enter_vent_button.disabled = true

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()


func _on_enter_vent_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if is_entering_vent or is_closing:
		return

	is_entering_vent = true
	can_close = false
	close_hint.visible = false
	enter_vent_button.disabled = true

	if enter_vent_sound.stream:
		enter_vent_sound.play()
		await enter_vent_sound.finished

	vent_entered.emit()
	queue_free()
