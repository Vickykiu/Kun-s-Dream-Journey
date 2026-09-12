@tool
extends CanvasLayer


@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

@export var sheet_music_lines: Array[DialogueLine] = []:
	set(value):
		sheet_music_lines = DialogueLine.fill_blanks(value)

@export var book_lines: Array[DialogueLine] = []:
	set(value):
		book_lines = DialogueLine.fill_blanks(value)

@export var metronome_lines: Array[DialogueLine] = []:
	set(value):
		metronome_lines = DialogueLine.fill_blanks(value)

@export var pliers_pickup_lines: Array[DialogueLine] = []:
	set(value):
		pliers_pickup_lines = DialogueLine.fill_blanks(value)

@export var pliers_closeup_texture: Texture2D


@onready var drawer_button: TextureButton = $DrawerButton
@onready var open_drawer_image: TextureRect = $OpenDrawerImage
@onready var pliers_button: TextureButton = $PliersButton
@onready var drawer_background: ColorRect = $DrawerBackground

@onready var close_hint: Label = $CloseHint
@onready var close_sound: AudioStreamPlayer = $CloseSound
@onready var drawer_open_sound: AudioStreamPlayer = $DrawerOpenSound


var drawer_opened: bool = false
var pliers_taken: bool = false
var can_close: bool = false
var is_closing: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = false

	pliers_taken = GameState.has_item("wire_cutters")

	open_drawer_image.visible = false
	pliers_button.visible = false
	drawer_background.visible = false
	drawer_button.visible = not pliers_taken

	# 防止打开 Desk 的那次 E 同时把它关闭。
	await get_tree().process_frame
	can_close = true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	close_hint.visible = (
		can_close
		and not is_closing
		and not Dialogue.is_active()
		and not ItemView.is_active()
	)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.keycode != KEY_E or not event.pressed or event.echo:
		return

	if (
		not can_close
		or is_closing
		or Dialogue.is_active()
		or ItemView.is_active()
	):
		return

	get_viewport().set_input_as_handled()
	close_ui()


# =========================
# Sheet music
# =========================

func _on_sheet_music_button_pressed() -> void:
	if Dialogue.is_active() or sheet_music_lines.is_empty():
		return

	Dialogue.show_lines(
		sheet_music_lines,
		portrait,
		speaker_name
	)


# =========================
# Book
# =========================

func _on_book_button_pressed() -> void:
	if Dialogue.is_active() or book_lines.is_empty():
		return

	Dialogue.show_lines(
		book_lines,
		portrait,
		speaker_name
	)


# =========================
# Metronome
# =========================

func _on_metronome_button_pressed() -> void:
	if Dialogue.is_active() or metronome_lines.is_empty():
		return

	Dialogue.show_lines(
		metronome_lines,
		portrait,
		speaker_name
	)


# =========================
# Open drawer
# =========================

func _on_drawer_button_pressed() -> void:
	if Dialogue.is_active() or drawer_opened:
		return

	drawer_opened = true

	if drawer_open_sound.stream:
		drawer_open_sound.play()

	drawer_background.visible = true
	open_drawer_image.visible = true
	pliers_button.visible = true
	drawer_button.visible = false


# =========================
# Pick up pliers
# =========================

func _on_pliers_button_pressed() -> void:
	if Dialogue.is_active() or ItemView.is_active():
		return

	if pliers_taken or GameState.has_item("wire_cutters"):
		return

	pliers_taken = true
	pliers_button.visible = false

	if pliers_closeup_texture:
		await ItemView.show_item(
			pliers_closeup_texture
		)

	drawer_background.visible = false
	open_drawer_image.visible = false
	pliers_button.visible = false
	drawer_button.visible = false

	GameState.add_item("wire_cutters")

	if not pliers_pickup_lines.is_empty():
		Dialogue.show_lines(
			pliers_pickup_lines,
			portrait,
			speaker_name
		)
		await Dialogue.finished


# =========================
# Close Desk UI
# =========================

func close_ui() -> void:
	is_closing = true
	close_hint.visible = false

	if close_sound.stream:
		close_sound.play()
		await close_sound.finished

	queue_free()
