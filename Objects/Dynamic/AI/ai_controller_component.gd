extends Node2D
class_name AIControllerComponent



@export var give_up_attack_time: float = 30.0 # For attacking
@onready var npc: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node = npc.get_node("Components/MovementComponent")
@onready var detection_area: Area2D = npc.get_node("DetectionArea")

var state: String = "Wander"

#Fleeing
var flee_target: Vector2 = Vector2.ZERO # Position to flee to
var is_fleeing: bool = false
var last_threat_pos: Vector2 = Vector2.ZERO
var flee_timer: float = 0.0
var flee_distance: float = 50.0

#Wanderng
var wander_target: Vector2 = Vector2.ZERO # Position to wander to
var wander_radius: float = 1000.0

#Combat
var attack_range: float = 400.0
var melee_range: float = 70.0
var current_target: Node2D = null
var boldness_factor: float = 1.0 # Only runs away from things more than n * npc's score
var kindness_factor: float = 1.0 # Doesnt go for things less than n * npc's score

#Chasing
var give_up_chase_time: float = 3.0 # For chasing
var target_out_of_range_timer: float = 5.0
var blacklisted_target: Node2D = null # Target you have just chased and failed to catch, to prevent constantly trying to chase the same target
var blacklist_timer: float = 0.0
var last_dist_to_target: float = INF # For checking if you are getting closer/further in a chase

#TODO
var inp_delay: float = 1.0 # Delay in taking actions
var inp_delay_timer: float = 1.0 
var action_to_take: bool = false

# PRIORITY ORDER - IMPORTANT DO NOT REMOVE
# Start Fleeing and flee from threats (Shoot back at them if possible) (Check for distance is closing / already too close > Attack)
# TODO Check if target is in range > Yes, shoot (R)
# Find targets 
# Chase if not in range

func _ready() -> void:
	boldness_factor = randf_range(0.5, 10.0) 
	kindness_factor = randf_range(0.1, 0.4) 
	give_up_chase_time = randf_range(1.0, 3.0)

# Orchestrates the AI decision-making loop, prioritizing flee persistence and combat state transitions.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	var my_score: int = TargetingUtils.get_entity_score(npc)
	var threat: Node2D = _get_dangerous_threat(my_score) # Gets the most dangerous threat 

	npc.get_node("State").text = state + " B:" + str(snapped(boldness_factor,0.01)) + " K:" + str(snapped(kindness_factor,0.01)) + " S:" + str(my_score) + "G_C:" + str(snapped(give_up_chase_time,0.01))
	


	# Always try to clear blacklist. 
	_clear_blacklist(delta)

	# Stats and handles fleeing from threats, If you are still fleeing or have found something new to flee from > Do nothing else
	if _process_fleeing(threat):
		return
		
	# Create a safe reference that is guaranteed to be either a valid Node2D or null to satisfy the static type checker.
	var safe_exclude: Node2D = blacklisted_target if is_instance_valid(blacklisted_target) else null
	
	# Handles targeting and re targeting to higher priority targets. New target found/ Switched Targets > Do nothing else
	var best_visible_target: Node2D = TargetingUtils.get_closest_enemy(npc.global_position, detection_area, npc.team_id, false, my_score, safe_exclude)
	
	if best_visible_target != null and _process_targeting(best_visible_target, my_score):
		return
	
	# If there is a target to go for, look into combat options
	var in_combat: bool = false
	if is_instance_valid(current_target) and not current_target.is_queued_for_deletion():
		in_combat = _process_combat_state(current_target, delta)

	 # If there is nothing else to do, wander around
	if not in_combat:
		_process_wander_state()

# Clears the blacklisted targets
func _clear_blacklist(delta) -> void:
	if blacklisted_target != null and not is_instance_valid(blacklisted_target): # Unblacklist a target if it is removed
		blacklisted_target = null
		blacklist_timer = 0.0
		return

	if blacklist_timer > 0.0:
		blacklist_timer -= delta
		if blacklist_timer <= 0.0:
			blacklisted_target = null

# Finds the most imminent threat among nearby enemies, weighted by distance and score.
# Distance is more important
func _get_dangerous_threat(my_score: int) -> Node2D:
	var highest_threat: Node2D = null
	var highest_threat_rating: float = 0.0
	
	for body: Node2D in detection_area.get_overlapping_bodies():
		# Only consider enemies on a different team
		if not "team_id" in body or body.get("team_id") == npc.team_id:
			continue
		
		# Only consider players and NPCs
		if not body.is_in_group("player") and not body.is_in_group("npc"):
			continue
		
		var enemy_score: int = TargetingUtils.get_entity_score(body)
		
		# Only consider entities that are actually a threat (higher score than us)
		if enemy_score <= my_score * boldness_factor:
			continue
		
		# How much stronger the enemy is than us — larger gap = more dangerous
		var score_difference: float = float(enemy_score - my_score)
		
		# How far away the enemy is — closer = more dangerous
		var distance: float = npc.global_position.distance_to(body.global_position)
		
		# Avoid division by zero if somehow overlapping exactly
		if distance < 1.0:
			distance = 1.0
		
		# Threat rating formula:
		# - Dividing score_difference by distance means close enemies rank much higher
		# - The further away an enemy is, the less their score advantage matters
		# - Example: score_diff=500, distance=100  -> rating=5.0  (close, very dangerous)
		# - Example: score_diff=500, distance=1000 -> rating=0.5  (far, less urgent)
		# - Example: score_diff=100, distance=50   -> rating=2.0  (close, moderately dangerous)
		var threat_rating: float = score_difference / distance
		
		if threat_rating > highest_threat_rating:
			highest_threat_rating = threat_rating
			highest_threat = body
			#print("New highest threat: %s | score diff: %d | distance: %.1f | rating: %.2f" % [body.name, score_difference, distance, threat_rating])
	
	return highest_threat

# Handles whether to keep fleeing, is far enough away 
func _process_fleeing(threat: Node2D) -> bool:
	
	if is_instance_valid(threat): # If there is a threat, flee
		last_threat_pos = threat.global_position
		flee_timer = 3.0
		_action_flee(last_threat_pos)
		return true
	
	if flee_timer > 0.0: # No threat but still fleeing
		#print("Fleeing after away from threat")
		flee_timer -= get_physics_process_delta_time()
		_action_flee(last_threat_pos)
		if flee_timer <= 0.0: # Fleeing finishes
			is_fleeing = false
		return true
		
	return false

# ACTION
# Flee away from a threat and sets the fleeing state
func _action_flee(from_pos: Vector2) -> void:
	state = "Fleeing"
	is_fleeing = true
	current_target = null # No targeting whilst fleeing
	target_out_of_range_timer = give_up_chase_time
	last_dist_to_target = INF
	
	var flee_dir: Vector2 = from_pos.direction_to(npc.global_position)
	var potential_flee_target: Vector2 = npc.global_position + (flee_dir * flee_distance)
	
	# Clamp the flee target within map boundaries to prevent logic loops at map edges.
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, potential_flee_target):
		var perpendicular: Vector2 = Vector2(-flee_dir.y, flee_dir.x)
		potential_flee_target = npc.global_position + (perpendicular * flee_distance)
		
		if not AbilityUtils.is_position_within_map(get_tree().current_scene, potential_flee_target): # So if at map edge tries to go right/left
			potential_flee_target = npc.global_position - (perpendicular * flee_distance)

	flee_target = potential_flee_target
	var direction_to_target: Vector2 = (flee_target - npc.global_position).normalized()
	
	move_comp.set_movement_direction(direction_to_target)

# Re target to higher priority targets, or get new target from the best visible ones
func _process_targeting(best_visible_target: Node2D, my_score: int) -> bool:
	var current_target_viable: bool = is_instance_valid(current_target) and current_target.is_inside_tree() and current_target in detection_area.get_overlapping_bodies() and current_target != blacklisted_target
	
	var target_points: int = TargetingUtils.get_entity_score(best_visible_target)
	
	if my_score * kindness_factor > target_points and target_points != 0: # Ignores low score players due to kindness
		return false
		
	#print("NPC has higher score accounted: " + )
	# If there is a current target check if the new one is better (If it is switch)
	if current_target_viable:
		var visible_target_viable: bool = is_instance_valid(best_visible_target) and TargetingUtils.get_priority(best_visible_target) > TargetingUtils.get_priority(current_target)
		
		if visible_target_viable: # Switch to a better target
			current_target = best_visible_target
			#print("Switching to new target: " + str(current_target.name))
			target_out_of_range_timer = give_up_chase_time
			last_dist_to_target = INF
			return true

	else: # The current target is not viable, Take the best visible one
		
		current_target = best_visible_target
		#print("Assigned new target: " + str(current_target.name))
		target_out_of_range_timer = give_up_chase_time
		last_dist_to_target = INF
		return true

	return false # No new target/ target not switched

# Evaluates targets and manages the progress-based abandonment timer while executing combat logic.
func _process_combat_state(target: Node2D, delta: float) -> bool:
	var dist: float = npc.global_position.distance_to(target.global_position)
	
	# If the target has escaped, return 
	if _process_chasing(delta, dist):
		return true
	
	var active_melee: MeleeWeaponComponent = npc.get("melee_w_component")
	var active_ranged: RangedWeaponComponent = npc.get("ranged_w_component")
	
	if is_instance_valid(active_melee) and is_instance_valid(active_ranged): # Melee and Ranged (Currently defaults to ranged)
		if dist <= attack_range: # In Range, fire
			_action_ranged(active_ranged, target)
			return true
		else: # Out of range
			if _move_towards(npc.global_position, target.global_position):
				return true
	elif is_instance_valid(active_melee): # Has Melee 
		if dist <= melee_range: # In Melee Range, attack
			_action_melee(active_melee, target)
			return true
		else: # Out of Melee Range
			if _move_towards(npc.global_position, target.global_position):
				return true
	elif is_instance_valid(active_ranged): # Has ranged
		if dist <= attack_range: # In Range, fire
			_action_ranged(active_ranged, target)
			return true
		else: # Out of range
			if _move_towards(npc.global_position, target.global_position):
				return true
	return false

# Handles chasing (True if the target escapes > No longer there)
func _process_chasing(delta: float, dist: float) -> bool:
	state = "Chasing"
	
	
	# Reset the timer if the AI is getting closer to the target, otherwise decrement towards abandonment.
	if dist < last_dist_to_target:
		target_out_of_range_timer = give_up_chase_time
	elif not current_target.is_in_group("food"):
		target_out_of_range_timer -= delta

	last_dist_to_target = dist

	if target_out_of_range_timer <= 0.0: # The target has escaped, reset chase stats
		#print("Giving up")
		blacklisted_target = current_target # Blacklist the target to avoid chasing them again for a while
		blacklist_timer = 5.0
		current_target = null 
		target_out_of_range_timer = give_up_chase_time
		last_dist_to_target = INF
		return true
	return false

# ACTION
# Stops moving and tries to request melee attacks
func _action_melee(active_melee: MeleeWeaponComponent, target: Node2D) -> void:
	state = "Melee_Attack"
	move_comp.set_movement_direction(Vector2.ZERO) # TODO change this to strafing or something
	if active_melee.can_attack:
		#print("Can Melee attack, Requesting attack")
		active_melee.request_melee_attack(target.global_position)

# ACTION
# Stops moving and tries to request ranged attacks
func _action_ranged(active_ranged: RangedWeaponComponent, target: Node2D) -> void:
	state = "Ranged_Attack"
	move_comp.set_movement_direction(Vector2.ZERO) # TODO change this to strafing or something
	if active_ranged.shot_cooldown <= 0.0:
		#print("Can Ranged attack, Requesting attack")
		active_ranged.shoot(target.global_position)

# Wanders to a random position
func _process_wander_state() -> bool:
	if wander_target == Vector2.ZERO or npc.global_position.distance_to(wander_target) < 50.0:
		wander_target = _get_valid_wander_pos()
		#print("Wandering to: " + str(wander_target))
	
	if _move_towards(npc.global_position, wander_target):
		state = "Wandering"
		return true
	return false

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

# ACTION
# Moves towards a direction
func _move_towards(pos: Vector2, t_pos: Vector2) -> bool:
	var direction_to_target: Vector2 = (t_pos - pos).normalized()
	move_comp.set_movement_direction(direction_to_target)
	return true
