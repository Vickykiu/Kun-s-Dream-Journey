@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var clock_lines: Array[DialogueLine] = []:
	set(value):
		clock_lines = DialogueLine.fill_blanks(value)


@onready var close_sound: AudioStreamPlayer = $CloseSound
@onready var close_hint: Label = $CloseHint

var can_close: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = false
	await get_tree().process_frame

	if not clock_lines.is_empty():
		Dialogue.show_lines(
			clock_lines,
			portrait,
			speaker_name
		)
		await Dialogue.finished

	# 避免最后一句对话的 E 同时把窗口关闭。
	await get_tree().process_frame
	can_close = true
	close_hint.visible = true


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if not can_close or is_closing or Dialogue.is_active():
		return

	get_viewport().set_input_as_handled()
	close_ui()


func close_ui() -> void:
	is_closing = true
	close_hint.visible = false

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
