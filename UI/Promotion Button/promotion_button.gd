extends Button

var type_id: String = ""
@export var display_text: String = "Promote: "

signal type_chosen(type_id: String)

# Initializes the button text and connects the press event
func _ready() -> void:
	text = display_text + type_id
	pressed.connect(_on_pressed)

# Updates the visual text to match the currently assigned type_id
func refresh_text() -> void:
	text = display_text + type_id

# Emits the selected type_id to the listening components
func _on_pressed() -> void:
	print("Pressed")
	type_chosen.emit(type_id)
