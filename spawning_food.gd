extends Node2D

@export var food_scene: PackedScene = preload("res://food.tscn")

var spawn_timer: float = 0.0

# Handles the dynamic spawning interval for food entities
func _process(delta: float) -> void:
	# Validates that the Main node is loaded
	if owner == null:
		return
		
	if owner.is_hosting:
		spawn_timer -= delta
		
		if spawn_timer <= 0 and get_child_count() < owner.max_food:
			_spawn_random_food()
			
			# Calculates a dynamic spawn rate based on current food density
			var current_food: float = max(get_child_count(), 1.0)
			spawn_timer = 20.0 / (float(owner.max_food) / current_food)

# Spawns a new food entity at a random location within the boundaries
func _spawn_random_food() -> void:
	var food_instance: Node = food_scene.instantiate()
	
	food_instance.position = Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
	add_child(food_instance, true)
