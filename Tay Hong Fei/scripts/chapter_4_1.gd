extends Node2D


# ===== Dialogue =====

@export var speaker_name: String = "Kunkun"
@export var portrait: Texture2D

@export var intro_lines: Array[DialogueLine] = []:
	set(value):
		intro_lines = DialogueLine.fill_blanks(value)


# ===== BGM =====

@export var bgm_volume_db: float = -5.0


# ===== Nodes =====

@onready var bgm: AudioStreamPlayer = (
	$BGM
)


# ===== Initialization =====

func _ready() -> void:
	# Start scene BGM.
	bgm.volume_db = bgm_volume_db

	if not bgm.playing:
		bgm.play()

	# Wait until the scene is ready.
	await get_tree().process_frame

	if intro_lines.is_empty():
		return

	Dialogue.show_lines(
		intro_lines,
		portrait,
		speaker_name
	)
