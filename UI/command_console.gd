extends CanvasLayer

@onready var input: LineEdit = $CommandInput
@onready var submit_button: Button = $SubmitButton

# Connects UI signals for command processing and ensures the console is hidden by default.
func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	input.text_submitted.connect(_on_text_submitted)

# Forwards the LineEdit text to the local player's testing component.
func _on_submit_pressed() -> void:
	_transmit_command(input.text)
	input.clear()

# Forwards the submitted text from the LineEdit to the local player's testing component.
func _on_text_submitted(new_text: String) -> void:
	_transmit_command(new_text)
	input.clear()

# Locates the testing component on the local player and passes the raw string.
func _transmit_command(text: String) -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var player_node: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + local_id)
	if is_instance_valid(player_node):
		var test_comp: Node = player_node.get_node_or_null("TestingComponent")
		if is_instance_valid(test_comp) and test_comp.has_method("send_command"):
			test_comp.send_command(text)
