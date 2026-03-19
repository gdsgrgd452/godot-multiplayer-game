extends Node

@export var player_speed: int = 100
var input_dir: Vector2 = Vector2.ZERO

@onready var player: Node = get_parent().get_parent()

# Triggers local input gathering for the client
func _physics_process(_delta: float) -> void:
	# Client gets input
	if player.name == str(multiplayer.get_unique_id()):
		_gather_input()

# Reads WASD keys and synchronizes it with the server
func _gather_input() -> void:
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("move_up", "move_down")
	var new_dir: Vector2 = Vector2(x, y)
		
	if new_dir.length() > 0:
		new_dir = new_dir.normalized()
		
	# Only send an RPC if the input actually changed
	if new_dir != input_dir:
		input_dir = new_dir
		if not multiplayer.is_server():
			rpc_id(1, "receive_input", new_dir)

# Changes the input for movement (server side) after a client requests it
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2) -> void:
	if multiplayer.is_server():
		# Security: Ensure the client is only moving their own parent node
		if str(multiplayer.get_remote_sender_id()) == player.name:
			input_dir = dir

# The parent player script will call this to get the final maths
func get_movement_velocity() -> Vector2:
	return input_dir * player_speed
