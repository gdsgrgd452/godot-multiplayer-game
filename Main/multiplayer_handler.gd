extends Node
class_name MultiplayerHandler

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new() 
const PORT: int = 8910 

# Stores authoritative usernames mapped to integer peer IDs.
var player_names_dict: Dictionary = {}

@onready var main: Node = get_parent().get_parent()
@onready var ip_label: Label = main.get_node_or_null("OverlayLayer/SharingIPLabel")

func _ready() -> void:
	main.get_node_or_null("MultiplayerMenu/JoinButton").pressed.connect(join_game)


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
		main.get_node("SpawnedPlayers").add_player(sender_id)

# Attempts to automatically forward the game port on the host's router.
func setup_upnp() -> void:
	var upnp: UPNP = UPNP.new()
	
	# Ask the network to find the local router (This will be blocked by many networks)
	var discover_result: int = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		printerr("UPNP Discover Failed! Error: %s" % discover_result)
		ip_label.text = "Router Not Found! Error: %s" % discover_result
		return

	# Verify the router is a valid gateway that accepts commands
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		printerr("UPNP Router Invalid Gateway!")
		ip_label.text = "Your router is an Invalid Gateway!"
		return

	# Ask the router to open the UDP port (ENet uses UDP)
	var map_result: int = upnp.add_port_mapping(PORT, PORT, "My Godot Game", "UDP")
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed! Error: %s" % map_result)
		ip_label.text = "Port Mapping Failed! Error: %s" % map_result
		return
		
	# Prints the public IP so the host can share it
	print("UPNP Success! Port %s is open." % PORT)
	print("Your public IP to give to friends is: %s" % upnp.query_external_address())
	ip_label.text = "Your public IP to give to friends is: %s" % upnp.query_external_address()
	
	ip_label.show()

# Initiates the server and spawns the host player
func host_game() -> void:
	
	# Sets up the unpn first if it is an open port game
	if main.open_port:
		setup_upnp()
	else:
		ip_label.text = "Players on your local network can join"
		ip_label.show()
	
	peer.create_server(PORT) 
	multiplayer.multiplayer_peer = peer
		
	var username: String = main.temp_username
	register_player_name(username)
	
	new_player_joined()
	
	# Spawn the host
	main.get_node("SpawnedPlayers").add_player(1)

# Attempts to connect to a server IP
func join_game() -> void:
	var username: String = main.temp_username
	var ip_to_join: String = ip_label.text
	if ip_to_join == "":
		ip_to_join = "127.0.0.1"
		
	peer.create_client(ip_to_join, PORT)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(func() -> void:
		register_player_name.rpc_id(1, username)
		new_player_joined()
	)
	
# Increases the food and bots supply when a new player joins
func new_player_joined() -> void:
	main.setup_handler.max_food += main.setup_handler.food_per_player
	main.setup_handler.max_bots += main.setup_handler.bots_per_player
