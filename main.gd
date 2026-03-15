extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene = preload("res://player.tscn")
@export var bullet_scene: PackedScene = preload("res://bullet.tscn")

@export var max_food = 0
var bullet_counter = 0 # NEW: Keeps bullet names strictly unique
@export var is_hosting: bool = false 

func _ready():
	$CanvasLayer/HostButton.pressed.connect(_on_host_pressed)
	$CanvasLayer/JoinButton.pressed.connect(_on_join_pressed)
	_create_boundaries()

func _create_boundaries():
	var boundary_body = StaticBody2D.new()
	boundary_body.add_to_group("boundary") # Tag it so the player knows what it hit
	
	# Define 4 walls (Top, Bottom, Left, Right) to frame the -2500 to 2500 map
	var rects = [
		Rect2(-2550, -2550, 5100, 50), # Top wall
		Rect2(-2550, 2500, 5100, 50),  # Bottom wall
		Rect2(-2550, -2500, 50, 5000), # Left wall
		Rect2(2500, -2500, 50, 5000)   # Right wall
	]
	
	for rect in rects:
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		# Rect sizes grow from the center in Godot 4, so we offset the position
		collision.position = rect.position + (rect.size / 2.0)
		boundary_body.add_child(collision)
		
	add_child(boundary_body)
	
func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	
	_add_player(multiplayer.get_unique_id())
	$CanvasLayer.hide()
	
	# 2. TURN ON SPAWNING ONLY FOR THE TRUE HOST
	is_hosting = true 

func _on_join_pressed():
	peer.create_client("127.0.0.1", 135)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	# The client NEVER sets is_hosting to true!

func _add_player(id):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id) 
	
	# Spawn players anywhere between -2000 and 2000 on both axes
	var random_x = randf_range(-2000, 2000)
	var random_y = randf_range(-2000, 2000)
	player_instance.position = Vector2(random_x, random_y)
	
	$SpawnedPlayers.add_child(player_instance, true)
	
	# Update the max food
	max_food = $SpawnedPlayers.get_child_count()*250

# --- NEW FUNCTION FOR BULLETS ---
func spawn_bullet(spawn_pos: Vector2, dir: Vector2, shooter_id: String):
	if multiplayer.is_server():
		var bullet = bullet_scene.instantiate()
		
		bullet_counter += 1
		bullet.name = "Bullet_" + str(bullet_counter)
		
		# Spawn it slightly in front of the player so it doesn't get stuck inside them
		bullet.position = spawn_pos + (dir * 30) 
		bullet.direction = dir
		bullet.shooter_id = shooter_id
		
		$SpawnedBullets.add_child(bullet, true)
