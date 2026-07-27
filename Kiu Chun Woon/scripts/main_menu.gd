extends Control

const CHAPTER_ONE_SCENE := "res://Kiu Chun Woon/scenes/chapter_1_placeholder.tscn"
const CHAPTER_SELECTION_SCENE := "res://Kiu Chun Woon/scenes/chapter_selection.tscn"
const OPTIONS_SCENE := "res://Kiu Chun Woon/scenes/options_menu.tscn"

const MENU_WIDTH := 460.0
const MENU_AREA_LEFT := 0.62


@onready var background: TextureRect = $Background
@onready var atmosphere_tint: ColorRect = $AtmosphereTint
@onready var readability_shade: ColorRect = $LeftReadabilityShade
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var menu_layout: HBoxContainer = $SafeMargin/Layout
@onready var menu_card: PanelContainer = %MenuCard
@onready var start_button: Button = %StartButton

@onready var menu_buttons: Array[Button] = [
	%StartButton,
	$SafeMargin/Layout/MenuCard/MenuColumn/Buttons/ChapterSelectionButton,
	$SafeMargin/Layout/MenuCard/MenuColumn/Buttons/OptionsButton,
	$SafeMargin/Layout/MenuCard/MenuColumn/Buttons/QuitButton
]


func _ready() -> void:
	_configure_layout()
	MusicManager.play_menu_music()

	for button in menu_buttons:
		button.mouse_entered.connect(
			_on_button_mouse_entered.bind(button)
		)
		button.mouse_exited.connect(
			_on_button_mouse_exited.bind(button)
		)

	_play_intro_animation()


func _configure_layout() -> void:
	# Display the complete background picture.
	_set_control_region(
		background,
		0.0,
		0.0,
		1.0,
		1.0
	)

	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Apply the dark overlays only behind the right-side menu.
	_set_control_region(
		atmosphere_tint,
		MENU_AREA_LEFT,
		0.0,
		1.0,
		1.0
	)

	_set_control_region(
		readability_shade,
		MENU_AREA_LEFT,
		0.0,
		1.0,
		1.0
	)

	atmosphere_tint.color = Color(
		0.008,
		0.004,
		0.003,
		0.16
	)

	readability_shade.color = Color(
		0.0,
		0.0,
		0.0,
		0.12
	)

	menu_layout.alignment = BoxContainer.ALIGNMENT_END

	menu_card.custom_minimum_size = Vector2(
		MENU_WIDTH,
		menu_card.custom_minimum_size.y
	)

	safe_margin.offset_left = 36.0
	safe_margin.offset_top = 28.0
	safe_margin.offset_right = -110.0
	safe_margin.offset_bottom = -28.0


func _set_control_region(
	control: Control,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom

	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _play_intro_animation() -> void:
	menu_card.modulate.a = 0.0

	var intro := create_tween()
	intro.set_trans(Tween.TRANS_QUAD)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(
		menu_card,
		"modulate:a",
		1.0,
		0.45
	)


func _on_button_mouse_entered(button: Button) -> void:
	button.grab_focus()


func _on_button_mouse_exited(button: Button) -> void:
	if button.has_focus():
		button.release_focus()


func _on_start_pressed() -> void:
	MusicManager.stop_music()
	get_tree().change_scene_to_file(CHAPTER_ONE_SCENE)


func _on_chapter_selection_pressed() -> void:
	get_tree().change_scene_to_file(CHAPTER_SELECTION_SCENE)


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_quit_pressed() -> void:
	MusicManager.save_settings()
	get_tree().quit()
