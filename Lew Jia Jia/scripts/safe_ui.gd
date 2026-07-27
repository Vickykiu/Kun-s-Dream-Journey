extends CanvasLayer

# Signal emitted when safe is unlocked (notifies the room scene)
signal safe_opened 
signal file_taken
# --- Node References ---
@onready var display = $Label 
@onready var sfx_button = $BtnSound
@onready var safe_bg = $TextureRect      # Safe UI background image
@onready var folder_btn = $FolderBtn    # Clickable area over the folder inside
@onready var file_detail = $FileDetail  # Detail view panel for the document

var current_input = ""
const CORRECT_PASS = "31512" # Safe password

func _ready():
	display.text = "" 
	# Hide folder button and detail panel when UI initialises
	folder_btn.visible = false
	file_detail.visible = false

# --- Keypad Input Logic ---
func add_digit(digit: String):
	if sfx_button:
		sfx_button.play()
	if current_input.length() < 5: 
		current_input += digit
		display.text = current_input

# Digit buttons (0-9)
func _on_btn_1_pressed(): add_digit("1")
func _on_btn_2_pressed(): add_digit("2")
func _on_btn_3_pressed(): add_digit("3")
func _on_btn_4_pressed(): add_digit("4")
func _on_btn_5_pressed(): add_digit("5")
func _on_btn_6_pressed(): add_digit("6")
func _on_btn_7_pressed(): add_digit("7")
func _on_btn_8_pressed(): add_digit("8")
func _on_btn_9_pressed(): add_digit("9")
func _on_btn_0_pressed(): add_digit("0")

# Clear button
func _on_btn_clear_pressed():
	current_input = ""
	display.text = ""

# --- Enter Button Logic ---
func _on_btn_enter_pressed():
	if current_input == CORRECT_PASS:
		print("Password correct! Safe opened!")
		display.text = ""
		
		# 1. Change background texture to open safe image
		safe_bg.texture = preload("res://Lew Jia Jia/assets/Safe_OpenEmpty.png")
		
		# 2. Enable folder click area
		folder_btn.visible = true
		
		# 3. Emit signal to notify room scene
		safe_opened.emit()
	else:
		print("Incorrect password!")
		display.text = "ERROR"
		current_input = ""

# --- Folder Click: Show Detail View ---
func _on_folder_btn_pressed():
	file_detail.visible = true

# --- Close Detail View ---
func _on_close_file_btn_pressed():
	file_detail.visible = false

# --- Exit Safe UI ---
func _on_btn_exit_pressed():
	queue_free()
