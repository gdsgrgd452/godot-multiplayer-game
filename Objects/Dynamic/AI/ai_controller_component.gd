extends Node2D
class_name AIControllerComponent

@export var attack_range: float = 400.0
@export var wander_radius: float = 1000.0
@export var melee_range: float = 70.0
@export var give_up_time: float = 5.0

var wander_target: Vector2 = Vector2.ZERO
var state: String = "Wander"

@onready var npc: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node = npc.get_node("Components/MovementComponent")
@onready var detection_area: Area2D = npc.get_node("DetectionArea")

var current_target: Node2D = null
var target_out_of_range_timer: float = 5.0
var blacklisted_target: Node2D = null
var blacklist_timer: float = 0.0
var last_dist_to_target: float = INF

# Orchestrates the AI decision-making loop, handling flee responses, target persistence timers, and combat states.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if blacklist_timer > 0.0:
		blacklist_timer -= delta
		if blacklist_timer <= 0.0:
			blacklisted_target = null
		
	var my_score: int = TargetingUtils.get_entity_score(npc)
	var threat: Node2D = _get_dangerous_threat(my_score)
	
	if is_instance_valid(threat):
		_process_flee_state(threat)
		current_target = null
		target_out_of_range_timer = give_up_time
		last_dist_to_target = INF
		return

	var best_visible: Node2D = TargetingUtils.get_closest_enemy(npc.global_position, detection_area, npc.team_id, false, my_score, blacklisted_target)

	if is_instance_valid(current_target) and current_target.is_inside_tree() and current_target in detection_area.get_overlapping_bodies() and current_target != blacklisted_target: # If the current target is still there, in the area and in the scene
		if is_instance_valid(best_visible) and TargetingUtils.get_priority(best_visible) > TargetingUtils.get_priority(current_target): # If the best visible is valid and has a higher priority than the current target
			current_target = best_visible
			target_out_of_range_timer = give_up_time
			last_dist_to_target = INF
	else:
		current_target = best_visible
		target_out_of_range_timer = give_up_time
		last_dist_to_target = INF
	
	if is_instance_valid(current_target):
		_process_combat_state(current_target, delta)
	else:
		_process_wander_state()

# Finds for any nearby enemy entities with a score higher than the NPC's own score and returns the one with the highest score 
func _get_dangerous_threat(my_score: int) -> Node2D:
	var highest_threat: Node2D = null
	var max_detected_score: int = my_score
	for body: Node2D in detection_area.get_overlapping_bodies():
		if "team_id" in body and body.get("team_id") != npc.team_id:
			if body.is_in_group("player"): #or body.is_in_group("npc"):
				var enemy_score: int = TargetingUtils.get_entity_score(body)
				if enemy_score > max_detected_score:
					max_detected_score = enemy_score
					highest_threat = body
					print("Found player threat")
	return highest_threat

# Directs the NPC to move away from a identified high-score threat while remaining within map boundaries.
func _process_flee_state(threat: Node2D) -> void:
	var flee_dir: Vector2 = threat.global_position.direction_to(npc.global_position)
	var target_pos: Vector2 = npc.global_position + (flee_dir * 100.0)
	
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, target_pos):
		var perpendicular: Vector2 = Vector2(-flee_dir.y, flee_dir.x)
		target_pos = npc.global_position + (perpendicular * 100.0)
		if not AbilityUtils.is_position_within_map(get_tree().current_scene, target_pos):
			target_pos = npc.global_position - (perpendicular * 100.0)

	move_comp.set_movement_direction(npc.global_position.direction_to(target_pos))

# Handles autonomous movement logic when no enemies are detected.
func _process_wander_state() -> void:
	if wander_target == Vector2.ZERO or npc.global_position.distance_to(wander_target) < 10.0:
		wander_target = _get_valid_wander_pos()
	
	var dir: Vector2 = npc.global_position.direction_to(wander_target)
	move_comp.set_movement_direction(dir)

# Attempts to calculate a random destination within the wander radius that resides inside the map boundaries.
func _get_valid_wander_pos() -> Vector2:
	var max_attempts: int = 15
	var scene: Node = get_tree().current_scene
	
	for i: int in range(max_attempts):
		var angle: float = randf() * TAU
		var random_offset: Vector2 = Vector2(cos(angle), sin(angle)) * wander_radius
		var potential_target: Vector2 = npc.global_position + random_offset
		
		if AbilityUtils.is_position_within_map(scene, potential_target):
			return potential_target
			
	return npc.global_position

# Evaluates targets and manages the progress-based abandonment timer while executing combat logic.
func _process_combat_state(target: Node2D, delta: float) -> void:
	var dist: float = npc.global_position.distance_to(target.global_position)
	var active_ranged: RangedWeaponComponent = npc.get("ranged_w_component")
	var active_melee: MeleeWeaponComponent = npc.get("melee_w_component")
	
	# Reset the timer if the AI is getting closer to the target, otherwise decrement towards abandonment.
	if dist < last_dist_to_target:
		target_out_of_range_timer = give_up_time
	else:
		target_out_of_range_timer -= delta
		
	last_dist_to_target = dist

	if target_out_of_range_timer <= 0.0: # Gives up on trying to chase something 
		blacklisted_target = target
		blacklist_timer = 5.0
		current_target = null
		target_out_of_range_timer = give_up_time
		last_dist_to_target = INF
		return

	if is_instance_valid(active_melee) and dist <= melee_range:
		move_comp.set_movement_direction(Vector2.ZERO)
		if active_melee.can_attack:
			active_melee.request_melee_attack(target.global_position)
		return

	if not is_instance_valid(active_ranged):
		var dir: Vector2 = npc.global_position.direction_to(target.global_position)
		move_comp.set_movement_direction(dir)
		return
	
	if dist <= attack_range:
		move_comp.set_movement_direction(Vector2.ZERO)
		if active_ranged.shot_cooldown <= 0.0:
			active_ranged.shoot(target.global_position)
	else:
		var dir: Vector2 = npc.global_position.direction_to(target.global_position)
		move_comp.set_movement_direction(dir)
