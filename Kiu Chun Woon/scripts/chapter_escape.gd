extends CanvasLayer

const MAIN_MENU_SCENE := "res://Kiu Chun Woon/scenes/main_menu.tscn"
const EXIT_BUTTON_TEXTURE := preload(
	"res://Kiu Chun Woon/assets/images/industrial_pixel_horror_button.png"
)
const CHAPTER_PATH_PREFIXES := [
	"res://Kiu Chun Woon/scenes/chapter_1",
	"res://Lau Kah Kei/",
	"res://Lew Jia Jia/",
	"res://Tay Hong Fei/",
]

var _escape_button: Button
var _last_scene_path := ""
var _changing_scene := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_escape_button()
	_refresh_visibility()


func _process(_delta: float) -> void:
	var scene_path := _current_scene_path()
	if scene_path != _last_scene_path:
		_last_scene_path = scene_path
		_refresh_visibility()


func _input(event: InputEvent) -> void:
	if _changing_scene or not _is_chapter_scene(_current_scene_path()):
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _create_escape_button() -> void:
	_escape_button = Button.new()
	_escape_button.name = "ChapterEscapeButton"
	_escape_button.text = "ESC  MAIN MENU"
	_escape_button.tooltip_text = "Return to the main menu (Esc)"
	_escape_button.focus_mode = Control.FOCUS_NONE
	_escape_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_escape_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_escape_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_escape_button.offset_left = -300.0
	_escape_button.offset_top = 20.0
	_escape_button.offset_right = -24.0
	_escape_button.offset_bottom = 92.0
	_escape_button.add_theme_font_size_override("font_size", 18)
	_escape_button.add_theme_color_override("font_color", Color("#e9e1d7"))
	_escape_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_escape_button.add_theme_color_override("font_pressed_color", Color.WHITE)

	var button_atlas := AtlasTexture.new()
	button_atlas.atlas = EXIT_BUTTON_TEXTURE
	button_atlas.region = Rect2(0, 155, 1915, 510)

	var normal_style := _make_image_button_style(
		button_atlas,
		Color(0.78, 0.74, 0.68, 1.0)
	)
	var hover_style := _make_image_button_style(
		button_atlas,
		Color(1.0, 0.9, 0.82, 1.0)
	)
	var pressed_style := _make_image_button_style(
		button_atlas,
		Color(0.86, 0.48, 0.4, 1.0),
		true
	)
	_escape_button.add_theme_stylebox_override("normal", normal_style)
	_escape_button.add_theme_stylebox_override("hover", hover_style)
	_escape_button.add_theme_stylebox_override("pressed", pressed_style)
	_escape_button.add_theme_stylebox_override("focus", hover_style)
	_escape_button.pressed.connect(_return_to_main_menu)
	add_child(_escape_button)


func _make_image_button_style(
	texture: Texture2D,
	color: Color,
	pressed := false
) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 72.0
	style.texture_margin_top = 32.0
	style.texture_margin_right = 72.0
	style.texture_margin_bottom = 32.0
	style.content_margin_left = 28.0
	style.content_margin_top = 15.0 if pressed else 13.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 11.0 if pressed else 13.0
	style.modulate_color = color
	return style


func _current_scene_path() -> String:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return ""
	return current_scene.scene_file_path


func _is_chapter_scene(scene_path: String) -> bool:
	for prefix in CHAPTER_PATH_PREFIXES:
		if scene_path.begins_with(prefix):
			return true
	return false


func _refresh_visibility() -> void:
	if is_instance_valid(_escape_button):
		_escape_button.visible = _is_chapter_scene(_current_scene_path())


func _return_to_main_menu() -> void:
	if _changing_scene:
		return
	_changing_scene = true
	get_tree().paused = false
	_escape_button.hide()

	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Unable to return to the main menu: " + str(error))
		_changing_scene = false
		_refresh_visibility()
		return

	await get_tree().process_frame
	_changing_scene = false
	_refresh_visibility()
