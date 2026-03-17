extends Node2D

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
const PORT: int = 8910

# These are our shared variables that the child spawners read/write
@export var max_food: int = 0
@export var is_hosting: bool = false 

# Connects buttons and initializes the game boundary
func _ready() -> void:
	$CanvasLayer/HostButton.pressed.connect(_on_host_pressed)
	$CanvasLayer/JoinButton.pressed.connect(_on_join_pressed)
	_create_boundaries()

# Sets up walls around the arena
func _create_boundaries() -> void:
	var boundary_body: StaticBody2D = StaticBody2D.new()
	boundary_body.add_to_group("boundary")
	
	var rects: Array = [
		Rect2(-2550, -2550, 5100, 50),
		Rect2(-2550, 2500, 5100, 50),  
		Rect2(-2550, -2500, 50, 5000), 
		Rect2(2500, -2500, 50, 5000)   
	]
	
	for rect in rects:
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.position + (rect.size / 2.0)
		boundary_body.add_child(collision)
		
	add_child(boundary_body)
	
# Initiates the server and spawns the host player
func _on_host_pressed() -> void:
	peer.create_server(PORT) 
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect($SpawnedPlayers.add_player)
	$SpawnedPlayers.add_player(multiplayer.get_unique_id())
	
	$CanvasLayer.hide()
	is_hosting = true 

# Attempts to connect to a server IP
func _on_join_pressed() -> void:
	# Grab the text from the new LineEdit node
	var ip_to_join: String = $CanvasLayer/LineEdit.text
	
	# If the box is empty, default back to local testing!
	if ip_to_join == "":
		ip_to_join = "127.0.0.1"
		
	# Connect using the dynamic IP and new port
	peer.create_client(ip_to_join, PORT)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
