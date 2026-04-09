extends Node2D
class_name TargetingUtils

static var all_passive: bool = false

# Returns a map of all potential targets to their info
static func get_all_potential_targets(origin: Vector2, detection_area: Area2D, my_team: int, exclude_blacklisted: Node = null) -> Dictionary:
	var targets_to_info: Dictionary = {}
	
	for body: Node2D in detection_area.get_overlapping_bodies():
		if body == exclude_blacklisted or not is_instance_valid(body):
			continue
			
		var body_team: int = body.get("team_id") if "team_id" in body else -1
		
		if body_team != -1 and body_team != my_team:
			if (not all_passive and body.is_in_group("player")):
				targets_to_info[body.name] = get_target_info(body, origin)
			elif body.is_in_group("npc"): 
				targets_to_info[body.name] = get_target_info(body, origin)
			elif body.is_in_group("food"):
				targets_to_info[body.name] = get_target_info(body, origin)
			elif body.is_in_group("tower"):
				targets_to_info[body.name] = get_target_info(body, origin)
				
	return targets_to_info

# Checks is something would die in less than a few hits
static func less_than_x_hits_to_kill(hits_to_kill_to_target: int, target_health: int, melee_comp: Node2D = null, ranged_comp: Node2D = null) -> bool:
	var hits_to_kill: float = INF
	
	if is_instance_valid(melee_comp):
		hits_to_kill = target_health / melee_comp.melee_damage
	if is_instance_valid(ranged_comp):
		hits_to_kill = target_health / ranged_comp.projectile_damage
		
	return hits_to_kill < hits_to_kill_to_target

static func get_target_info(target: Node2D, origin: Vector2) -> Dictionary:
	var target_info: Dictionary = {
		"entity": target,
		"type": get_entity_type(target),
		"health": get_entity_health(target),
		"distance": get_entity_distance_from(target, origin),
		"score": get_entity_score(target),
		"priority": 0
	}
	return target_info

# Iterates through a provided array of nodes to identify the one with the shortest distance to the origin.
static func _find_closest_in_array(origin: Vector2, targets: Array[Node2D]) -> Node2D:
	var closest: Node2D = null
	var min_dist: float = INF
	
	for target: Node2D in targets:
		var dist: float = origin.distance_to(target.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = target
			
	return closest

# Returns the type 
static func get_entity_type(body: Node2D) -> String:
	if body.is_in_group("player"):
		return "player"
	if body.is_in_group("npc"):
		return "npc"
	if body.is_in_group("tower"):
		return "tower"
	if body.is_in_group("food"):
		return "food"
	printerr("Unknown thing in the targeting range")
	return "unknown"

# Retrieves the total score from an entity's LevelingComponent if available.
static func get_entity_score(entity: Node2D) -> int:
	var level_comp: LevelingComponent = entity.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp) and "total_score" in level_comp:
		return level_comp.total_score as int
	elif entity.is_in_group("food"):
		return entity.points_value
	return 0 # Gives things without a score 0 (Towers)

static func get_entity_health(entity: Node2D) -> int:
	var health_comp: Node2D = entity.get_node_or_null("Components/HealthComponent")
	if is_instance_valid(health_comp) and "health" in health_comp:
		return health_comp.health
	else:
		printerr("No health found")
		return 0

static func get_entity_distance_from(entity: Node2D, origin: Vector2) -> float:
	var dist: float = origin.distance_to(entity.global_position)
	return dist
	
# Returns the base priority based on type
static func get_priority(body: Node2D) -> int:
	if body.is_in_group("player"):
		return 50
	if body.is_in_group("npc"):
		return 50
	if body.is_in_group("tower"):
		return 49
	if body.is_in_group("food"):
		return 30
	printerr("Unknown thing in the targeting range")
	return 0

# Determines if a food entity is a valid target based on its shape type and the attacker's accumulated score.
static func _is_food_accessible(food: Node2D, score: int) -> bool:
	var shape: String = food.get("shape_type")
	match shape:
		"Circle": return score >= 0
		"Triangle": return score >= 100
		"Square": return score >= 500
		"Hexagon": return score >= 2000
		"Decagon": return score >= 50000
		_: return true
