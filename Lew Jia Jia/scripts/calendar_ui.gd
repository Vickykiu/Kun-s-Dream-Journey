@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var calendar_lines: Array[DialogueLine] = []:
	set(value):
		calendar_lines = DialogueLine.fill_blanks(value)


@onready var close_sound: AudioStreamPlayer = $CloseSound

var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	await get_tree().process_frame

	if not calendar_lines.is_empty():
		Dialogue.show_lines(
			calendar_lines,
			portrait,
			speaker_name
		)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	# 对话还在进行时，E 用来继续对话。
	if Dialogue.is_active() or is_closing:
		return

	# 对话结束后，再按 E 关闭 Calendar。
	get_viewport().set_input_as_handled()
	close_ui()


func close_ui() -> void:
	is_closing = true

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
