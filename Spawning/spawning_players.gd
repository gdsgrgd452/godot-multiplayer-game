extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")


# Instantiates a player node using the technical peer ID as its unique name.
func add_player(id: int) -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player_instance.name = str(id) 
	
	# Retrieves the cosmetic name from the registry and applies it to the instance.
	print(str(owner.player_names_dict))
	print(player_instance.name)
	if owner.player_names_dict.has(id):
		player_instance.player_username = owner.player_names_dict[id]
	else:
		player_instance.player_username = "Guest_" + str(id)
	
	var arena_half: float = owner.arena_size / 2.0 - 50.0
	player_instance.position = Vector2(randf_range(-arena_half, arena_half), randf_range(-arena_half, arena_half))
	
	match owner.game_type:
		"FFA":
			player_instance.team_id = 1 if id == 1 else get_child_count() + 1
		"2_Teams":
			player_instance.team_id = 1 if id == 1 else (get_child_count() % 2) + 1
	
	printerr("REAL NAME: " + str(player_instance.name))
	printerr("Username: " + player_instance.player_username)
	add_child(player_instance, true)
