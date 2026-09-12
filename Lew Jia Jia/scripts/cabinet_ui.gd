@tool
extends CanvasLayer


const CABINET_OPEN_TEXTURE = preload(
	"res://Lew Jia Jia/assets/Cabinet_Open.png"
)


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var cabinet_lines: Array[DialogueLine] = []:
	set(value):
		cabinet_lines = DialogueLine.fill_blanks(value)


@onready var cabinet_image: TextureRect = $CabinetImage
@onready var open_button: TextureButton = $OpenButton
@onready var close_hint: Label = $CloseHint
@onready var close_sound: AudioStreamPlayer = $CloseSound


var is_open: bool = false
var can_close: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = false

	# 避免打开 Cabinet 的 E 同时关闭它。
	await get_tree().process_frame
	can_close = true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = (
		can_close
		and not is_closing
		and not Dialogue.is_active()
	)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if not can_close or is_closing or Dialogue.is_active():
		return

	get_viewport().set_input_as_handled()
	close_ui()


func _on_open_button_pressed() -> void:
	if is_open or Dialogue.is_active():
		return

	is_open = true
	cabinet_image.texture = CABINET_OPEN_TEXTURE
	open_button.visible = false

	if not cabinet_lines.is_empty():
		Dialogue.show_lines(
			cabinet_lines,
			portrait,
			speaker_name
		)


func close_ui() -> void:
	is_closing = true
	close_hint.visible = false

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
