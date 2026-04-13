extends Node2D

@export var move_speed: int = 100
@export var acceleration: float = 300.0
@export var friction: float = 1800.0

var movement_blocked: bool = false
var current_velocity: Vector2 = Vector2.ZERO

var directions: Array[Vector2] = []
var interest: Array[float] = []
var danger: Array[float] = []
var context_dir: Vector2 = Vector2.ZERO

var entity_radius: float = 50.0 

const NUM_RAYS: int = 32
const MAX_DETECTION_DIST: float = 600.0

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var looking_area: Area2D = entity.get_node("LookingArea") as Area2D
@onready var npc_brain: MainBrain = entity.get_node("BrainComponents/MainBrain") as MainBrain

# Initializes the 32-direction arrays for context mapping.
func _ready() -> void:
	for i: int in range(NUM_RAYS):
		var angle: float = i * TAU / NUM_RAYS
		directions.append(Vector2.RIGHT.rotated(angle))
		interest.append(0.0)
		danger.append(0.0)

# Calculates the movement velocity based on the current context steering direction.
func get_movement_velocity(delta: float) -> Vector2:
	if movement_blocked:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		return current_velocity
		
	_compute_context_steering(delta)
	
	var target_speed: float = float(move_speed)
	var target_velocity: Vector2 = context_dir * target_speed
	
	if context_dir.length() > 0.0:
		current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		
	return current_velocity

# Evaluates interest and danger maps to generate a collision-aware movement vector.
func _compute_context_steering(delta: float) -> void:
	var desired_dir: Vector2 = npc_brain.get_desired_direction()
	var obstacles: Array[Node2D] = looking_area.get_overlapping_bodies()
	
	# Maps the interest based on the controller's desired heading.
	for i: int in range(NUM_RAYS):
		interest[i] = max(0.0, directions[i].dot(desired_dir))
		danger[i] = 0.0

	# Maps environmental dangers to rays to influence the final steering direction.
	for body: Node2D in obstacles:
		if body == entity:
			continue
			
		var to_obstacle: Vector2 = body.global_position - global_position
		var dist: float = to_obstacle.length()
		var dir_to_obstacle: Vector2 = to_obstacle.normalized()
		
		var is_boundary: bool = body.is_in_group("boundary")
		var danger_weight: float = 4.0 if is_boundary else 1.0
		var danger_arc: float = atan2(entity_radius * (2.5 if is_boundary else 1.5), max(dist, 1.0))

		for i: int in range(NUM_RAYS):
			var angle_to_ray: float = abs(directions[i].angle_to(dir_to_obstacle))
			
			if angle_to_ray < danger_arc:
				var proximity_weight: float = 1.0 - (dist / MAX_DETECTION_DIST)
				danger[i] = max(danger[i], proximity_weight * danger_weight)

	# Harmonizes interest and danger maps into a single synchronized movement vector.
	var chosen_dir: Vector2 = Vector2.ZERO
	for i: int in range(NUM_RAYS):
		var score: float = interest[i] - danger[i]
		chosen_dir += directions[i] * max(0.0, score)
	
	if chosen_dir != Vector2.ZERO:
		context_dir = context_dir.lerp(chosen_dir.normalized(), delta * 18.0).normalized()
		looking_area.rotation = context_dir.angle()
	else:
		context_dir = Vector2.ZERO

# Virtual function maintained for compatibility with NPC state transitions.
func set_movement_direction(_dir: Vector2) -> void:
	pass
