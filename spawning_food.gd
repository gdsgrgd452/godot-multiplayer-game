extends MultiplayerSpawner

@export var food_scene: PackedScene = preload("res://food.tscn")

var spawn_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta):
	# 3. CHANGE THIS IF STATEMENT
	# Now, only the window that actually clicked "Host" will run this code.
	if owner == null:
		return
	if owner.is_hosting:
		spawn_timer -= delta
		
		if spawn_timer <= 0 and get_child_count() < owner.max_food:
			_spawn_random_food()
			spawn_timer = 20/(owner.max_food/max(get_child_count(), 1))
			print(spawn_timer)

func _spawn_random_food():
	var food_instance = food_scene.instantiate()
	# Spread the food out across the new massive map
	food_instance.position = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
	food_instance.shape_type = randi() % 3 
	add_child(food_instance, true)
