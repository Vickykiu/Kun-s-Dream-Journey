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


# =========================
# Drawer references
# =========================
@onready var drawer_button: TextureButton = $DrawerButton
@onready var open_drawer_image: TextureRect = $OpenDrawerImage
@onready var pliers_button: TextureButton = $PliersButton
@onready var drawer_background: ColorRect = $DrawerBackground

var drawer_opened: bool = false
var pliers_taken: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	pliers_taken = GameState.has_item("wire_cutters")

	open_drawer_image.visible = false
	pliers_button.visible = false
	drawer_background.visible = false

	# Already collected: drawer can no longer be opened
	drawer_button.visible = not pliers_taken


# =========================
# Sheet music
# =========================
func _on_sheet_music_button_pressed() -> void:
	if Dialogue.is_active():
		return

	if sheet_music_lines.is_empty():
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
	if Dialogue.is_active():
		return

	if book_lines.is_empty():
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
	if Dialogue.is_active():
		return

	if metronome_lines.is_empty():
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
	if Dialogue.is_active():
		return

	if drawer_opened:
		return

	drawer_opened = true

	drawer_background.visible = true
	open_drawer_image.visible = true
	pliers_button.visible = true
	drawer_button.visible = false


# =========================
# Pliers — implement next
# =========================
func _on_pliers_button_pressed() -> void:
	if Dialogue.is_active() or ItemView.is_active():
		return

	if pliers_taken:
		return

	if GameState.has_item("wire_cutters"):
		return

	pliers_taken = true
	pliers_button.visible = false

	# Show enlarged pliers image
	if pliers_closeup_texture:
		await ItemView.show_item(pliers_closeup_texture)

	# Hide the drawer before showing dialogue
	drawer_background.visible = false
	open_drawer_image.visible = false
	pliers_button.visible = false
	drawer_button.visible = false

	# Add the tool to inventory
	GameState.add_item("wire_cutters")

	# Dialogue now appears over the normal DeskUI
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
func _on_close_button_pressed() -> void:
	if Dialogue.is_active():
		return

	queue_free()

	
	
