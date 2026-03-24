extends Node2D

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new() 
const PORT: int = 8910 

var max_food: int = 0
@export var is_hosting: bool = false # Remove this?

# --- New Spectator Variables ---
var spectate_target: Node2D = null
var respawn_timer: float = 0.0
@onready var spectator_camera: Camera2D = $SpectatorCamera
@onready var respawn_button: Button = $CanvasLayer/RespawnButton
@onready var respawn_label: Label = $CanvasLayer/RespawnTimerLabel

var leaderboard_timer: float = 0.0


var arena_size: float = 2000.0
var top_left_x: float = -arena_size/2
var top_left_y: float = -arena_size/2
var bottom_left_x: float = arena_size/2

# Connects buttons and initializes the game boundary
func _ready() -> void:
	$CanvasLayer/HostButton.pressed.connect(_on_host_pressed)
	$CanvasLayer/HostOPButton.pressed.connect(_on_host_open_port_pressed)
	$CanvasLayer/JoinButton.pressed.connect(_on_join_pressed)
	$Background.size = Vector2(arena_size, arena_size)
	$Background.position = Vector2(-arena_size/2, -arena_size/2)
	respawn_button.pressed.connect(_on_respawn_pressed)
	_create_boundaries()

# Handles the countdown timer and smoothly pans the spectator camera to the killer.
func _process(delta: float) -> void:
	# Lerp camera to target if it exists and hasn't disconnected/died
	if spectate_target and is_instance_valid(spectate_target) and spectate_target.is_inside_tree():
		spectator_camera.global_position = spectator_camera.global_position.lerp(spectate_target.global_position, delta * 5.0)
		
	# Handle the countdown sequence
	if respawn_timer > 0.0:
		respawn_timer -= delta
		respawn_label.text = "Respawning in: " + str(ceil(respawn_timer)) + "s"
		
		if respawn_timer <= 0.0:
			respawn_label.hide()
			respawn_button.show()
			spectate_target = null # Stop tracking the killer so they can spawn in peace
			
	# Server handles leaderboard calculation
	if multiplayer.is_server():
		leaderboard_timer -= delta
		if leaderboard_timer <= 0.0:
			leaderboard_timer = 1.0 # Update the leaderboard every 1 second and broadcasts to players
			broadcast_leaderboard()

# Gathers all active players, sorts them by total score, and broadcasts the list.
func broadcast_leaderboard() -> void:
	var scores: Array = []
	
	for player: Node in $SpawnedPlayers.get_children():
		# Ensure the player node isn't scheduled for deletion
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			continue
			
		var leveling_comp: Node = player.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": player.name, "score": leveling_comp.total_score, "team_id": player.team_id})
		else:
			printerr("Player has no leveling component: " + str(player.name))
	
	for npc: Node in $SpawnedNPCs.get_children():
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		
		var leveling_comp: Node = npc.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": npc.name, "score": leveling_comp.total_score, "team_id": npc.team_id})
		else:
			printerr("NPC has no leveling component: " + str(npc.name))
	
	# Sort the array from highest score to lowest
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	
	# Format the text block
	var lb_text: String = "--- Leaderboard ---\n"
	for i: int in range(scores.size()):
		var p_data: Dictionary = scores[i]
		var prefix: String = "Player " if p_data["id"] != "1" else "Host "
		lb_text += str(i + 1) + ". " + prefix + p_data["id"].left(7) + " - Score: " + str(p_data["score"]) + " - Team: " + str(p_data["team_id"]) + "\n"
		
	# Beam the compiled text to all clients
	update_leaderboard_rpc.rpc(lb_text)

# Receives the formatted leaderboard string from the server and passes it to the local player.
@rpc("authority", "call_local", "unreliable")
func update_leaderboard_rpc(leaderboard_text: String) -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node = $SpawnedPlayers.get_node_or_null(local_id)
	
	if local_player:
		var ui_comp: Node = local_player.get_node_or_null("UIComponent")
		if ui_comp and ui_comp.has_method("update_leaderboard_ui"):
			ui_comp.update_leaderboard_ui(leaderboard_text)
		else:
			printerr("No player UI (LB)")


# Sets up the local client's UI and camera for the spectate phase.
func start_spectating(killer_id: String) -> void:
	respawn_button.hide()
	respawn_label.show()
	respawn_timer = 10.0
	
	# Swap the active camera to the main scene's spectator camera
	spectator_camera.enabled = true
	spectator_camera.make_current()

	
	# Attempt to find the killer. If environmental or missing, the camera stays where the player died.
	if killer_id != "":
		var killer_node = $SpawnedPlayers.get_node_or_null(killer_id)
		if killer_node:
			spectate_target = killer_node
			# Snap the camera to the killer immediately so it doesn't drag across the entire map
			spectator_camera.global_position = spectate_target.global_position

func _create_boundaries() -> void:
	var boundary_body: StaticBody2D = StaticBody2D.new()
	boundary_body.add_to_group("boundary")
		
	# Set the boundary to Layer 2 (Bit 1, Value 2)
	boundary_body.collision_layer = 2
	boundary_body.collision_mask = 0
	
	var rects: Array = [
		Rect2(top_left_x - 50, top_left_y - 50, arena_size + 100, 50),  # Top wall
		Rect2(top_left_x - 50, bottom_left_x, arena_size + 100, 50),    # Bottom wall
		Rect2(top_left_x - 50, top_left_y, 50, arena_size),             # Left wall
		Rect2(top_left_x + arena_size, top_left_y, 50, arena_size)      # Right wall
	]
	
	for rect in rects:
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.position + (rect.size / 2.0)
		boundary_body.add_child(collision)
		
	add_child(boundary_body)

func _on_host_open_port_pressed() -> void:
	# Run the UPNP port forwarding before starting the server
	setup_upnp()
	
	_on_host_pressed() 

# Initiates the server and spawns the host player
func _on_host_pressed() -> void:
	peer.create_server(PORT) 
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect($SpawnedPlayers.add_player)
	$SpawnedPlayers.add_player(multiplayer.get_unique_id())
	
	hide_out_of_game_info()
	
	is_hosting = true

# Attempts to automatically forward the game port on the host's router.
func setup_upnp() -> void:
	var upnp: UPNP = UPNP.new()
	
	# Ask the network to find the local router (This will be blocked by many networks)
	var discover_result: int = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed! Error: %s" % discover_result)
		$CanvasLayer/SharingIPLabel.text = "UPNP Discover Failed! Error: %s" % discover_result
		return

	# Verify the router is a valid gateway that accepts commands
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		print("UPNP Invalid Gateway!")
		$CanvasLayer/SharingIPLabel.text = "UPNP Invalid Gateway!"
		return

	# Ask the router to open the UDP port (ENet uses UDP)
	var map_result: int = upnp.add_port_mapping(PORT, PORT, "My Godot Game", "UDP")
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed! Error: %s" % map_result)
		$CanvasLayer/SharingIPLabel.text = "UPNP Port Mapping Failed! Error: %s" % map_result
		return
		
	# Prints the public IP so the host can share it
	print("UPNP Success! Port %s is open." % PORT)
	print("Your public IP to give to friends is: %s" % upnp.query_external_address())
	$CanvasLayer/SharingIPLabel.text = "Your public IP to give to friends is: %s" % upnp.query_external_address()

# Attempts to connect to a server IP
func _on_join_pressed() -> void:
	var ip_to_join: String = $CanvasLayer/InputIP.text
	
	if ip_to_join == "":
		ip_to_join = "127.0.0.1"
		
	peer.create_client(ip_to_join, PORT)
	multiplayer.multiplayer_peer = peer
	
	hide_out_of_game_info()


func hide_out_of_game_info() -> void:
	$CanvasLayer/HostButton.hide()
	$CanvasLayer/HostOPButton.hide()
	$CanvasLayer/JoinButton.hide()
	$CanvasLayer/InputIP.hide()
	$CanvasLayer/Panel.hide()
	$CanvasLayer/Panel2.hide()
	respawn_button.hide()

# Hides the button locally and asks the server for a new body.
func _on_respawn_pressed() -> void:
	respawn_button.hide()
	request_respawn.rpc_id(1)

# Deletes the old dead player node with a temporary unique name and spawns a fresh one to prevent synchronization race conditions.
@rpc("any_peer", "call_local", "reliable")
func request_respawn() -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	var old_player: Node = $SpawnedPlayers.get_node_or_null(str(sender_id))
	
	if old_player:
		old_player.name = str(sender_id) + "_dying_" + str(Time.get_ticks_msec())
		old_player.queue_free()
		
	$SpawnedPlayers.add_player(sender_id)
