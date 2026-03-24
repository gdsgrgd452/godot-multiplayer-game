extends Node2D

@export var food_scene: PackedScene = preload("res://Objects/Static/Food/food.tscn")

var spawn_timer: float = 0.0
@onready var arena_size: float = owner.arena_size - 25

# Handles the dynamic spawning interval for food entities exclusively on the server.
func _process(delta: float) -> void:
	if owner == null:
		return
	
	if multiplayer.is_server():
		spawn_timer -= delta
		
		if spawn_timer <= 0.0 and get_child_count() < owner.max_food:
			try_spawn_food()
			
			var current_food: float = max(float(get_child_count()), 1.0)
			spawn_timer = 20.0 / (float(owner.max_food) / current_food)

# Attempts to find a valid spawn position using rejection sampling with a fixed maximum attempt limit.
func try_spawn_food() -> void:
	var max_attempts: int = 7
	var attempts: int = 0
	var success: bool = false
	
	while attempts < max_attempts and not success:
		var attempted_position: Vector2 = Vector2(randf_range(-arena_size/2, arena_size/2), randf_range(-arena_size/2, arena_size/2))
		
		if randf() < get_spawn_probability(attempted_position):
			_spawn_food(attempted_position)
			success = true
		attempts += 1
		
	#print("Attempts: " + str(attempts))

# Calculates a normalized spawn probability that decreases as the distance from the center origin increases.
func get_spawn_probability(food_pos: Vector2) -> float:
	var current_distance: float = food_pos.length()
	var normalized_distance: float = clampf(current_distance / arena_size, 0.0, 1.0)
	var probability: float = 1.2 - normalized_distance
	
	return probability
	
# Instantiates and places a new food entity, calculating its distance modifier.
func _spawn_food(food_pos: Vector2) -> void:
	var food_instance: Node2D = food_scene.instantiate() as Node2D
	food_instance.position = food_pos
	
	food_instance.distance_factor = clampf(food_pos.length() / arena_size, 0.0, 1.0)
	
	add_child(food_instance, true)
