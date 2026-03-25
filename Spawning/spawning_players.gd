extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")


func add_player(id: int) -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player_instance.name = str(id) 
	
	var random_x: float = randf_range(-300, 300)
	var random_y: float = randf_range(-300, 300)
	player_instance.position = Vector2(random_x, random_y)
	
	# FFA
	player_instance.team_id = 1 if id == 1 else get_child_count() + 1

	# 2 teams
	#player_instance.team_id = 1 if id == 1 else (get_child_count() % 2) + 1
	
	add_child(player_instance, true)
	
	if owner != null:
		owner.max_food = get_child_count() * owner.food_per_player
		owner.max_bots = get_child_count() * owner.bots_per_player
