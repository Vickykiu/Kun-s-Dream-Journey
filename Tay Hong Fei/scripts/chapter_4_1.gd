extends Node2D


# ===== Dialogue =====

@export var speaker_name: String = "Kunkun"

@export var portrait: Texture2D

@export var intro_lines: Array[DialogueLine] = []:
	set(value):
		intro_lines = DialogueLine.fill_blanks(
			value
		)


# ===== BGM =====

@export var bgm_volume_db: float = 0.0


# ===== Nodes =====

@onready var bgm: AudioStreamPlayer = (
	$BGM
)


# ===== Enter Tree =====

func _enter_tree() -> void:
	# Reset before child nodes become ready.
	if GameState.new_game_started:
		reset_chapter_4()

		GameState.new_game_started = false


# ===== Initialization =====

func _ready() -> void:
	# Set BGM volume.
	bgm.volume_db = bgm_volume_db

	# Enable MP3 loop.
	if bgm.stream is AudioStreamMP3:
		bgm.stream.loop = true
		bgm.stream.loop_offset = 0.0

	# Start scene BGM.
	if not bgm.playing:
		bgm.play()

	# Wait until scene is ready.
	await get_tree().process_frame

	if intro_lines.is_empty():
		return

	Dialogue.show_lines(
		intro_lines,
		portrait,
		speaker_name
	)


# ===== Reset Chapter 4 =====

func reset_chapter_4() -> void:
	# Reset push block puzzle.
	PushableBlock.reset_snap_progress()

	# Reset completed crystals.
	MinesweeperState.completed_crystals.clear()

	# Reset Minesweeper progress.
	MinesweeperState.puzzle_progress.clear()

	# Reset mystery person.
	MinesweeperState.mystery_intro_played = false

	# Reset reject hint.
	MinesweeperState.reject_hint_pending = false

	# Reset return scene.
	MinesweeperState.return_scene_path = ""

	# Reset return position.
	MinesweeperState.return_position = (
		Vector2.ZERO
	)

	MinesweeperState.has_return_position = false

	# Reset active crystal.
	MinesweeperState.active_crystal_id = ""

	# Remove old ending BGM.
	var ending_bgm: Node = (
		get_tree().root.get_node_or_null(
			"EndingBGM"
		)
	)

	if ending_bgm != null:
		ending_bgm.queue_free()


# ===== Stop BGM =====

func stop_bgm() -> void:
	if bgm.playing:
		bgm.stop()
