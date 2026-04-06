extends Node2D
class_name FleeingBrain

@onready var main_brain: MainBrain = get_parent().get_node("MainBrain") as MainBrain
@onready var ability_brain: AbilityBrain = get_parent().get_node("AbilityBrain") as AbilityBrain

var current_threat: Node2D
var last_threat_pos: Vector2 = Vector2.ZERO
var flee_timer: float = 0.0
var max_flee_time: float = 5.0
var flee_distance: float = 100.0
var super_scared_threshold: float = 0.2

func _ready() -> void:
	super_scared_threshold = randf_range(0.05, 0.4)
	max_flee_time = randf_range(3.0, 6.0)
	
# Finds the most imminent threat among nearby enemies, weighted by distance and score.
func _get_dangerous_threat() -> Node2D:
	var highest_threat: Node2D = null
	var highest_threat_rating: float = 0.0
	for body: Node2D in main_brain.detection_area.get_overlapping_bodies():
		if not body.is_in_group("player") and not body.is_in_group("npc"):
			continue
		if not "team_id" in body or body.get("team_id") == main_brain.npc.team_id:
			continue
		var enemy_score: int = TargetingUtils.get_entity_score(body)
		var weighted_boldness_threshold: float = main_brain.my_score * main_brain.boldness_factor * main_brain.health_scale
		
		if main_brain.health_scale <= super_scared_threshold: # Super scared if less than 20% health
			weighted_boldness_threshold *= 0.025
		#print("Weighted boldness: " + str(weighted_boldness_threshold))
		if enemy_score <= weighted_boldness_threshold:
			continue
		var score_difference: float = float(enemy_score - main_brain.my_score)
		var distance: float = main_brain.npc.global_position.distance_to(body.global_position)
		if distance < 1.0: distance = 1.0
		var threat_rating: float = (score_difference / distance) / main_brain.health_scale
		if threat_rating > highest_threat_rating:
			highest_threat_rating = threat_rating
			highest_threat = body
			
	current_threat = highest_threat
	return highest_threat

# Handles whether to keep fleeing, is far enough away - stop
func _process_fleeing(threat: Node2D) -> bool:
	if is_instance_valid(threat):
		last_threat_pos = threat.global_position
		flee_timer = max_flee_time
		if main_brain.curr_class == "Shadow_Knight": ability_brain._action_stealth()
		elif main_brain.curr_class == "Jester": ability_brain._action_illusion()
		_action_flee(last_threat_pos)
		return true
	if flee_timer > 0.0:
		flee_timer -= get_physics_process_delta_time()
		_action_flee(last_threat_pos)
		return true
	return false

# ACTION
# Flee away from a threat and sets the fleeing state (Also handles repositioning)
func _action_flee(from_pos: Vector2) -> void:
	var flee_dir: Vector2 = from_pos.direction_to(main_brain.npc.global_position)
	var potential_flee_target: Vector2 = main_brain.npc.global_position + (flee_dir * flee_distance)

	if not AbilityUtils.is_position_within_map(get_tree().current_scene, potential_flee_target):
		var perpendicular: Vector2 = Vector2(-flee_dir.y, flee_dir.x)
		potential_flee_target = main_brain.npc.global_position + (perpendicular * flee_distance)

		if not AbilityUtils.is_position_within_map(get_tree().current_scene, potential_flee_target):
			potential_flee_target = main_brain.npc.global_position - (perpendicular * flee_distance)

	var direction_to_target: Vector2 = (potential_flee_target - main_brain.npc.global_position).normalized()
	main_brain.move_comp.set_movement_direction(direction_to_target)
