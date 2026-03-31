extends Node2D

@export var tower_scene: PackedScene = preload("res://Objects/Dynamic/Spawnables/mini_rook_tower.tscn")
@export var wof_scence: PackedScene = preload("res://Objects/Dynamic/Spawnables/wof.tscn")


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
	
	add_child(tower, true)
	
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
