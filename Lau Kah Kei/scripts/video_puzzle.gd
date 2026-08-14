extends CanvasLayer

# The monitor room puzzle. Three clips off the desktop, out of order, sitting
# on a timeline. Drag one onto another to swap them; get all three in the
# order they were recorded and the tape plays: morning, afternoon, night,
# and then the frame it freezes on.
#
# The only clue is the timestamp burned into each clip, so the puzzle is
# really "read the corner of the picture" — which is the point. Nothing here
# is random except the shuffle.
#
# Opened from the computer: wire the Interactable's `finished` signal to
# open(). It hands out the evidence itself once the tape has played, the
# same way everything else does — close-up first, then into the bag.

signal solved

@export_group("Clips, in the order they were recorded")
@export var clip_1: Texture2D     # morning
@export var clip_2: Texture2D     # afternoon
@export var clip_3: Texture2D     # night

# The frame the tape freezes on once the order is right.
@export var freeze_frame: Texture2D
@export_multiline var freeze_subtitle: String = ""

@export_group("Words on screen")
@export var title_text: String = "PLAYBACK ORDER"
@export var hint_text: String = "Drag a clip onto another to swap them"
@export var wrong_text: String = "Out of order. Check the timestamps."

@export_group("What it hands over")
# What Kunkun says once the tape has finished playing.
@export var found_lines: Array[DialogueLine] = []:
	set(value):
		found_lines = DialogueLine.fill_blanks(value)

# An id from ItemDB, handed over after `found_lines` — held up on screen
# first, exactly like a pickup off the floor.
@export var item_id: String = ""

# What he says with it in his hand.
@export var reaction_lines: Array[DialogueLine] = []:
	set(value):
		reaction_lines = DialogueLine.fill_blanks(value)

@export var speaker_name: String = "Kun"
@export var portrait: Texture2D

# Remembered in GameState so the puzzle stays solved after a scene change.
@export var flag_id: String = "a02_video_solved"

const SLOT_SIZE := Vector2(420, 236)     # 16:9
const SLOT_GAP := 60.0
const SLOT_Y := 470.0

var _root: Control
var _clips: Array[TextureRect] = []      # one per clip, index = recorded order
var _slot_of: Array[int] = [0, 1, 2]     # _slot_of[clip index] = which slot it sits in
var _status: Label
var _film: TextureRect
var _subtitle: Label

var _open := false
var _playing := false                    # the tape is rolling; no more dragging
var _dragging := -1                      # clip index being carried, -1 for none
var _grab_offset := Vector2.ZERO
var _picked := -1                        # slot picked with the number keys


func _ready():
	layer = 110                                  # over the dialogue box
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()


# --- public API ---------------------------------------------------------

# Wired to the computer's `finished` signal, which passes the node along.
func open(_who = null) -> void:
	if _open or GameState.has_flag(flag_id):
		return
	_open = true
	_playing = false
	_dragging = -1
	_picked = -1

	# Re-assigned here as well as in _build_ui, so swapping the art in the
	# Inspector doesn't leave three empty frames on screen.
	var textures := [clip_1, clip_2, clip_3]
	for clip in _clips.size():
		_clips[clip].texture = textures[clip]
		_clips[clip].size = SLOT_SIZE      # never let the texture decide this
		_clips[clip].show()

	_shuffle()
	_highlight()
	_status.text = hint_text
	_film.hide()
	_subtitle.hide()
	_root.show()

	_freeze_player(true)
	_block_menu_overlay(true)


func close() -> void:
	if not _open:
		return
	_open = false
	_root.hide()
	_freeze_player(false)
	_block_menu_overlay(false)


func is_open() -> bool:
	return _open


# --- input --------------------------------------------------------------

func _input(event):
	if not _open:
		return

	# The keys that do something in here are 1-3 and Esc. Everything else
	# dies here so it can't reach the inventory or the room behind.
	if event is InputEventKey or event is InputEventJoypadButton:
		if not _playing and event is InputEventKey and event.pressed and not event.echo:
			if event.is_action_pressed("ui_cancel"):
				close()
			else:
				_press_number(event.physical_keycode)
		get_viewport().set_input_as_handled()
		return

	if _playing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_grab(event.position)
		else:
			_drop(event.position)
	elif event is InputEventMouseMotion and _dragging >= 0:
		_clips[_dragging].position = event.position - _grab_offset


func _grab(at: Vector2) -> void:
	# Topmost first, so a clip already lifted wins over the one under it.
	for i in range(_clips.size() - 1, -1, -1):
		if Rect2(_clips[i].position, _clips[i].size).has_point(at):
			_dragging = i
			_grab_offset = at - _clips[i].position
			_root.move_child(_clips[i], -1)     # draw it on top while carried
			return


func _drop(at: Vector2) -> void:
	if _dragging < 0:
		return

	var carried := _dragging
	_dragging = -1

	var target := _slot_at(at)
	if target >= 0 and target != _slot_of[carried]:
		# Whoever is standing in that slot goes back to the one we came from.
		var displaced := _clip_in_slot(target)
		_slot_of[displaced] = _slot_of[carried]
		_slot_of[carried] = target

	_layout()
	_check()


# The same swap, for players who would rather not drag: 1-3 picks a clip up,
# 1-3 again drops it on that slot and swaps whatever was standing there. The
# rest of the game is keyboard-only, so the mouse should never be the only
# way through a puzzle.
func _press_number(keycode: int) -> void:
	var slot := -1
	match keycode:
		KEY_1: slot = 0
		KEY_2: slot = 1
		KEY_3: slot = 2
	if slot < 0:
		return

	if _picked < 0:
		_picked = slot
		_status.text = "Clip %d picked up — press 1, 2 or 3 to swap it." % (slot + 1)
	elif _picked == slot:
		_picked = -1
		_status.text = hint_text
	else:
		var here := _clip_in_slot(_picked)
		var there := _clip_in_slot(slot)
		_slot_of[here] = slot
		_slot_of[there] = _picked
		_picked = -1
		_layout()
		_check()

	_highlight()


func _highlight() -> void:
	for clip in _clips.size():
		if _picked < 0:
			_clips[clip].modulate = Color(1, 1, 1)
		else:
			var lifted := _slot_of[clip] == _picked
			_clips[clip].modulate = Color(1, 1, 1) if lifted else Color(0.5, 0.5, 0.55)


# Which slot is nearest the drop, if any is close enough to count.
func _slot_at(at: Vector2) -> int:
	for slot in 3:
		if Rect2(_slot_position(slot), SLOT_SIZE).grow(40.0).has_point(at):
			return slot
	return -1


func _clip_in_slot(slot: int) -> int:
	for clip in _slot_of.size():
		if _slot_of[clip] == slot:
			return clip
	return 0


# --- the puzzle itself --------------------------------------------------

func _shuffle() -> void:
	# Any order except the right one, so it always needs at least one move.
	var orders := [[1, 0, 2], [0, 2, 1], [2, 1, 0], [1, 2, 0], [2, 0, 1]]
	_slot_of.assign(orders[randi() % orders.size()])
	_layout()


func _check() -> void:
	for clip in 3:
		if _slot_of[clip] != clip:
			_status.text = wrong_text
			return
	_play_tape()


func _layout() -> void:
	for clip in _clips.size():
		_clips[clip].position = _slot_position(_slot_of[clip])


func _slot_position(slot: int) -> Vector2:
	var total := SLOT_SIZE.x * 3 + SLOT_GAP * 2
	var left := (_root.size.x - total) * 0.5
	return Vector2(left + slot * (SLOT_SIZE.x + SLOT_GAP), SLOT_Y)


# --- the payoff ---------------------------------------------------------

func _play_tape() -> void:
	_playing = true
	GameState.set_flag(flag_id)
	_status.text = ""
	solved.emit()

	for tex in [clip_1, clip_2, clip_3]:
		_show_film(tex)
		await get_tree().create_timer(1.4).timeout

	# The frame it stops on. Held until the player presses something, so
	# nobody misses it.
	_show_film(freeze_frame if freeze_frame else clip_3)
	if freeze_subtitle != "":
		_subtitle.text = freeze_subtitle
		_subtitle.show()
	await get_tree().create_timer(2.6).timeout

	close()
	await _hand_over()


func _show_film(tex: Texture2D) -> void:
	if tex == null:
		return
	for clip in _clips:
		clip.hide()
	_film.texture = tex
	_film.show()


# The same grammar as every other pickup in the chapter: he reacts, the thing
# is held up on screen, and the next press puts it in the bag.
func _hand_over() -> void:
	if not found_lines.is_empty():
		Dialogue.show_lines(found_lines, portrait, speaker_name)
		await Dialogue.finished

	if item_id == "":
		return

	await ItemView.show_item(_item_texture())
	GameState.add_item(item_id)

	var pages: Array = []
	pages.append_array(reaction_lines)
	pages.append("(Added to inventory: %s)" % ItemDB.get_item(item_id)["name"])
	Dialogue.show_lines(pages, portrait, speaker_name)


func _item_texture() -> Texture2D:
	var icon_path: String = ItemDB.get_item(item_id).get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		return load(icon_path)
	return null


# --- UI, built in code so no scene has to wire it up --------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var title := Label.new()
	title.text = title_text
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 150.0
	title.offset_bottom = 220.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(title)

	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_top = 800.0
	_status.offset_bottom = 870.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 28)
	_status.modulate = Color(1, 1, 1, 0.75)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_status)

	# The three slots of the timeline, drawn behind the clips.
	for slot in 3:
		var frame := Panel.new()
		frame.position = _slot_position(slot) - Vector2(6, 6)
		frame.size = SLOT_SIZE + Vector2(12, 12)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.05, 0.05, 0.08, 0.9)
		box.border_color = Color(0.75, 0.72, 0.55, 0.5)
		box.set_border_width_all(3)
		frame.add_theme_stylebox_override("panel", box)
		_root.add_child(frame)

		var number := Label.new()
		number.text = str(slot + 1)
		number.position = _slot_position(slot) + Vector2(0, SLOT_SIZE.y + 16)
		number.size = Vector2(SLOT_SIZE.x, 50)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 32)
		number.modulate = Color(1, 1, 1, 0.6)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(number)

	var textures := [clip_1, clip_2, clip_3]
	for clip in 3:
		var view := TextureRect.new()
		# Order matters: a TextureRect that is handed a texture while it is
		# still on the default expand mode takes the full size of that
		# texture as its minimum, and every size set afterwards is clamped
		# up to it. Loosen it first, then hand over the picture, then say
		# how big it actually is.
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_SCALE
		view.texture = textures[clip]
		view.size = SLOT_SIZE
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(view)
		_clips.append(view)

	# Full-screen playback, on top of everything else in here.
	_film = TextureRect.new()
	_film.set_anchors_preset(Control.PRESET_FULL_RECT)
	_film.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_film.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_film.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_film.hide()
	_root.add_child(_film)

	_subtitle = Label.new()
	_subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_top = -220.0
	_subtitle.offset_bottom = -120.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 52)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.hide()
	_root.add_child(_subtitle)


func _freeze_player(frozen: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_can_move"):
			p.set_can_move(not frozen)


func _block_menu_overlay(blocked: bool) -> void:
	var overlay = get_node_or_null("/root/ChapterEscape")
	if overlay:
		overlay.visible = not blocked
		overlay.set_process_input(not blocked)
