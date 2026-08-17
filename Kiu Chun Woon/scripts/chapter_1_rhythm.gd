extends Control

const INTRO_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_placeholder.tscn"
const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const CHAPTER_TWO_SCENE := "res://Lau Kah Kei/scenes/corridor.tscn"

const REACTION_TEXTURES := {
	"PERFECT": preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_perfect.png"),
	"GREAT": preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_great.png"),
	"TOO EARLY": preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_too_early.png"),
	"MISS": preload("res://Kiu Chun Woon/assets/images/reactions/kunkun_miss.png"),
}

const FALLBACK_SONG_DURATION := 38.0
const NOTE_COUNT := 72
const NOTE_TRAVEL_TIME := 1.8
const PERFECT_WINDOW := 0.10
const GOOD_WINDOW := 0.21
const MISS_WINDOW := 0.28
const PASS_ACCURACY := 50.0

const LANE_TEXT := ["←", "↓", "↑", "→"]
const LANE_COLORS := [
	Color("#d99aa3"),
	Color("#c5a4cc"),
	Color("#d9a0a0"),
	Color("#e2c19b"),
]
const NOTE_PATTERN := [
	0, 1, 2, 3, 0, 2, 1, 3,
	0, 0, 2, 1, 3, 3, 1, 2,
	0, 2, 3, 1, 0, 3, 2, 1,
	1, 2, 0, 3, 1, 3, 0, 2,
]

@onready var conductor: RhythmConductor = %Conductor
@onready var atmosphere: ColorRect = $Atmosphere
@onready var note_layer: Control = %NoteLayer
@onready var judgement_label: Label = %JudgementLabel
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var accuracy_label: Label = %AccuracyLabel
@onready var time_label: Label = %TimeLabel
@onready var song_progress_fill: Panel = %SongProgressFill
@onready var reaction_portrait: TextureRect = %ReactionPortrait
@onready var instruction_overlay: Control = %InstructionOverlay
@onready var countdown_label: Label = %CountdownLabel
@onready var result_overlay: Control = %ResultOverlay
@onready var result_title: Label = %ResultTitle
@onready var result_stats: Label = %ResultStats
@onready var evidence_label: Label = %EvidenceLabel
@onready var teacher_mei_dialogue_portrait: TextureRect = %TeacherMeiDialoguePortrait
@onready var teacher_mei_disappointed_portrait: TextureRect = %TeacherMeiDisappointedPortrait

var chart: Array[Dictionary] = []
var next_spawn_index := 0
var playing := false
var countdown_active := false
var score := 0
var combo := 0
var best_combo := 0
var perfect_count := 0
var good_count := 0
var miss_count := 0
var judged_count := 0
var rating_points := 0.0
var judgement_tween: Tween
var atmosphere_tween: Tween
var song_duration := FALLBACK_SONG_DURATION


func _ready() -> void:
	var menu_music := get_node_or_null("/root/MusicManager")
	if menu_music != null and menu_music.has_method("stop_music"):
		menu_music.stop_music()

	song_duration = maxf(conductor.get_song_length(), FALLBACK_SONG_DURATION)
	_build_chart()
	_reset_run()


func _process(_delta: float) -> void:
	if not playing:
		return

	var song_time := conductor.get_song_position()
	_spawn_ready_notes(song_time)
	_update_notes(song_time)
	_update_hud(song_time)

	if song_time >= song_duration:
		_on_song_finished()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_intro()
		return

	if event is InputEventKey and event.echo:
		return
	if not playing:
		return

	var lane := -1
	if event.is_action_pressed("ui_left"):
		lane = 0
	elif event.is_action_pressed("ui_down"):
		lane = 1
	elif event.is_action_pressed("ui_up"):
		lane = 2
	elif event.is_action_pressed("ui_right"):
		lane = 3

	if lane >= 0:
		get_viewport().set_input_as_handled()
		_judge_lane(lane)


func _build_chart() -> void:
	chart.clear()
	for index in range(NOTE_COUNT):
		chart.append({
			"time": conductor.time_for_beat(index),
			"lane": NOTE_PATTERN[index % NOTE_PATTERN.size()],
			"visual": null,
			"judged": false,
			"beat_pulsed": false,
		})


func _reset_run() -> void:
	playing = false
	countdown_active = false
	conductor.stop_song()
	next_spawn_index = 0
	score = 0
	combo = 0
	best_combo = 0
	perfect_count = 0
	good_count = 0
	miss_count = 0
	judged_count = 0
	rating_points = 0.0

	for child in note_layer.get_children():
		child.queue_free()
	for note in chart:
		note["visual"] = null
		note["judged"] = false
		note["beat_pulsed"] = false

	atmosphere.color = Color(0.015, 0.025, 0.055, 0.13)
	judgement_label.modulate.a = 0.0
	reaction_portrait.hide()
	teacher_mei_dialogue_portrait.show()
	teacher_mei_disappointed_portrait.hide()
	countdown_label.hide()
	result_overlay.hide()
	_update_hud(0.0)


func _on_start_training_pressed() -> void:
	if countdown_active or playing:
		return
	teacher_mei_dialogue_portrait.hide()
	teacher_mei_disappointed_portrait.hide()
	instruction_overlay.hide()
	_begin_countdown()


func _begin_countdown() -> void:
	countdown_active = true
	countdown_label.show()
	for message in ["3", "2", "1", "FOLLOW THE BEAT"]:
		countdown_label.text = message
		countdown_label.modulate = Color.WHITE
		countdown_label.scale = Vector2(1.15, 1.15)
		var pulse := create_tween().set_parallel(true)
		pulse.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pulse.tween_property(countdown_label, "scale", Vector2.ONE, 0.35)
		pulse.tween_property(countdown_label, "modulate:a", 0.35, 0.62)
		await get_tree().create_timer(0.72).timeout

	countdown_label.hide()
	countdown_active = false
	_start_song()


func _start_song() -> void:
	playing = true
	conductor.play_song()
	_show_judgement("READY", Color("#f5ead9"))


func _spawn_ready_notes(song_time: float) -> void:
	while next_spawn_index < chart.size():
		var note := chart[next_spawn_index]
		if float(note["time"]) - song_time > NOTE_TRAVEL_TIME:
			break
		_spawn_note(note)
		next_spawn_index += 1


func _spawn_note(note: Dictionary) -> void:
	var lane := int(note["lane"])
	var visual := Label.new()
	visual.text = LANE_TEXT[lane]
	visual.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visual.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_theme_font_size_override("font_size", 58)
	visual.add_theme_color_override("font_color", LANE_COLORS[lane])
	visual.add_theme_color_override("font_outline_color", Color(0.12, 0.095, 0.16, 1.0))
	visual.add_theme_constant_override("outline_size", 7)

	var note_style := StyleBoxFlat.new()
	note_style.bg_color = Color(0.16, 0.13, 0.21, 0.16)
	note_style.border_width_left = 0
	note_style.border_width_top = 0
	note_style.border_width_right = 0
	note_style.border_width_bottom = 0
	note_style.border_color = LANE_COLORS[lane].darkened(0.2)
	note_style.corner_radius_top_left = 8
	note_style.corner_radius_top_right = 8
	note_style.corner_radius_bottom_left = 8
	note_style.corner_radius_bottom_right = 8
	visual.add_theme_stylebox_override("normal", note_style)

	note_layer.add_child(visual)
	note["visual"] = visual
	_position_note(note, conductor.get_song_position())


func _update_notes(song_time: float) -> void:
	for note in chart:
		if bool(note["judged"]):
			continue

		if not bool(note["beat_pulsed"]) and song_time >= float(note["time"]):
			note["beat_pulsed"] = true
			_pulse_background()

		var visual: Label = note["visual"]
		if is_instance_valid(visual):
			_position_note(note, song_time)

		if song_time - float(note["time"]) > MISS_WINDOW:
			_register_miss(note)


func _position_note(note: Dictionary, song_time: float) -> void:
	var visual: Label = note["visual"]
	if not is_instance_valid(visual):
		return

	var lane_width := note_layer.size.x / 4.0
	var note_size := Vector2(maxf(lane_width - 28.0, 76.0), 84.0)
	var hit_y := note_layer.size.y * 0.73
	var spawn_y := -note_size.y
	var progress := 1.0 - ((float(note["time"]) - song_time) / NOTE_TRAVEL_TIME)
	var note_y := lerpf(spawn_y, hit_y, clampf(progress, 0.0, 1.18))
	visual.size = note_size
	visual.position = Vector2(float(note["lane"]) * lane_width + 14.0, note_y)


func _judge_lane(lane: int) -> void:
	var song_time := conductor.get_song_position()
	var best_note: Dictionary = {}
	var smallest_difference := GOOD_WINDOW + 1.0

	for note in chart:
		if bool(note["judged"]) or int(note["lane"]) != lane:
			continue
		var visual: Label = note["visual"]
		if not is_instance_valid(visual):
			continue
		var difference := absf(song_time - float(note["time"]))
		if difference <= GOOD_WINDOW and difference < smallest_difference:
			smallest_difference = difference
			best_note = note

	_flash_receptor(lane)
	if best_note.is_empty():
		combo = 0
		_show_judgement("TOO EARLY", Color("#8d99ae"))
		_update_hud(song_time)
		return

	best_note["judged"] = true
	var visual: Label = best_note["visual"]
	if is_instance_valid(visual):
		visual.hide()
		visual.queue_free()

	judged_count += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	if smallest_difference <= PERFECT_WINDOW:
		perfect_count += 1
		rating_points += 1.0
		score += 1000 + combo * 12
		_show_judgement("PERFECT", Color("#ffd166"))
	else:
		good_count += 1
		rating_points += 0.65
		score += 550 + combo * 6
		_show_judgement("GREAT", Color("#56cfe1"))
	_update_hud(song_time)


func _register_miss(note: Dictionary) -> void:
	if bool(note["judged"]):
		return
	note["judged"] = true
	var visual: Label = note["visual"]
	if is_instance_valid(visual):
		visual.queue_free()
	judged_count += 1
	miss_count += 1
	combo = 0
	_show_judgement("MISS", Color("#ff5c5c"))


func _flash_receptor(lane: int) -> void:
	var receptors := [%LeftReceptor, %DownReceptor, %UpReceptor, %RightReceptor]
	var receptor: Label = receptors[lane]
	receptor.modulate = LANE_COLORS[lane].lightened(0.35)
	receptor.scale = Vector2(1.12, 1.12)
	var flash := create_tween().set_parallel(true)
	flash.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash.tween_property(receptor, "modulate", Color.WHITE, 0.18)
	flash.tween_property(receptor, "scale", Vector2.ONE, 0.18)


func _pulse_background() -> void:
	if atmosphere_tween != null and atmosphere_tween.is_valid():
		atmosphere_tween.kill()
	atmosphere.color = Color(0.06, 0.08, 0.12, 0.21)
	atmosphere_tween = create_tween()
	atmosphere_tween.tween_property(
		atmosphere,
		"color",
		Color(0.015, 0.025, 0.055, 0.13),
		0.22
	)


func _show_judgement(message: String, color: Color) -> void:
	_show_reaction(message)
	if judgement_tween != null and judgement_tween.is_valid():
		judgement_tween.kill()
	judgement_label.text = message
	judgement_label.add_theme_color_override("font_color", color)
	judgement_label.modulate = Color.WHITE
	judgement_label.scale = Vector2(1.16, 1.16)
	judgement_tween = create_tween().set_parallel(true)
	judgement_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	judgement_tween.tween_property(judgement_label, "scale", Vector2.ONE, 0.18)
	judgement_tween.tween_property(judgement_label, "modulate:a", 0.0, 0.62).set_delay(0.28)


func _show_reaction(message: String) -> void:
	if not REACTION_TEXTURES.has(message):
		reaction_portrait.hide()
		return
	reaction_portrait.texture = REACTION_TEXTURES[message]
	reaction_portrait.modulate = Color(1, 1, 1, 0)
	reaction_portrait.show()
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(reaction_portrait, "modulate:a", 1.0, 0.16)


func _update_hud(song_time: float) -> void:
	score_label.text = "%06d" % score
	combo_label.text = "%02d combo!" % combo
	var accuracy := 0.0
	if judged_count > 0:
		accuracy = rating_points / float(judged_count) * 100.0
	accuracy_label.text = "ACCURACY  %05.1f%%" % accuracy

	var current_seconds := clampi(int(song_time), 0, int(song_duration))
	var total_seconds := int(song_duration)
	time_label.text = "%02d:%02d / %02d:%02d" % [
		floori(current_seconds / 60.0),
		current_seconds % 60,
		floori(total_seconds / 60.0),
		total_seconds % 60,
	]
	song_progress_fill.anchor_right = clampf(song_time / song_duration, 0.0, 1.0)


func _on_song_finished() -> void:
	if not playing:
		return
	playing = false
	for note in chart:
		if not bool(note["judged"]):
			_register_miss(note)
	_update_hud(song_duration)
	_show_results()


func _show_results() -> void:
	var hits := perfect_count + good_count
	var final_accuracy := rating_points / float(maxi(chart.size(), 1)) * 100.0
	var grade := "D"

	if final_accuracy >= 92.0:
		grade = "S"
	elif final_accuracy >= 82.0:
		grade = "A"
	elif final_accuracy >= 68.0:
		grade = "B"
	elif final_accuracy >= PASS_ACCURACY:
		grade = "C"

	var passed := final_accuracy >= PASS_ACCURACY

	# Resolve optional result buttons once so both branches can use them.
	var continue_button := get_node_or_null("%ContinueButton") as Button
	var retry_button := get_node_or_null("%RetryButton") as Button
	var main_menu_button := get_node_or_null("%ReturnMainMenuButton") as Button

	if passed:
		result_title.text = "ORIENTATION COMPLETE  |  GRADE %s" % grade
	else:
		result_title.text = "TRAINING FAILED  |  GRADE %s" % grade

	result_stats.text = (
		"SCORE  %06d\nPERFECT  %02d     GREAT  %02d     MISS  %02d\nBEST COMBO  %02d     ACCURACY  %05.1f%%"
		% [score, perfect_count, good_count, miss_count, best_combo, final_accuracy]
	)

	if not passed:
		teacher_mei_dialogue_portrait.hide()
		teacher_mei_disappointed_portrait.show()
		evidence_label.text = "Teacher Mei feels disappointed once she sees the result.\n\"You must reach Grade C or higher.\"\nRETRY TRAINING TO CONTINUE."
		evidence_label.add_theme_color_override("font_color", Color("#ff7777"))

		# A failed attempt does not unlock Chapter 2.

		if continue_button != null:
			continue_button.hide()
		if retry_button != null:
			retry_button.show()
		if main_menu_button != null:
			main_menu_button.hide()

		_mark_chapter_one_complete(grade, final_accuracy, false)
	else:
		teacher_mei_disappointed_portrait.hide()
		teacher_mei_dialogue_portrait.show()
		if hits == 0:
			_award_torn_diary_evidence()
			evidence_label.text = "HIDDEN EVIDENCE FOUND\nTorn Diary Page"
			evidence_label.add_theme_color_override("font_color", Color("#ff7777"))
		else:
			evidence_label.text = "Teacher Mei: Keep following the rhythm. The camp is watching."
			evidence_label.add_theme_color_override("font_color", Color("#a9b8c8"))


		if continue_button != null:
			continue_button.show()
		if retry_button != null:
			retry_button.show()
		if main_menu_button != null:
			main_menu_button.show()

		_mark_chapter_one_complete(grade, final_accuracy, true)

	result_overlay.show()

	if passed:
		if continue_button != null:
			continue_button.grab_focus()
	else:
		if retry_button != null:
			retry_button.grab_focus()


func _mark_chapter_one_complete(
	grade: String,
	final_accuracy: float,
	passed: bool = true
) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return

	game_state.set_meta("chapter_1_complete", passed)
	game_state.set_meta("chapter_1_grade", grade)
	game_state.set_meta("chapter_1_accuracy", final_accuracy)


func _award_torn_diary_evidence() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or bool(game_state.get_meta("torn_diary_page", false)):
		return
	game_state.set_meta("torn_diary_page", true)
	var evidence_count := int(game_state.get_meta("evidence_count", 0))
	game_state.set_meta("evidence_count", evidence_count + 1)


func _on_retry_pressed() -> void:
	_reset_run()
	result_overlay.hide()

	if teacher_mei_disappointed_portrait != null:
		teacher_mei_disappointed_portrait.hide()

	if teacher_mei_dialogue_portrait != null:
		teacher_mei_dialogue_portrait.show()

	instruction_overlay.show()

	var start_button := get_node_or_null("%StartTrainingButton") as Button
	if start_button != null:
		start_button.grab_focus()


func _on_continue_pressed() -> void:
	conductor.stop_song()
	var error := get_tree().change_scene_to_file(CHAPTER_TWO_SCENE)
	if error != OK:
		push_error("Unable to open Chapter 2 scene: " + CHAPTER_TWO_SCENE)


func _on_return_main_menu_pressed() -> void:
	conductor.stop_song()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_back_pressed() -> void:
	_return_to_intro()


func _return_to_intro() -> void:
	conductor.stop_song()
	get_tree().change_scene_to_file(INTRO_SCENE)
