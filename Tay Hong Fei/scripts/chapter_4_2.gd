extends Node2D


# ===== BGM =====

@export var bgm_volume_db: float = 0.0


# ===== Nodes =====

@onready var bgm: AudioStreamPlayer = (
	$BGM
)


# ===== Initialization =====

func _ready() -> void:
	# Set BGM volume.
	bgm.volume_db = bgm_volume_db

	# Enable MP3 loop.
	if bgm.stream is AudioStreamMP3:
		bgm.stream.loop = true
		bgm.stream.loop_offset = 0.0

	# Start BGM.
	if not bgm.playing:
		bgm.play()


# ===== Stop BGM =====

func stop_bgm() -> void:
	if bgm.playing:
		bgm.stop()


# ===== Process =====

func _process(_delta: float) -> void:
	pass
