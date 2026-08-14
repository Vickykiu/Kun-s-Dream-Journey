extends CharacterBody2D

# A trainee on autopilot. Walks the same short stretch of corridor back and
# forth, mutters the same words over and over, and never looks up. There is
# nothing to press E on, because there is nobody left in there to talk to.
#
# Deliberately NOT player.gd. These only ever walk left and right, so none of
# the four-direction animation in there applies, and Kunkun's movement stays
# free to change without dragging the extras along behind it.
#
# Set `patrol_distance` to 0 and they stand still instead — face them away
# with `tex_back` and you get the one at the end of the hall who won't turn
# around.

@export_group("Look")
@export var tex_left: Texture2D          # standing, facing left
@export var tex_right: Texture2D         # standing, facing right
@export var tex_left_step: Texture2D     # optional, mid-stride
@export var tex_right_step: Texture2D

# Only used when standing still (patrol_distance = 0). Empty falls back to
# tex_left, so a missing back sprite costs you the pose, not a crash.
@export var tex_back: Texture2D

# Drain the colour out of them. Different values on each student make three
# copies of the same sprite read as three different people.
@export var tint := Color(1, 1, 1, 1)

@export_group("Walking")
@export var speed := 70.0

# How far they get before turning around. 0 = they never move.
@export var patrol_distance := 200.0

# How long they stand at each end before shuffling back.
@export var pause_time := 1.2

@export var steps_per_second := 4.0

@export_group("Muttering")
# Handed to the Label underneath (see float_text.gd). Kept here so a whole
# student can be set up from this one node in the Inspector. One line per row
# — a text box rather than an array because Godot blanks exported arrays on
# instanced scenes, and a student who has quietly lost their lines looks
# exactly like a student who is working fine.
@export_multiline var mutter_text: String = "Training.\nTraining.\nWe become stars."
@export var mutter_delay := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _mutter: Label = get_node_or_null("Mutter")

var _origin_x := 0.0
var _heading := 1.0      # +1 walking right, -1 walking left
var _wait := 0.0
var _step_time := 0.0


func _ready():
	_origin_x = global_position.x
	_sprite.modulate = tint

	if _mutter:
		_mutter.say(mutter_text, mutter_delay)

	if patrol_distance <= 0.0:
		# Standing still forever — no reason to run physics on them.
		_show(tex_back if tex_back else tex_left)
		set_physics_process(false)
		return

	_show(tex_right)


func _physics_process(delta):
	# Standing at the end of the walk, about to turn back.
	if _wait > 0.0:
		_wait -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_step_time = 0.0
		_show(_standing_pose())
		return

	# Reached the end of the beat, or walked into something (a wall, or the
	# player standing in the way — either way, turn around).
	if _past_the_end() or is_on_wall():
		_heading = -_heading
		_wait = pause_time
		return

	velocity = Vector2(speed * _heading, 0.0)
	move_and_slide()
	_animate(delta)


func _past_the_end() -> bool:
	var travelled := global_position.x - _origin_x
	if _heading > 0.0:
		return travelled >= patrol_distance
	return travelled <= 0.0


func _animate(delta: float) -> void:
	_step_time += delta

	var standing := _standing_pose()
	var stepping := tex_right_step if _heading > 0.0 else tex_left_step

	# Alternate standing / mid-stride. With no step sprite they just slide
	# along, which is not the worst look for something this hollow.
	var on_step := int(_step_time * steps_per_second) % 2 == 1
	_show(stepping if (on_step and stepping) else standing)


func _standing_pose() -> Texture2D:
	return tex_right if _heading > 0.0 else tex_left


func _show(tex: Texture2D) -> void:
	if tex and _sprite.texture != tex:
		_sprite.texture = tex
