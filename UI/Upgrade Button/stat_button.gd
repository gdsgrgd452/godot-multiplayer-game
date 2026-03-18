extends Button

var stat_id: String = ""
@export var display_text: String = "Upgrade: "

signal stat_chosen(stat_id: String)

# Initializes the button text and connects the press event
func _ready() -> void:
	text = display_text + stat_id
	pressed.connect(_on_pressed)

# Updates the visual text to match the currently assigned stat_id
func refresh_text() -> void:
	text = display_text + stat_id

# Emits the selected stat_id to the listening components
func _on_pressed() -> void:
	stat_chosen.emit(stat_id)
