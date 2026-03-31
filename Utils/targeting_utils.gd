extends Node2D
class_name TargetingUtils

static var all_passive: bool = false

# Evaluates targets within an area to find the closest enemy while prioritizing players/NPCs and filtering by score.
static func get_closest_enemy(origin: Vector2, detection_area: Area2D, my_team: int, ignore_score: bool, my_score: int = 1, exclude_target: Node = null) -> Node2D:
	var target_players_npcs: Array[Node2D] = []
	var target_others: Array[Node2D] = []

	for body: Node2D in detection_area.get_overlapping_bodies():
		if body == exclude_target:
			continue
		
		var body_team = body.get("team_id") if "team_id" in body else -1
		
		if body_team != -1 and body_team != my_team:
			if (not all_passive and body.is_in_group("player")) or body.is_in_group("npc"):
				target_players_npcs.append(body)
			elif body.is_in_group("food"):
				if _is_food_accessible(body, my_score) or ignore_score:
					target_others.append(body)			
			elif body.is_in_group("tower") or body.is_in_group("shield_blockable"):
				target_others.append(body)

	if not target_players_npcs.is_empty():
		return _find_closest_in_array(origin, target_players_npcs)
	return _find_closest_in_array(origin, target_others)

# Determines if a food entity is a valid target based on its shape type and the attacker's accumulated score.
static func _is_food_accessible(food: Node2D, score: int) -> bool:
	var shape: String = food.get("shape_type")
	match shape:
		"Circle": return score <= 150
		"Triangle": return score >= 100
		"Square": return score >= 500
		"Hexagon": return score >= 2000
		"Decagon": return score >= 50000
		_: return true

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

# Returns a priority integer based on node groups to assist NPC in target selection.
static func get_priority(body: Node2D) -> int:
	if not is_instance_valid(body):
		return 0
	if body.is_in_group("player"):
		return 3
	if body.is_in_group("npc"):
		return 3
	if body.is_in_group("tower"):
		return 2
	if body.is_in_group("food"):
		return 1
	return 0

# Retrieves the total score from an entity's LevelingComponent if available.
static func get_entity_score(entity: Node2D) -> int:
	var level_comp: Node = entity.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp) and "total_score" in level_comp:
		return level_comp.total_score as int
	return 0 # Gives things without a score 0 (Towers)
