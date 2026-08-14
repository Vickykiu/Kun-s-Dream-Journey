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

var is_open: bool = false


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

	queue_free()
