extends CanvasLayer

const CABINET_OPEN_TEXTURE = preload(
	"res://Lew Jia Jia/assets/Cabinet_Open.png"
)

@onready var cabinet_image: TextureRect = $CabinetImage
@onready var open_button: TextureButton = $OpenButton

var is_open: bool = false


func _on_open_button_pressed() -> void:
	if is_open:
		return

	is_open = true
	cabinet_image.texture = CABINET_OPEN_TEXTURE
	open_button.visible = false


func _on_close_button_pressed() -> void:
	queue_free()
