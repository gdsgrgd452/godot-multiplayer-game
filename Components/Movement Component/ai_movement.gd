extends Node2D

@export var move_speed: int = 100
@export var acceleration: float = 300.0
@export var friction: float = 1800.0

var movement_blocked: bool = false
var current_velocity: Vector2 = Vector2.ZERO
var speed_limit_multiplier: float = 1.0

var directions: Array[Vector2] = []
var interest: Array[float] = []
var danger: Array[float] = []
var context_dir: Vector2 = Vector2.ZERO

var entity_radius: float = 50.0 

const NUM_RAYS: int = 32
const MAX_DETECTION_DIST: float = 600.0

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var looking_area: Area2D = entity.get_node("LookingArea") as Area2D
@onready var ai_controller: AIControllerComponent = entity.get_node("Components/AIControllerComponent") as AIControllerComponent

# Initializes the 16-direction arrays for context mapping.
func _ready() -> void:
	for i: int in range(NUM_RAYS):
		var angle: float = i * TAU / NUM_RAYS
		directions.append(Vector2.RIGHT.rotated(angle))
		interest.append(0.0)
		danger.append(0.0)

# Calculates the movement velocity, prioritizing friction-based braking when approaching a target.
func get_movement_velocity(delta: float) -> Vector2:
	if movement_blocked:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		return current_velocity
		
	_compute_context_steering(delta)
	
	var target_speed: float = float(move_speed) * speed_limit_multiplier
	var target_velocity: Vector2 = context_dir * target_speed
	
	# Selects friction for braking if the target speed is lower than current momentum.
	var force_to_apply: float = acceleration
	if current_velocity.length() > target_speed or target_speed == 0.0:
		force_to_apply = friction
	
	if context_dir.length() > 0.0 and target_speed > 0.0:
		current_velocity = current_velocity.move_toward(target_velocity, force_to_apply * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		
	return current_velocity

# Evaluates steering maps and applies a hard-stop multiplier based on the controller's equipment ranges.
func _compute_context_steering(delta: float) -> void:
	var desired_dir: Vector2 = ai_controller.get_desired_direction()
	var obstacles: Array[Node2D] = looking_area.get_overlapping_bodies()
	
	var forward_danger: float = 0.0
	var avoidance_speed_mult: float = 1.0
	var target_arrival_mult: float = 1.0
	
	# Reference existing controller ranges for tactical stopping distances.
	var arrival_threshold: float = 100.0
	var stop_threshold: float = 0
	
	# Determines the stopping distance based on whether the AI is engaging in melee or ranged combat.
	if is_instance_valid(entity.get("melee_w_component")):
		stop_threshold = ai_controller.melee_range
	elif is_instance_valid(entity.get("ranged_w_component")):
		stop_threshold = ai_controller.attack_range
	else:
		stop_threshold = 60.0 # Default fallback for body damage/contact
	
	# Maps the interest based on the controller's desired heading.
	for i: int in range(NUM_RAYS):
		interest[i] = max(0.0, directions[i].dot(desired_dir))
		danger[i] = 0.0

	# Manages deceleration and hard-stopping based on distance to the active target.
	if is_instance_valid(ai_controller.current_target):
		var dist_to_target: float = entity.global_position.distance_to(ai_controller.current_target.global_position)
		
		# If within the tactical range, kill interest and movement immediately.
		if dist_to_target < stop_threshold:
			target_arrival_mult = 0.0
			for i: int in range(NUM_RAYS):
				interest[i] = 0.0
		else:
			# Scale speed down as the NPC enters the arrival threshold.
			target_arrival_mult = clamp((dist_to_target - stop_threshold) / (arrival_threshold - stop_threshold), 0.0, 1.0)

	for body: Node2D in obstacles:
		if body == entity:
			continue
			
		var to_obstacle: Vector2 = body.global_position - global_position
		var dist: float = to_obstacle.length()
		var dir_to_obstacle: Vector2 = to_obstacle.normalized()
		
		var danger_weight: float = 1.5 if body.is_in_group("boundary") else 1.0
		var danger_arc: float = atan2(entity_radius, max(dist, 1.0))

		for i: int in range(NUM_RAYS):
			var angle_to_ray: float = abs(directions[i].angle_to(dir_to_obstacle))
			
			if angle_to_ray < danger_arc:
				var proximity_weight: float = 1.0 - (dist / MAX_DETECTION_DIST)
				danger[i] = max(danger[i], proximity_weight * danger_weight)
				
				if directions[i].dot(context_dir) > 0.9:
					forward_danger = max(forward_danger, danger[i])

	if forward_danger > 0.85:
		avoidance_speed_mult = lerp(1.0, 0.2, (forward_danger - 0.85) * 8.0)

	speed_limit_multiplier = min(avoidance_speed_mult, target_arrival_mult)

	var chosen_dir: Vector2 = Vector2.ZERO
	for i: int in range(NUM_RAYS):
		var score: float = interest[i] - danger[i]
		chosen_dir += directions[i] * max(0.0, score)
	
	if chosen_dir != Vector2.ZERO:
		context_dir = context_dir.lerp(chosen_dir.normalized(), delta * 18.0).normalized()
		looking_area.rotation = context_dir.angle()

# Virtual function maintained for compatibility with AI state transitions.
func set_movement_direction(_dir: Vector2) -> void:
	pass
