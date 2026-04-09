extends Node2D

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new() 
const PORT: int = 8910 

@export var is_hosting: bool = false # Remove this?

var spectate_target: Node2D = null
var respawn_timer: float = 0.0
@onready var spectator_camera: Camera2D = $SpectatorCamera
@onready var respawn_button: Button = $RespawnLayer/RespawnPanel/RespawnButton
@onready var respawn_label: Label = $RespawnLayer/RespawnPanel/RespawnTimerLabel
var dead_scores_dict: Dictionary

@onready var ip_label: Label = $CanvasLayer/SharingIPLabel

const PRESETS: Dictionary = {
	"Alone": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 0, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Holy_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # Alone for testing
	
	"1-Bot": { "game_type": "FFA", "arena_size": 1500.0, "food_per_player": 50, "bots_per_player": 1, "bot_classes": ["Jester"], "npc_points": true, "start_lvls": 200, "player_class": "Holy_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 1 Bot for testing
	
	"1-Bot-L": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 1, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Super_Queen", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 1 Bot for testing
	
	"2-Bot": { "game_type": "FFA", "arena_size": 2500.0, "food_per_player": 1500, "bots_per_player": 2, "bot_classes": ["Pawn"], "npc_points": false, "start_lvls": 200, "player_class": "Pawn_II", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 2}, # 2 Bots for testing
	
	"FFA": { "game_type": "FFA", "arena_size": 6000.0, "food_per_player": 7500, "bots_per_player": 20, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # Large game FFA
	"2T": { "game_type": "2_Teams", "arena_size": 6000.0, "food_per_player": 7500, "bots_per_player": 20, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # Large game 2 teams
	
	"FFA-L": { "game_type": "FFA", "arena_size": 12000.0, "food_per_player": 12000, "bots_per_player": 40, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3}, # Large game FFA
	"2T-L": { "game_type": "2_Teams", "arena_size": 12000.0, "food_per_player": 12000, "bots_per_player": 40, "bot_classes": ["Pawn", "Pawn_I"], "npc_points": true, "start_lvls": 0, "player_class": "Pawn", "player_levels_for_upgrade": 1, "player_levels_for_promotion": 3} # Large game 2 teams
}

var leaderboard_timer: float = 0.0

var arena_size: float = 2500.0
var top_left_x: float = -arena_size/2
var top_left_y: float = -arena_size/2
var bottom_left_x: float = arena_size/2

var food_per_player: int = 1500
var max_food: int = 0

var bots_per_player: int = 0
var max_bots: int = 0
var npc_gains_points: bool = true
var bot_spawn_classes: Array = ["Pawn"]

#TODO add to presets
var npc_levels_for_promotion: int = 3
var npc_levels_for_upgrade: int = 1

var player_levels_at_start: int = 0
var player_starts_as: String = "Pawn"
var player_levels_for_upgrade: int = 1
var player_levels_for_promotion: int = 2

var game_type: String = "2_Teams"

# Stores authoritative usernames mapped to integer peer IDs.
var player_names_dict: Dictionary = {}

# Connects buttons and initializes the game boundary
func _ready() -> void:
	$TitleScreen/HostPanel/HostButton.pressed.connect(_on_host_pressed)
	$TitleScreen/HostPanel/HostOPButton.pressed.connect(_on_host_OP_pressed)
	$TitleScreen/JoinPanel/JoinButton.pressed.connect(_on_join_pressed)
	respawn_button.pressed.connect(_on_respawn_pressed)
	$RespawnLayer.hide()
	ip_label.hide()

# Parses the preset input field and applies matching or custom settings.
func _apply_preset_or_custom() -> void:
	var input: String = $TitleScreen/HostPanel/Preset.text.strip_edges()
	if input == "":
		input = "Alone"
	var parts: Array = input.split(",")
	print("GAME PRESETS: " + str(parts))
	# If a single token matches a preset key, apply it directly
	if parts.size() == 1 and PRESETS.has(parts[0].strip_edges()):
		var preset: Dictionary = PRESETS[parts[0].strip_edges()]
		print(str(preset))
		game_type        = preset["game_type"]
		arena_size       = preset["arena_size"]
		food_per_player  = preset["food_per_player"]
		bots_per_player  = preset["bots_per_player"]
		bot_spawn_classes = preset["bot_classes"]
		npc_gains_points = preset["npc_points"]
		player_levels_at_start = preset["start_lvls"]
		player_starts_as = preset["player_class"]
		player_levels_for_upgrade = preset["player_levels_for_upgrade"]
		player_levels_for_promotion = preset["player_levels_for_promotion"]
		return

	# Otherwise expect: game_type, arena_size, food_per_player, bots_per_player
	if parts.size() != 5:
		printerr("Preset input must be a preset number or 5 comma-separated values.")
		return

	game_type       = parts[0].strip_edges()
	arena_size      = float(parts[1].strip_edges())
	food_per_player = int(parts[2].strip_edges())
	bots_per_player = int(parts[3].strip_edges())
	bot_spawn_classes = Array(parts[4].strip_edges())
	npc_gains_points = bool(parts[5].strip_edges())

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
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			continue
		var leveling_comp: Node = player.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": player.player_username, "score": leveling_comp.total_score, "team_id": player.team_id})
	
	for npc: Node in $SpawnedNPCs.get_children():
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		var leveling_comp: Node = npc.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": npc.name, "score": leveling_comp.total_score, "team_id": npc.team_id})
	
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	
	var lb_data_slice: Array = []
	for i: int in range(min(scores.size(), 10)):
		lb_data_slice.append(scores[i])
		
	update_leaderboard_rpc.rpc(lb_data_slice)

# Sends the leaderboard list to players
@rpc("authority", "call_local", "unreliable")
func update_leaderboard_rpc(leaderboard_data: Array) -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node = $SpawnedPlayers.get_node_or_null(local_id)
	
	if local_player:
		var ui_comp: Node = local_player.get_node_or_null("UIComponent")
		if ui_comp and ui_comp.has_method("update_leaderboard_ui"):
			ui_comp.update_leaderboard_ui(leaderboard_data)

# Creates the boundry walls of the arena
func _create_boundaries() -> void:
	
	top_left_x = -arena_size/2
	top_left_y = -arena_size/2
	bottom_left_x = arena_size/2
	
	var rects: Array = [
		Rect2(top_left_x - 50, top_left_y - 50, arena_size + 100, 50),  # Top wall
		Rect2(top_left_x - 50, bottom_left_x, arena_size + 100, 50),    # Bottom wall
		Rect2(top_left_x - 50, top_left_y, 50, arena_size),             # Left wall
		Rect2(top_left_x + arena_size, top_left_y, 50, arena_size)      # Right wall
	]
	
	for rect: Rect2 in rects:
		$SpawnedTraps.spawn_wall(rect)
		

func _on_host_OP_pressed() -> void:
	# Run the UPNP port forwarding before starting the server
	setup_upnp()
	_on_host_pressed() 

# Initiates the server and spawns the host player
func _on_host_pressed() -> void:
	peer.create_server(PORT) 
	multiplayer.multiplayer_peer = peer
		
	var username: String = $TitleScreen/JoinPanel/UsernameInput.text
	register_player_name(username)
	
	
	# Set up the game
	_apply_preset_or_custom()
	$TitleScreen.hide()
	_create_boundaries()
	$Tiles.size = Vector2(arena_size, arena_size)
	$Tiles.position = Vector2(-arena_size/2, -arena_size/2)
	is_hosting = true	
	new_player_joined()
	
	# Spawn the host
	#multiplayer.peer_connected.connect($SpawnedPlayers.add_player)
	# Host spawning is manually handled to ensure peer ID 1 is used.
	$SpawnedPlayers.add_player(1)

# Attempts to automatically forward the game port on the host's router.
func setup_upnp() -> void:
	var upnp: UPNP = UPNP.new()
	
	# Ask the network to find the local router (This will be blocked by many networks)
	var discover_result: int = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed! Error: %s" % discover_result)
		ip_label.text = "UPNP Discover Failed! Error: %s" % discover_result
		return

	# Verify the router is a valid gateway that accepts commands
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		print("UPNP Invalid Gateway!")
		ip_label.text = "UPNP Invalid Gateway!"
		return

	# Ask the router to open the UDP port (ENet uses UDP)
	var map_result: int = upnp.add_port_mapping(PORT, PORT, "My Godot Game", "UDP")
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed! Error: %s" % map_result)
		ip_label.text = "UPNP Port Mapping Failed! Error: %s" % map_result
		return
		
	# Prints the public IP so the host can share it
	print("UPNP Success! Port %s is open." % PORT)
	print("Your public IP to give to friends is: %s" % upnp.query_external_address())
	ip_label.text = "Your public IP to give to friends is: %s" % upnp.query_external_address()
	
	ip_label.show()

# Attempts to connect to a server IP
func _on_join_pressed() -> void:
	var username: String = $TitleScreen/JoinPanel/UsernameInput.text
	var ip_to_join: String = $TitleScreen/JoinPanel/InputIP.text
	if ip_to_join == "":
		ip_to_join = "127.0.0.1"
		
	peer.create_client(ip_to_join, PORT)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(func() -> void:
		register_player_name.rpc_id(1, username)
		new_player_joined()
	)
	
	$TitleScreen.hide()

# Increases the food and bots supply when a new player joins
func new_player_joined():
	max_food += food_per_player
	max_bots += bots_per_player

# Records the player's score on the server and initiates the spectate sequence for the client.
func player_died(player_id: String, player_score: int, killer_id: String) -> void:
	# Records score on the server for the upcoming respawn request.
	if multiplayer.is_server():
		dead_scores_dict[player_id] = player_score
	
	# Commands the local client to initiate spectating.
	start_spectating.rpc_id(player_id.to_int(), killer_id)

# Commands the local client's UI and camera to enter the spectate phase.
@rpc("authority", "call_local", "reliable")
func start_spectating(killer_id: String) -> void:
	$RespawnLayer.show()
	respawn_button.hide()
	respawn_label.show()
	respawn_timer = 4.0
	
	# Swap the active camera to the main scene's spectator camera
	spectator_camera.enabled = true
	spectator_camera.make_current()

	# Attempt to find the killer. If environmental or missing, the camera stays where the player died.
	if killer_id != "":
		var killer_node: CharacterBody2D = $SpawnedPlayers.get_node_or_null(killer_id)
		if not killer_node:
			killer_node = $SpawnedNPCs.get_node_or_null(killer_id)
		if not killer_node:
			var npcs_to_spectate: Array = $SpawnedNPCs.get_children()
			if npcs_to_spectate.size() <= 0:
				printerr("No one to specate")
			else:
				killer_node = npcs_to_spectate[0]
		if killer_node:
			spectate_target = killer_node
			# Snap the camera to the killer immediately so it doesn't drag across the entire map
			spectator_camera.global_position = spectate_target.global_position

# Hides the button locally and asks the server for a new body.
func _on_respawn_pressed() -> void:
	spectate_target = null
	respawn_button.hide()
	$RespawnLayer.hide()
	request_respawn.rpc_id(1)

# Handles the server-side logic for cleaning up the dead body and spawning a new entity with the saved score.
@rpc("any_peer", "call_local", "reliable")
func request_respawn() -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	var player_key: String = str(sender_id)
	var old_player: Node = $SpawnedPlayers.get_node_or_null(player_key)
	
	# Renames and frees the old node immediately to start the network deletion process.
	if is_instance_valid(old_player):
		old_player.name = player_key + "_dying_" + str(Time.get_ticks_msec())
		old_player.queue_free()
	
	# Delays the new spawn by a few frames to ensure the MultiplayerSpawner clears the previous node name.
	get_tree().create_timer(0.1).timeout.connect(func() -> void: _execute_respawn_spawn(sender_id))

# Registers a player's cosmetic name and triggers the spawning process on the server.
@rpc("any_peer", "call_local", "reliable")
func register_player_name(username: String) -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	# The technical ID is 1 for the host; handle local calls that might return 0.
	if sender_id == 0:
		sender_id = 1
		
	var final_name: String = username.strip_edges()
	if final_name == "":
		final_name = "Guest_" + str(sender_id)
	
	player_names_dict[sender_id] = final_name
	
	# Clients are spawned only after their name is authoritatively registered.
	if sender_id != 1:
		$SpawnedPlayers.add_player(sender_id)

# Finalizes the respawn by instantiating the new player and restoring their authoritative score.
func _execute_respawn_spawn(id: int) -> void:
	var player_key: String = str(id)
	if dead_scores_dict.has(player_key):
		var previous_score: int = dead_scores_dict[player_key]
		$SpawnedPlayers.add_player(id, previous_score)
		dead_scores_dict.erase(player_key)
	else:
		$SpawnedPlayers.add_player(id)
