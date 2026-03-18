extends CharacterBody2D

@onready var health_component: Node = $Components/HealthComponent

var knockback: Vector2 = Vector2.ZERO
var weight: int = 1
@export var points_value: int

@export var shape_type: String = "":
	set(value):
		shape_type = value
		# Scales up the decagons for everyone instantly upon network sync
		if shape_type == "Decagon":
			scale = Vector2(5, 5)
		else:
			scale = Vector2(1, 1)
		queue_redraw()
		
# Sets up groups, signals, and server-side generation
func _ready() -> void:
	add_to_group("food") 
	health_component.died.connect(_on_food_died)
	
	# Only the server should generate the random shape and health!
	if multiplayer.is_server():
		set_type_and_health()
		
	queue_redraw()

# Randomly assigns a shape, health, and point value based on probability
func set_type_and_health() -> void:
	var type_prop: float = randf()
	var temp_health: int = 0
	
	if (type_prop <= 0.4): 
		shape_type = "Circle"
		temp_health = 50
		points_value = randi_range(5, 25)
	elif (type_prop <= 0.7): 
		shape_type = "Square"
		temp_health = 150
		points_value = randi_range(10, 100)
		weight = 2
	elif (type_prop <= 0.9): 
		shape_type = "Triangle"
		temp_health = 500
		points_value = randi_range(50, 500)
		weight = 3
	elif (type_prop <= 0.95): 
		shape_type = "Hexagon"
		temp_health = 2000
		points_value = randi_range(100, 10000)
		weight = 5
	elif (type_prop <= 1):
		shape_type = "Decagon"
		temp_health = 200000
		points_value = randi_range(100000, 100000000)
	weight = 12
	
	health_component.max_health = temp_health
	health_component.health = temp_health

# Draws the shape dynamically based on the shape_type string
func _draw() -> void:
	if shape_type == "Circle":
		draw_circle(Vector2.ZERO, 15, Color.WHITE)
	elif shape_type == "Square":
		draw_rect(Rect2(-15, -15, 30, 30), Color.BLACK)
	elif shape_type == "Triangle": 
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(0, -15),   # Top
		 	Vector2(15, 15),   # Bottom Right
		 	Vector2(-15, 15)   # Bottom Left
		])
		draw_polygon(points, PackedColorArray([Color.GREEN_YELLOW]))
	elif shape_type == "Hexagon":
		var hex_points: PackedVector2Array = PackedVector2Array([
			Vector2(0, -15),    # Top
			Vector2(13, -7.5),  # Top Right
			Vector2(13, 7.5),   # Bottom Right
			Vector2(0, 15),     # Bottom
			Vector2(-13, 7.5),  # Bottom Left
			Vector2(-13, -7.5)  # Top Left
		])
		draw_polygon(hex_points, PackedColorArray([Color.ORANGE]))
	elif shape_type == "Decagon":
		var decagon_points: PackedVector2Array = PackedVector2Array([
			Vector2(0, -15),       # Top
			Vector2(8.8, -12.1),   # Top Right 1
			Vector2(14.3, -4.6),   # Top Right 2
			Vector2(14.3, 4.6),    # Bottom Right 1
			Vector2(8.8, 12.1),    # Bottom Right 2
			Vector2(0, 15),        # Bottom
			Vector2(-8.8, 12.1),   # Bottom Left 2
			Vector2(-14.3, 4.6),   # Bottom Left 1
			Vector2(-14.3, -4.6),  # Top Left 2
			Vector2(-8.8, -12.1)   # Top Left 1
		])
		draw_polygon(decagon_points, PackedColorArray([Color.CRIMSON]))

# Moves the food and handles sliding server-side
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		handle_knockback(delta)
		move_and_slide()
		handle_collisions()

# Handles knockback slowly decaying over time
func handle_knockback(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500 * weight)
	velocity = knockback

# Bounces the food off other objects and passes bounce force to them
func handle_collisions() -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		var normal: Vector2 = collision.get_normal()
		knockback = knockback.bounce(normal)
		
		if collider and collider.has_method("apply_bounce"):
			collider.apply_bounce(-normal * 250)

# Accepts a physical push from an outside source
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force

# Routes damage down to the health component
func take_damage(amount: int, attacker_id: String = "") -> void:
	if multiplayer.is_server():
		health_component.take_damage(amount, attacker_id)

# Triggered when health hits 0; cleans up the entity
func _on_food_died(attacker_id: String) -> void:
	give_points_on_death(attacker_id)
	queue_free()

# Gives points to the attacker (There should be one unless 2 foods bump into each other)
func give_points_on_death(attacker_id: String) -> void:
	if attacker_id != "":
		var attacker: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + attacker_id)
		if attacker and attacker.has_method("get_points_from_kill"):
			attacker.get_points_from_kill(points_value)
		else:
			printerr("No attacker id")
