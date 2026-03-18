extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")

const food_per_player: int = 500

# Spawns a newly connected player and updates the global food limit
func add_player(id: int) -> void:
	var player_instance: Node = player_scene.instantiate()
	player_instance.name = str(id) 
	
	var random_x: float = randf_range(-1000, 1000)
	var random_y: float = randf_range(-1000, 1000)
	player_instance.position = Vector2(random_x, random_y)
	
	add_child(player_instance, true)
	
	# Recalculates the food capacity based on the active player count
	if owner != null:
		owner.max_food = get_child_count() * food_per_player
