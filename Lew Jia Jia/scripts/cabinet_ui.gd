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
@onready var close_button: BaseButton = $CloseButton
@onready var close_sound: AudioStreamPlayer = $CloseSound


var is_open: bool = false
var is_closing: bool = false


func _on_open_button_pressed() -> void:
	if is_open:
		return

	if Dialogue.is_active():
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


func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if is_closing:
		return

	is_closing = true
	close_button.disabled = true

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
