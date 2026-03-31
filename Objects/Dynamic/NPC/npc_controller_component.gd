extends Node2D
class_name NPCControllerComponent

@export var give_up_attack_time: float = 30.0 # For attacking
@onready var npc: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node2D = npc.get_node("Components/MovementComponent")
@onready var detection_area: Area2D = npc.get_node("DetectionArea")
@onready var health_comp: Node2D = npc.get_node("Components/HealthComponent")
@onready var kill_zone: Area2D = npc.get_node("KillArea")

var curr_class: String = "Pawn"
var state: String = "Wander"

#View distances


#Score
var my_score: int = 0

#Fleeing
var threat: Node2D = null
var flee_target: Vector2 = Vector2.ZERO # Position to flee to
var is_fleeing: bool = false
var last_threat_pos: Vector2 = Vector2.ZERO
var flee_timer: float = 0.0
var flee_distance: float = 100.0

#Wanderng
var wander_target: Vector2 = Vector2.ZERO # Position to wander to
var wander_radius: float = 1000.0

#Combat
@onready var max_shoot_range: float = detection_area.get_node("DetectionHitbox").shape.radius * 0.9 * npc.global_scale.x # They can shoot nearly as far as they can see
@onready var min_shoot_range: float = max_shoot_range * 0.2
@onready var melee_range: float = 280.0 * npc.global_scale.x
var current_target: Node2D = null
var move_target:Vector2 = Vector2.ZERO  # The position to re-position to
var boldness_factor: float = 1.0 # Only runs away from things more than n * npc's score
var kindness_factor: float = 1.0 # Doesnt go for things less than n * npc's score
var health_scale: float = 1.0

#Chasing
var give_up_chase_time: float = 3.0 # For chasing
var target_out_of_range_timer: float = 5.0
var blacklisted_target: Node2D = null # Target you have just chased and failed to catch, to prevent constantly trying to chase the same target
var blacklist_timer: float = 0.0
var last_dist_to_target: float = INF # For checking if you are getting closer/further in a chase

#Input delay
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
	kindness_factor = randf_range(0.01, 0.2) 
	give_up_chase_time = randf_range(1.0, 3.0)
	inp_delay = randf_range(0.2, 0.6)
	inp_delay_timer = inp_delay


# Orchestrates the NPC decision-making loop, prioritizing flee persistence and combat state transitions.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	inp_delay_timer -= delta
	if inp_delay_timer > 0.0:
		return
	inp_delay_timer = inp_delay

	curr_class = npc.current_class
	health_scale = health_comp.health/health_comp.max_health
	
	my_score = TargetingUtils.get_entity_score(npc)
	threat = _get_dangerous_threat() # Gets the most dangerous threat 

	# Always try to clear blacklist. 
	_clear_blacklist(delta)
	
	# If you are a spawner try and spawn towers
	if curr_class == "Rook" or curr_class == "Rook_Knight" or curr_class == "King_Rook" or curr_class == "Sultan":
		_spawn_towers()
	
	if threat:
		_last_stand()

		# Stats and handles fleeing from threats, If you are still fleeing or have found something new to flee from > Do nothing else
		if state != "Last Stand" and _process_fleeing():
			return

	# # In case the blacklister target no longer exist
	var safe_exclude: Node2D = blacklisted_target if is_instance_valid(blacklisted_target) else null
	
	# # Handles targeting and re targeting to higher priority targets. New target found/ Switched Targets > Do nothing else
	var best_visible_target: Node2D = TargetingUtils.get_closest_enemy(npc.global_position, detection_area, npc.team_id, false, my_score, safe_exclude)
	if best_visible_target != null and _process_targeting(best_visible_target):
		return

	# # If there is a target to go for, look into combat options
	var in_combat: bool = false
	if is_instance_valid(current_target) and not current_target.is_queued_for_deletion():
		in_combat = _process_combat_state(current_target, delta)

	 # If there is nothing else to do, wander around
	if not in_combat:
		_process_wander_state()

# Spawn towers 
func _spawn_towers():
	var spawn_comp: SpawnerComponent = npc.get("first_ability_component")
	if is_instance_valid(spawn_comp) and spawn_comp.current_cooldown <= 0.0:
		spawn_comp.request_spawn.rpc(npc.global_position)
		#print("NPC spawned tower")
		return true
	return false

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
func _get_dangerous_threat() -> Node2D:
	var highest_threat: Node2D = null
	var highest_threat_rating: float = 0.0
	
	for body: Node2D in detection_area.get_overlapping_bodies():
		
		# Only consider players and NPCs
		if not body.is_in_group("player") and not body.is_in_group("npc"):
			continue
		
		# Only consider enemies on a different team
		if not "team_id" in body or body.get("team_id") == npc.team_id:
			continue
		
		var enemy_score: int = TargetingUtils.get_entity_score(body)
		
		var weighted_boldness_threshold: float = my_score * boldness_factor * health_scale
		
		# Only consider entities that are actually a threat (higher score than our threashold)
		if enemy_score <= weighted_boldness_threshold:
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
		var threat_rating: float = (score_difference / distance) / health_scale
		
		if threat_rating > highest_threat_rating:
			highest_threat_rating = threat_rating
			highest_threat = body
			#print("New highest threat: %s | score diff: %d | distance: %.1f | rating: %.2f" % [body.name, score_difference, distance, threat_rating])
	
	return highest_threat

# Handles taking final stands when being hunted down
func _last_stand() -> void:
	var active_melee: MeleeWeaponComponent = npc.get("melee_w_component")
	var active_ranged: RangedWeaponComponent = npc.get("ranged_w_component")
	
	if threat in kill_zone.get_overlapping_bodies():
		state = "Last Stand"
		
		if is_instance_valid(active_ranged):
			_action_ranged(active_ranged, threat)
			
		if active_melee != null and active_melee.can_attack:
			active_melee.request_melee_attack(threat.global_position)


# Handles whether to keep fleeing, is far enough away - stop
func _process_fleeing() -> bool:

	if is_instance_valid(threat):
		last_threat_pos = threat.global_position
		flee_timer = 3.0
		
		var active_ranged: RangedWeaponComponent = npc.get("ranged_w_component")
		if is_instance_valid(active_ranged):
			_action_ranged(active_ranged, threat)
			
		if curr_class == "Shadow_Knight" and _action_stealth():
			return true
		elif (curr_class == "Jester" or curr_class == "Holy_Queen") and _action_illusion():
			return true
		_action_flee(last_threat_pos)
		return true
	
	if flee_timer > 0.0:
		flee_timer -= get_physics_process_delta_time()
		_action_flee(last_threat_pos)
		if flee_timer <= 0.0:
			is_fleeing = false
		return true
		
	return false

func _action_stealth() -> bool:
	var stealth_comp = npc.get_node_or_null("Components/StealthComponent")
	if stealth_comp.current_cooldown <= 0.0:
		print("NPC requesting Stealth")
		stealth_comp.request_stealth.rpc()
		return true
	return false

func _action_illusion() -> bool:
	var illusion_comp = npc.get_node_or_null("Components/IllusionComponent")
	if illusion_comp.current_cooldown <= 0.0:
		print("NPC requesting Illusion")
		illusion_comp.request_scattered_illusions.rpc()
		return true
	return false

# ACTION
# Flee away from a threat and sets the fleeing state (Also handles repositioning)
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
func _process_targeting(best_visible_target: Node2D) -> bool:
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
	
	_update_chase_timers(delta, dist)
	
	var active_melee: MeleeWeaponComponent = npc.get("melee_w_component")
	var active_ranged: RangedWeaponComponent = npc.get("ranged_w_component")

	# Logic for melee attacks: Stop and swing if in range
	if is_instance_valid(active_melee):
		if dist <= melee_range: 
			state = "Melee_Attack"
			move_comp.set_movement_direction(Vector2.ZERO)
			_action_melee(active_melee, target)
			return true
		
		# If melee only, we must continue chasing
		if not is_instance_valid(active_ranged):
			state = "Chasing"
			_move_towards(npc.global_position, target.global_position)
			move_comp.set_movement_direction(npc.global_position.direction_to(target.global_position))
			return true
	
	if is_instance_valid(active_ranged):
		# Buffer zones to prevent jittering during repositioning
		var reposition_threshold = min_shoot_range * 0.95
		
		if dist <= max_shoot_range:
			_action_ranged(active_ranged, target)
		
		if dist < reposition_threshold: #and not target.is_in_group("food"):
			state = "Repositioning"
			_action_reposition(target.global_position)
			return true
		elif dist > max_shoot_range:
			state = "Chasing"
			_move_towards(npc.global_position, target.global_position)
			move_comp.set_movement_direction(npc.global_position.direction_to(target.global_position))
			return true
		else:
			# Valid range for shooting: Stop moving
			state = "Ranged_Attack"
			move_comp.set_movement_direction(Vector2.ZERO)
			return true

	return false

# Handles chasing 
func _update_chase_timers(delta: float, dist: float) -> void:
	state = "Chasing"
	
	# Reset the timer if the NPC is getting closer, otherwise decrement
	if dist < last_dist_to_target:
		target_out_of_range_timer = give_up_chase_time
	elif not current_target.is_in_group("food"):
		target_out_of_range_timer -= delta

	last_dist_to_target = dist

	if target_out_of_range_timer <= 0.0: # Blacklist the target if it gets away
		blacklisted_target = current_target
		blacklist_timer = 5.0
		current_target = null 
		target_out_of_range_timer = give_up_chase_time
		last_dist_to_target = INF

# ACTION
# Stops moving and tries to request melee attacks
func _action_melee(active_melee: MeleeWeaponComponent, target: Node2D) -> void:
	state = "Melee_Attack"
	if active_melee.can_attack:
		active_melee.request_melee_attack(target.global_position)

# ACTION
# Stops moving and tries to request ranged attacks
func _action_ranged(active_ranged: RangedWeaponComponent, target: Node2D) -> void:
	if active_ranged.shot_cooldown <= 0.0:
		active_ranged.shoot(target.global_position)

# ACTION
# Moves away if too close whilst shooting
func _action_reposition(from_pos: Vector2):
	state = "Repositioning"
	
	var move_dir: Vector2 = from_pos.direction_to(npc.global_position)
	var probe_pos = npc.global_position + (move_dir * 50.0)
	
	# Clamp the flee target within map boundaries to prevent logic loops at map edges.
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, probe_pos):
		move_dir = Vector2(-move_dir.y, move_dir.x)
	
	move_comp.set_movement_direction(move_dir)

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
# Updates the NPC's movement direction based on the high-level NPC state and context-aware steering.
func _move_towards(pos: Vector2, t_pos: Vector2) -> bool:
	var dist: float = pos.distance_to(t_pos)
	var arrival_threshold: float = 120.0
	var min_speed_ratio: float = 0.2
	if state == "Chasing" or state == "Melee_Attack":
		move_comp.speed_limit_multiplier = clamp(dist / arrival_threshold, min_speed_ratio, 1.0)
	else:
		move_comp.speed_limit_multiplier = 1.0
		
	return true

# Provides the raw heading toward the current target for the context steering system.
func get_desired_direction() -> Vector2:
	# Moving away from a target
	if state == "Fleeing" and last_threat_pos != Vector2.ZERO:
		return last_threat_pos.direction_to(npc.global_position)
		
	if state == "Repositioning" and is_instance_valid(current_target):
		return current_target.global_position.direction_to(npc.global_position)
	
	# Stop steering rays if we are currently in an attack state to stand ground
	if state in ["Ranged_Attack", "Melee_Attack"]:
		return Vector2.ZERO

	# Moving towards a target
	if is_instance_valid(current_target):
		return global_position.direction_to(current_target.global_position)
		
	if state == "Wandering" and wander_target != Vector2.ZERO:
		return global_position.direction_to(wander_target)
		
	return Vector2.ZERO

func _draw() -> void:
	var active_ranged: Node = npc.get("ranged_w_component")
	if is_instance_valid(active_ranged):
		draw_circle(Vector2.ZERO, max_shoot_range, Color(1.0, 0.0, 0.0, 0.1), false, 10.0)
		draw_circle(Vector2.ZERO, max_shoot_range, Color(1.0, 0.0, 0.0, 0.1), false, 10.0)
