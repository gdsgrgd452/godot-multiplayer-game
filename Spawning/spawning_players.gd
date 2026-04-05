extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")


# Instantiates a player node using the technical peer ID as its unique name.
func add_player(id: int, start_score: int = 0) -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player_instance.name = str(id) 
	
	# Retrieves the cosmetic name from the registry and applies it to the instance.
	if owner.player_names_dict.has(id):
		player_instance.player_username = owner.player_names_dict[id]
	else:
		player_instance.player_username = "Guest_" + str(id)
	
	var arena_half: float = owner.arena_size / 2.0 - 50.0
	player_instance.position = Vector2(randf_range(-arena_half, arena_half), randf_range(-arena_half, arena_half))
	
	if start_score > 0: # Gives the player score when they start
		player_instance.ready.connect(func() -> void: _apply_start_score(player_instance, start_score))
	
	match owner.game_type:
		"FFA":
			player_instance.team_id = 1 if id == 1 else get_child_count() + 1
		"2_Teams":
			player_instance.team_id = 1 if id == 1 else (get_child_count() % 2) + 1 #TODO change this to be fair
	
	printerr("REAL NAME: " + str(player_instance.name))
	printerr("Username: " + player_instance.player_username)
	add_child(player_instance, true)

# Grants the previous score back
func _apply_start_score(player: CharacterBody2D, points: int) -> void:
	var level_comp: Node = player.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp) and level_comp.has_method("get_points"):
		level_comp.get_points(points)
