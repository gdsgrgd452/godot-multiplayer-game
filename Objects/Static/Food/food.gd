extends CharacterBody2D

@onready var health_component: Node = $Components/HealthComponent

var knockback: Vector2 = Vector2.ZERO
var weight: int = 1
var distance_factor: float = 0.0
@export var points_value: int
var team_id: int = 999

const LAYER_NPC_PLAYER_AND_FOOD: int = 1
const LAYER_WORLD_BOUNDARIES: int = 2

@export var shape_type: String = "":
	set(value):
		shape_type = value
		if shape_type == "Decagon":
			scale = Vector2(1.5, 1.5)
		else:
			scale = Vector2(1.0, 1.0)
		queue_redraw()
		
# Sets up groups, signals, and server-side generation.
func _ready() -> void:
	add_to_group("food")
	add_to_group("shield_blockable")
	health_component.died.connect(_on_food_died)

	collision_layer = LAYER_NPC_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_NPC_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	if multiplayer.is_server():
		set_type_and_health()
		
	queue_redraw()

# Assigns attributes based on the current shape or picks a random shape if none is assigned.
func set_type_and_health() -> void:
	if shape_type == "":
		var max_roll: float = lerpf(1.0, 0.90, distance_factor)
		var type_prop: float = randf() * max_roll
		
		if type_prop <= 0.4: 
			shape_type = "Circle"
		elif type_prop <= 0.7: 
			shape_type = "Triangle"
		elif type_prop <= 0.9: 
			shape_type = "Square"
		elif type_prop <= 0.95: 
			shape_type = "Hexagon"
		else:
			shape_type = "Decagon"

	_apply_stats_for_shape()

# Configures health, points, and weight based on the final shape_type string.
func _apply_stats_for_shape() -> void:
	var temp_health: int = 0
	
	match shape_type:
		"Circle":
			temp_health = 50
			points_value = randi_range(5, 25)
			weight = 1
		"Triangle":
			temp_health = 150
			points_value = randi_range(10, 100)
			weight = 2
		"Square":
			temp_health = 500
			points_value = randi_range(50, 500)
			weight = 3
		"Hexagon":
			temp_health = 2000
			points_value = randi_range(100, 10000)
			weight = 5
		"Decagon":
			temp_health = 50000
			points_value = randi_range(10000, 100000)
			weight = 30

	health_component.max_health = temp_health
	health_component.health = temp_health

# Draws the shape dynamically based on the shape_type string.
func _draw() -> void:
	if shape_type == "Circle":
		draw_circle(Vector2.ZERO, 15.0, Color.WHITE)
	elif shape_type == "Square":
		draw_rect(Rect2(-15.0, -15.0, 30.0, 30.0), Color.BLACK)
	elif shape_type == "Triangle": 
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, -15.0),
			Vector2(15.0, 15.0),
			Vector2(-15.0, 15.0)
		])
		draw_polygon(points, PackedColorArray([Color.GREEN_YELLOW]))
	elif shape_type == "Hexagon":
		var hex_points: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, -15.0),
			Vector2(13.0, -7.5),
			Vector2(13.0, 7.5),
			Vector2(0.0, 15.0),
			Vector2(-13.0, 7.5),
			Vector2(-13.0, -7.5)
		])
		draw_polygon(hex_points, PackedColorArray([Color.ORANGE]))
	elif shape_type == "Decagon":
		var decagon_points: PackedVector2Array = PackedVector2Array([
			Vector2(0.0, -15.0),
			Vector2(8.8, -12.1),
			Vector2(14.3, -4.6),
			Vector2(14.3, 4.6),
			Vector2(8.8, 12.1),
			Vector2(0.0, 15.0),
			Vector2(-8.8, 12.1),
			Vector2(-14.3, 4.6),
			Vector2(-14.3, -4.6),
			Vector2(-8.8, -12.1)
		])
		draw_polygon(decagon_points, PackedColorArray([Color.CRIMSON]))

# Moves the food and handles sliding server-side.
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		handle_knockback(delta)
		move_and_slide()
		handle_collisions()

# Handles knockback slowly decaying over time based on the entity's weight.
func handle_knockback(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500.0 * float(weight))
	velocity = knockback

# Bounces the food off other objects and passes bounce force to them.
func handle_collisions() -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var normal: Vector2 = collision.get_normal()
		knockback = knockback.bounce(normal)

# Accepts a physical push from an outside source.
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force

# Routes damage down to the health component.
func take_damage(amount: int, attacker_id: String = "") -> void:
	if multiplayer.is_server():
		health_component.take_damage(amount, attacker_id)

# Triggered when health hits 0 to clean up the entity.
func _on_food_died(attacker_id: String) -> void:
	KillingUtils.route_kill_credits_and_points(get_tree().current_scene, attacker_id, points_value)
	queue_free()
