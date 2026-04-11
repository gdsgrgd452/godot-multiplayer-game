extends Node2D
class_name CombatBrain

@onready var main_brain: MainBrain = get_parent().get_node("MainBrain") as MainBrain
@onready var move_comp: Node2D = main_brain.npc.get_node("Components/MovementComponent")
@onready var kill_zone: Area2D = main_brain.npc.get_node("KillArea") as Area2D
@onready var active_melee: MeleeWeaponComponent = main_brain.npc.get("melee_w_component")
@onready var active_ranged: RangedWeaponComponent = main_brain.npc.get("ranged_w_component")

# Ranges
var melee_range: float = 110.0
var comfortable_melee_range: float = 75
var max_shoot_range: float = 300.0
var min_shoot_range: float = 150.0

# Factors that affect whether to take a fight
var kindness_factor: float = 1.0 
var hits_to_kill_to_target: int = 5

var current_target: Node2D = null
var current_targets_priority: int = 0
var combat_state: String = ""
var blacklisted_target: Node2D = null 
var blacklist_timer: float = 0.0
var last_dist_to_target: float = INF 

var target_out_of_range_timer: float = 5.0 # TODO

var give_up_attack_time: float = 30.0 # TODO

var nearby_food_count: int = 0

func _ready() -> void:
	kindness_factor = randf_range(0.01, 0.2)
	hits_to_kill_to_target = randi_range(1, 10)

# Re target to higher priority targets, or get new target from the best visible ones
func _process_targeting(all_targets: Dictionary) -> bool:
	var players: Dictionary = {}
	var npcs: Dictionary = {}
	var food: Dictionary = {}
	var towers: Dictionary = {}
	
	# Sorts potential targets by type
	for target_name: String in all_targets:
		var target_info: Dictionary = all_targets[target_name]
		var type: String = target_info.get("type", "unknown")
		
		# Sets the default priority based on type
		target_info.set("priority", TargetingUtils.get_priority(target_info.get("entity")))
		
		match type:
			"player":
				players[target_name] = target_info
			"npc":
				npcs[target_name] = target_info
			"food":
				food[target_name] = target_info
			"tower":
				towers[target_name] = target_info
	
	nearby_food_count = food.size()
		
	#print("Players: " + str(players))
	#print("NPCs: " + str(npcs))
	#print("Food: " + str(food))
	
	_update_weapons()
	
	#Filters for players/NPCs with too low a score
	for dict in [players, npcs]:
		for key in dict:
			var potential_target: Dictionary = dict.get(key)
			
			if main_brain.my_score * main_brain.kindness_factor > potential_target.get("score"): # Skips players or nps with a much lower score
				potential_target.set("priority", -1)
				continue
			
			if potential_target.get("entity") in kill_zone.get_overlapping_bodies(): # Always goes for ones in the kill zone
				potential_target.set("priority", 100)
				continue
			
			if TargetingUtils.less_than_x_hits_to_kill(hits_to_kill_to_target, potential_target.get("health"), active_melee, active_ranged): # If it is low health increase the priority
				potential_target.set("priority", potential_target.get("priority") + 30)
	
	#Filters to not go for food too big for it
	for f in food:
		var food_to_check: Dictionary = food.get(f)
		if not TargetingUtils._is_food_accessible(food_to_check.get("entity"), 0):
			if TargetingUtils.less_than_x_hits_to_kill(hits_to_kill_to_target, food_to_check.get("health"), active_melee, active_ranged): # If the thing is low health make an exception and increase the priority
				food_to_check.set("priority", food_to_check.get("priority") + 19) 
				#print("Low food found")
			else:
				food_to_check.set("priority", -1) 
	
	# Finds the highest priority potential target around
	var best_potential_target: Dictionary
	var highest_priority: int = 0
	for dict in [players, npcs, food, towers]:
		for key in dict:
			var potential_target_info: Dictionary = dict.get(key)
			var target_priority: int = potential_target_info.get("priority")
			#print("Target: " + str(potential_target_info.get("entity")) + " Priority: " + str(target_priority))
			if target_priority > highest_priority:
				best_potential_target = potential_target_info
				highest_priority = target_priority
				
			# If there is already a best potential target and another has the same priority
			elif not best_potential_target.is_empty() and not potential_target_info.is_empty() and target_priority == highest_priority:
				if potential_target_info.get("distance") < best_potential_target.get("distance"):
					#print("Same priority, defaulting to closest")
					best_potential_target = potential_target_info
					highest_priority = target_priority
				#print("NEW TARGET HAS BEST PRIORITY: " + str(target_priority))
	
	#print("Best pri: " + str(current_targets_priority) + " Curr pri: " + str(highest_priority))
	# There is still a current target with better priority
	if is_instance_valid(current_target):
		if highest_priority <= current_targets_priority:
			return false
		
	# If there is a new found highest priority potential target, make it the current target
	if best_potential_target:
		current_target = best_potential_target.get("entity")
		current_targets_priority = highest_priority
		#print("New curr pri: " + str(current_targets_priority))
		target_out_of_range_timer = 3.0
		last_dist_to_target = INF
		return true
	else:
		return false

	
	
# Handles taking final stands when being hunted down
func _last_stand(threat: Node2D) -> bool:
	if threat in kill_zone.get_overlapping_bodies():
		current_target = threat
		_update_weapons()
		_ranged_attack(threat, false)
		_melee_attack(threat, false)
		#print(combat_state, str(threat.get_groups()))
		if combat_state in ["Melee_Attack", "Ranged_Attack", "Ranged_Attack-TC", "Chasing"]:
			return true
	return false

# Evaluates targets and manages the progress-based abandonment timer while executing combat logic.
func _process_combat_state(delta: float) -> bool:
	_update_chase_timers(delta)
	_update_weapons()
	#print("Processing combat with: " + str(current_target.get_groups()[0]))
	_melee_attack(current_target)
	_ranged_attack(current_target)
	if combat_state in ["Melee_Attack", "Ranged_Attack", "Ranged_Attack-TC", "Chasing"]:
		return true
	else:
		return false

# Tries to do a melee attack
func _melee_attack(target: Node2D, chase: bool = true) -> bool:
	if is_instance_valid(active_melee) and is_instance_valid(target):
		#print("Trying to melee")
		var dist: float = main_brain.npc.global_position.distance_to(target.global_position)
		# If in range, stop moving, set state and request an attack
		if dist <= melee_range:
			combat_state = "Melee_Attack"
			move_comp.set_movement_direction(Vector2.ZERO)
			if active_melee.can_attack: 
				active_melee.request_melee_attack(target.global_position)
			if dist <= comfortable_melee_range: # Moves towards if they are in the outer part of the melee range
				move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
		elif chase:
			#If not in range, chase the target
			combat_state = "Chasing"
			move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
	return false


# Trie to do a ranged attack
func _ranged_attack(target: Node2D, chase: bool = true) -> bool:
	if is_instance_valid(active_ranged) and is_instance_valid(target):
		#print("Trying to ranged")
		var dist: float = main_brain.npc.global_position.distance_to(target.global_position)

		if dist <= max_shoot_range:
			active_ranged.look_at(target.global_position)
			move_comp.set_movement_direction(Vector2.ZERO)
			
			# If the weapon is not busy charging, start a new attack cycle
			if not active_ranged.get("is_charging"):
				active_ranged.request_start_charge()
			
			combat_state = "Ranged_Attack"
			
			if dist <= min_shoot_range:
				combat_state = "Ranged_Attack-TC"
			return true
		elif chase:
			# Out of range, chase
			combat_state = "Chasing"
			move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
	return false

# Handles chasing 
func _update_chase_timers(delta: float) -> void:
	var dist: float = main_brain.npc.global_position.distance_to(current_target.global_position)
	if dist < last_dist_to_target:
		target_out_of_range_timer = 3.0
	elif not current_target.is_in_group("food"):
		target_out_of_range_timer -= delta
	last_dist_to_target = dist
	if target_out_of_range_timer <= 0.0:
		blacklisted_target = current_target
		blacklist_timer = 5.0
		current_target = null 

# Clears the blacklisted targets
func _clear_blacklist(delta: float) -> void:
	if blacklist_timer > 0.0:
		blacklist_timer -= delta
		if blacklist_timer <= 0.0: blacklisted_target = null

func _update_weapons() -> void:
	active_melee = main_brain.npc.get("melee_w_component")
	if main_brain.npc.current_melee_weapon == "Spear":
		melee_range = 110.0
	elif main_brain.npc.current_melee_weapon == "Sword":
		melee_range = 95.0
	active_ranged = main_brain.npc.get("ranged_w_component")

#func _draw() -> void:


# # ACTION
# # Moves away if too close whilst shooting
# func _action_reposition(from_pos: Vector2) -> void:
# 	var move_dir: Vector2 = from_pos.direction_to(main_brain.npc.global_position)
# 	var probe_pos: Vector2 = main_brain.npc.global_position + (move_dir * 50.0)
# 	if not AbilityUtils.is_position_within_map(get_tree().current_scene, probe_pos):
# 		move_dir = Vector2(-move_dir.y, move_dir.x)
# 	main_brain.move_comp.set_movement_direction(move_dir)
