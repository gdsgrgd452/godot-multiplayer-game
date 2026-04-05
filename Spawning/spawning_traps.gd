extends Node2D

@export var tower_scene: PackedScene = preload("res://Objects/Dynamic/Spawnables/mini_rook_tower.tscn")
@export var wof_scence: PackedScene = preload("res://Objects/Dynamic/Spawnables/wof.tscn")
@export var wall_scence: PackedScene = preload("res://Objects/Static/Wall/wall.tscn")

# Instantiates a tower on the server and configures its initial state for synchronization.
func spawn_tower(spawn_pos: Vector2, owner_id: String, team: int) -> Node2D:
	if not multiplayer.is_server():
		return null
		
	var tower: StaticBody2D = tower_scene.instantiate() as StaticBody2D
	
	# Ensures the node name is unique so the MultiplayerSpawner can track it across peers
	tower.name = "Tower_" + str(owner_id) + "_" + str(Time.get_ticks_msec())
	tower.global_position = spawn_pos
	
	# Assign the team_id property directly to the script before adding to tree
	# This helps server-side NPC logic immediately recognize it as a teammate
	if "team_id" in tower:
		tower.team_id = team
	
	add_child(tower)
	
	if tower.has_method("initialise"):
		tower.initialise(owner_id, team)
		
	return tower
	
# Instantiates a WOF on the server and configures its initial state for synchronization.
func spawn_wof(start_pos: Vector2, end_pos: Vector2, owner_id: String, team: int) -> Node2D:
	if not multiplayer.is_server():
		return null
		
	var wall: Area2D = wof_scence.instantiate() as Area2D
	wall.name = "WOF_" + str(owner_id) + "_" + str(Time.get_ticks_msec()) # Unique name assigned
	
	# Assign the team_id property directly to the script before adding to tree
	# This helps server-side NPC logic immediately recognize it as a teammate
	if "team_id" in wall:
		wall.team_id = team
	
	add_child(wall, true)
	
	if wall.has_method("initialise"):
		print("Init wall")
		wall.initialise(owner_id, team, start_pos, end_pos)
		
	return wall

# Spawns a black boundry wall with a hitbox
func spawn_wall(rect: Rect2):
	
	var wall: StaticBody2D = wall_scence.instantiate() as StaticBody2D
	wall.name = "ARENA_WALL_" + str(Time.get_ticks_msec()) + str(randi_range(0,999))
	
	wall.collision_layer = 2
	wall.collision_mask = 0
	
	
	var collision: CollisionShape2D = wall.get_node_or_null("Hitbox")
	var shape: RectangleShape2D = collision.shape
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.position + (rect.size / 2.0)
	wall.add_child(collision)
	
	var visual: Polygon2D = wall.get_node_or_null("Colour")
	var half = rect.size / 2.0
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	visual.position = rect.position + half
	
	add_child(wall)
	
