extends Node2D

@export var food_scene: PackedScene = preload("res://food.tscn")

var spawn_timer = 0.0

func _process(delta):
	# 1. Safety check: Ensure the Main node is fully loaded before we check its variables
	if owner == null:
		return
		
	# 2. Only the host server should spawn food
	if owner.is_hosting:
		spawn_timer -= delta
		
		# 3. Check if we have room for more food
		if spawn_timer <= 0 and get_child_count() < owner.max_food:
			_spawn_random_food()
			
			# Dynamic timer: Spawns faster when there is less food, slower when it's almost full
			# Using float() to ensure smooth division and prevent integer truncation
			var current_food = max(get_child_count(), 1.0)
			spawn_timer = 20.0 / (float(owner.max_food) / current_food)
			print("Next food in: ", spawn_timer, " seconds")

func _spawn_random_food():
	var food_instance = food_scene.instantiate()
	
	# Spread the food out across the massive map
	food_instance.position = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
	food_instance.shape_type = randi() % 3 
	
	# Add the food as a child of this Node2D container
	add_child(food_instance, true)
