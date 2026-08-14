extends CharacterBody2D

# The puppet instructor patrolling the monitor room.
#
# He walks a straight line back and forth. While he is walking you only ever
# see his side or his back, and the cone in front of him points along the
# wall — that is your window. At each end of the walk he stops and turns to
# face the room for a couple of seconds, and anything standing in that cone
# gets caught.
#
#   walking  ->  cone points the way he is going  ->  safe behind him
#   stopped  ->  cone points at the room          ->  move and you are seen
#
# Anything solid between him and Kunkun blocks the view, so any StaticBody2D
# in the room works as cover — the filing cabinets, a desk, a wall. Nothing
# to set up: if the physics ray hits it before it reaches the player, it
# counts.
#
# He never catches the player while the game is paused for a dialogue box, a
# close-up or the video puzzle. Being caught by something you couldn't walk
# away from is not tension, it's a bug.

signal caught

@export_group("Look")
@export var tex_front: Texture2D          # facing the room, i.e. facing you
@export var tex_back: Texture2D
@export var tex_left: Texture2D
@export var tex_right: Texture2D
@export var tex_left_step: Texture2D      # optional, mid-stride
@export var tex_right_step: Texture2D
@export var steps_per_second := 4.0
@export var tint := Color(1, 1, 1, 1)

@export_group("Patrol")
# How far he walks before turning back, along X. He starts at the left end.
@export var patrol_distance := 400.0
@export var speed := 90.0

# How long he stands at each end. This is the dangerous part: he spends it
# looking at the room instead of along it.
@export var look_around_time := 1.8

@export_group("Eyes")
# While he is walking he is only looking where he is going: a narrow beam
# down the lane. Stay out of the lane in front of him and you are fine.
@export var sight_range := 240.0
@export var sight_angle := 22.0           # degrees either side of where he faces

# When he stops and turns to face the room he is actually looking, and this
# is the wide one. Being anywhere in this wedge is what gets you caught.
@export var scan_range := 420.0
@export var scan_angle := 55.0

# Draw the cone on screen. Stealth the player can't see is just bad luck, so
# leave this on unless you are deliberately making it cruel.
@export var show_cone := true
@export var cone_colour := Color(1, 0.25, 0.2, 0.16)

# A moment of blindness after the game hands control back — closing a
# dialogue box or the puzzle and being caught in the same frame, with no
# chance to move, reads as the game cheating.
@export var grace_after_freeze := 1.2

@export_group("Caught")
@export var caught_face: Texture2D
@export_multiline var caught_text: String = ""
@export_file("*.tscn") var caught_scene: String = ""
@export var face_time := 1.4              # how long his face fills the screen

@onready var _sprite: Sprite2D = $Sprite

var _origin_x := 0.0
var _heading := 1.0                       # +1 walking right, -1 walking left
var _facing := Vector2.RIGHT              # where the cone points
var _looking := false                     # standing at an end, facing the room
var _timer := 0.0
var _step_time := 0.0
var _caught := false
var _was_frozen := true                   # the room opens with a dialogue box
var _grace := 0.0

var _screen: CanvasLayer
var _face: TextureRect
var _black: ColorRect
var _label: Label


func _ready():
	_origin_x = global_position.x
	_sprite.modulate = tint
	_face_direction(Vector2.RIGHT)
	_build_caught_screen()


func _physics_process(delta):
	if _caught:
		return

	# The game is busy with a box, a close-up or the puzzle: he waits too.
	var player = _player()
	if player == null or not player.can_move:
		_was_frozen = true
		return

	# Just handed back control — give them a moment before he looks.
	if _was_frozen:
		_was_frozen = false
		_grace = grace_after_freeze
	if _grace > 0.0:
		_grace -= delta

	if _looking:
		_timer -= delta
		if _timer <= 0.0:
			_looking = false
			_heading = -_heading
			_face_direction(Vector2.RIGHT if _heading > 0.0 else Vector2.LEFT)
	elif _past_the_end() or is_on_wall():
		_looking = true
		_timer = look_around_time
		_step_time = 0.0
		_face_direction(Vector2.DOWN)          # turns to look at the room
	else:
		velocity = Vector2(speed * _heading, 0.0)
		move_and_slide()
		_animate(delta)

	if _grace <= 0.0 and _sees(player):
		_catch()


func _past_the_end() -> bool:
	var travelled := global_position.x - _origin_x
	if _heading > 0.0:
		return travelled >= patrol_distance
	return travelled <= 0.0


# --- eyes ---------------------------------------------------------------

func _sees(player) -> bool:
	var to: Vector2 = player.global_position - global_position
	if to.length() > _range():
		return false
	if abs(rad_to_deg(_facing.angle_to(to))) > _angle():
		return false

	# Something solid in the way? Then he can't see through it.
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == player


# Standing still and scanning is a different pair of eyes from walking.
func _range() -> float:
	return scan_range if _looking else sight_range


func _angle() -> float:
	return scan_angle if _looking else sight_angle


func _player():
	for p in get_tree().get_nodes_in_group("player"):
		return p
	return null


# --- being caught -------------------------------------------------------

func _catch() -> void:
	_caught = true
	velocity = Vector2.ZERO
	caught.emit()

	var player = _player()
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	_block_menu_overlay(true)

	if caught_text != "":
		_label.text = caught_text

	var tween := create_tween()
	tween.tween_property(_face, "modulate:a", 1.0, 0.18)
	tween.tween_property(_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(face_time)
	tween.tween_property(_black, "modulate:a", 1.0, 0.7)
	await tween.finished

	if caught_scene != "":
		get_tree().change_scene_to_file(caught_scene)


# --- drawing ------------------------------------------------------------

func _draw():
	if not show_cone or _caught:
		return

	var points := PackedVector2Array([Vector2.ZERO])
	var half := deg_to_rad(_angle())
	var steps := 18
	for i in steps + 1:
		var a := -half + (half * 2.0) * float(i) / float(steps)
		points.append(_facing.rotated(a) * _range())
	draw_colored_polygon(points, cone_colour)


func _face_direction(dir: Vector2) -> void:
	_facing = dir
	queue_redraw()

	var tex: Texture2D = null
	if dir == Vector2.LEFT:
		tex = tex_left
	elif dir == Vector2.RIGHT:
		tex = tex_right
	elif dir == Vector2.DOWN:
		tex = tex_front
	else:
		tex = tex_back
	_show(tex)


func _animate(delta: float) -> void:
	_step_time += delta
	var standing := tex_right if _heading > 0.0 else tex_left
	var stepping := tex_right_step if _heading > 0.0 else tex_left_step
	var on_step := int(_step_time * steps_per_second) % 2 == 1
	_show(stepping if (on_step and stepping) else standing)
	queue_redraw()


func _show(tex: Texture2D) -> void:
	if tex and _sprite.texture != tex:
		_sprite.texture = tex


# --- the screen he fills when he gets you -------------------------------

func _build_caught_screen() -> void:
	_screen = CanvasLayer.new()
	_screen.layer = 115
	add_child(_screen)

	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.texture = caught_face
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face.modulate.a = 0.0
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_face)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -260.0
	_label.offset_bottom = -140.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 48)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_label)

	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.modulate.a = 0.0
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_black)


func _block_menu_overlay(blocked: bool) -> void:
	var overlay = get_node_or_null("/root/ChapterEscape")
	if overlay:
		overlay.visible = not blocked
		overlay.set_process_input(not blocked)
