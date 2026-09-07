extends CanvasLayer

signal finished
@export var kunkun_cutout: ShaderMaterial

@onready var overlay: Control = $Overlay
@onready var portrait: TextureRect = %DialoguePortrait
@onready var speaker_label: Label = %DialogueSpeaker
@onready var emotion_label: Label = %DialogueEmotion
@onready var badge: Control = %DialogueEmoji
@onready var text_label: RichTextLabel = %DialogueText
@onready var page_label: Label = %DialoguePage
@onready var next_button: Button = %DialogueNext
@onready var dialogue_music: AudioStreamPlayer = $DialogueMusicPlayer

var active := false
var pages: Array[Dictionary] = []
var page_index := 0
var revealed_characters := 0.0
var previous_focus: Control


func _ready() -> void:
	add_to_group("chapter_dialogue")
	overlay.hide()
	# Each dialogue instance owns its loop setting. Menu/rhythm tracks are separate.
	if dialogue_music.stream is AudioStreamMP3:
		var dialogue_stream := dialogue_music.stream.duplicate() as AudioStreamMP3
		dialogue_stream.loop = true
		dialogue_music.stream = dialogue_stream
	%DialogueNext.pressed.connect(advance)
	%DialogueSkip.pressed.connect(close)


func start(conversation: Array) -> void:
	if conversation.is_empty() or active:
		return
	pages.assign(conversation)
	page_index = 0
	previous_focus = get_viewport().gui_get_focus_owner()
	active = true
	overlay.show()
	# The Music bus means existing Master and Music sliders control this track.
	dialogue_music.play()
	var exit_layer := get_node_or_null("/root/ChapterEscape")
	if exit_layer:
		exit_layer.hide()
	_show_page()
	next_button.grab_focus()


func _process(delta: float) -> void:
	if not active or text_label.visible_characters < 0:
		return
	revealed_characters += delta * 48.0
	text_label.visible_characters = int(revealed_characters)
	if text_label.visible_characters >= text_label.get_total_character_count():
		text_label.visible_characters = -1


func _input(event: InputEvent) -> void:
	if not active or not is_inside_tree():
		return
	var dialogue_viewport := get_viewport()
	if event is InputEventKey and event.echo:
		dialogue_viewport.set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		# Consume input before finished can remove this scene from the tree.
		dialogue_viewport.set_input_as_handled()
		close()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		# Advancing the final page can trigger that same scene transition.
		dialogue_viewport.set_input_as_handled()
		# Tab can focus Skip, and Enter should activate that visible choice.
		if dialogue_viewport.gui_get_focus_owner() == %DialogueSkip:
			close()
		else:
			advance()


func advance() -> void:
	if not active:
		return
	if text_label.visible_characters >= 0:
		text_label.visible_characters = -1
		return
	page_index += 1
	if page_index >= pages.size():
		close()
	else:
		_show_page()


func _show_page() -> void:
	var page: Dictionary = pages[page_index]
	speaker_label.text = str(page.get("speaker", "Kunkun"))
	portrait.texture = page.get("portrait") as Texture2D
	portrait.material = kunkun_cutout if portrait.texture != null and \
		portrait.texture.resource_path.contains("/kunkun_") else null
	badge.set("emotion", str(page.get("emotion", "calm")))
	emotion_label.text = str(page.get("mood", "Listening"))
	text_label.text = str(page.get("text", ""))
	revealed_characters = 0.0
	text_label.visible_characters = 0
	page_label.text = "%02d / %02d" % [page_index + 1, pages.size()]
	next_button.text = "CONTINUE" if page_index == pages.size() - 1 else "NEXT"
	MusicManager.play_sfx(&"dialogue")


func close() -> void:
	if not active:
		return
	active = false
	overlay.hide()
	# Stop before emitting finished so audio never follows into the next scene.
	dialogue_music.stop()
	_restore_exit_layer()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	finished.emit()


func _restore_exit_layer() -> void:
	var exit_layer := get_node_or_null("/root/ChapterEscape")
	if exit_layer:
		exit_layer.show()


func _exit_tree() -> void:
	if active:
		dialogue_music.stop()
		_restore_exit_layer()
