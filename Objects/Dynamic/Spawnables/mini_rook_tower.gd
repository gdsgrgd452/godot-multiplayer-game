extends StaticBody2D

var owner_peer_id: String = ""
var team_id: int = -1 

@onready var detection_area: Area2D = $Area2D
@onready var ranged_weapon: Node = $Components/BowComponent 
@onready var health_component: Node = $Components/HealthComponent

var current_target: Node2D 
var current_targets_priority: int = 0
var hits_to_kill_to_target: int = 3

# Sets the initial identity and team data
func initialise(creator_id: String, creator_team: int) -> void:
	owner_peer_id = creator_id
	team_id = creator_team
	$UI/TeamLabel.text = str(team_id)
	$UI/TeamLabel.add_theme_font_size_override("font_size", 40)
	add_to_group("tower")
	
	if not health_component.died.is_connected(on_tower_died):
		health_component.died.connect(on_tower_died)
	
	health_component.max_health = 100
	health_component.health = 100
	health_component.healing = false
	health_component.decaying = true
	health_component.decay_amount = 1
	health_component.decay_speed = 2.0
	health_component.decay_cooldown = 2.0
	
	apply_team_color()

# Processes targeting on the server and triggers visual updates on clients when data is synchronized.
func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		# Updates the color only once the synchronized team_id arrives from the server.
		if team_id != -1 and $Sprite2D.modulate == Color(1.0, 1.0, 1.0, 1.0):
			apply_team_color()
		return
		
	var _all_visible_entities: Dictionary = TargetingUtils.get_all_potential_targets(global_position, detection_area, team_id)

	if not _all_visible_entities.is_empty():
		_process_targeting(_all_visible_entities)
		if is_instance_valid(current_target) and is_instance_valid(ranged_weapon):
			
			ranged_weapon.look_at(current_target.global_position)
			if not ranged_weapon.get("is_charging"):
				var direction: Vector2 = global_position.direction_to(current_target.global_position)
				ranged_weapon.shoot(global_position + direction)

# Re target to higher priority targets, or get new target from the best visible ones
func _process_targeting(all_targets: Dictionary) -> bool:
	
	if is_instance_valid(current_target) and not current_target in detection_area.get_overlapping_bodies():
		current_target = null
		current_targets_priority = 0
	
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
		
	# Goes specifically for players or NPCs that can be killed in less htis
	for dict: Dictionary in [players, npcs]:
		for key: String in dict:
			var potential_target: Dictionary = dict.get(key)
			if TargetingUtils.less_than_x_hits_to_kill(hits_to_kill_to_target, potential_target.get("health"), null, ranged_weapon): # If it is low health increase the priority
				potential_target.set("priority", potential_target.get("priority") + 30)
	
	# Finds the highest priority potential target around
	var best_potential_target: Dictionary
	var highest_priority: int = 0
	for dict: Dictionary in [players, npcs, food, towers]:
		for key: String in dict:
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
		return true
	else:
		return false

# Triggered when health hits 0 to clean up the entity.
func on_tower_died(_attacker_id: String) -> void:
	queue_free()

# Colors the tower based on whether the local client shares the tower's team affiliation.
func apply_team_color() -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node2D = get_tree().current_scene.find_child(local_id, true, false) as Node2D
	
	if local_player and "team_id" in local_player:
		if team_id == local_player.get("team_id"):
			$Sprite2D.modulate = Color(0.0, 1.0, 0.0)
		else:
			$Sprite2D.modulate = Color(1.0, 0.0, 0.0)
