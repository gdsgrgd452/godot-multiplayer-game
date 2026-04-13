extends Node2D
class_name MainBrain

@onready var npc: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node2D = npc.get_node("Components/MovementComponent") as Node2D
@onready var detection_area: Area2D = npc.get_node("DetectionArea") as Area2D
@onready var health_comp: Node2D = npc.get_node("Components/HealthComponent") as Node2D

@onready var fleeing_brain: FleeingBrain = get_parent().get_node("FleeingBrain") as FleeingBrain
@onready var combat_brain: CombatBrain = get_parent().get_node("CombatBrain") as CombatBrain
@onready var ability_brain: AbilityBrain = get_parent().get_node("AbilityBrain") as AbilityBrain

var curr_class: String = "Pawn"
var state: String = "Wander"
var my_score: int = 0
var health_scale: float = 1.0
var boldness_factor: float = 1.0 
var kindness_factor: float = 1.0

var all_visible_entities: Dictionary

var wander_target: Vector2 = Vector2.ZERO 
var wander_radius: float = 1000.0

var inp_delay: float = 1.0 
var inp_delay_timer: float = 1.0 

# Initializes randomized behavioral factors and input timers.
func _ready() -> void:
	boldness_factor = randf_range(0.5, 10.0) 
	kindness_factor = randf_range(0.01, 0.2)
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
	health_scale = health_comp.get("health") / health_comp.get("max_health")
	my_score = TargetingUtils.get_entity_score(npc)
	
	combat_brain._clear_blacklist(delta)
	
	if curr_class in ["Rook", "Rook_Knight", "King_Rook", "Sultan"]:
		ability_brain._spawn_towers()
	
	var threat: Node2D = fleeing_brain._get_dangerous_threat()
	if is_instance_valid(threat):
		if combat_brain._last_stand(threat): # If you are taking a last stand, dont flee
			state = "Last_Stand" + "_" + combat_brain.combat_state
			return

		if fleeing_brain._process_fleeing(threat):
			state = "Fleeing"
			
			
			var has_target_whilst_fleeing: bool = false
			# Attacks whilst fleeing, (Wont chase)
			if is_instance_valid(threat):
				if combat_brain._ranged_attack(threat, false):
					state += "_" + combat_brain.combat_state
					has_target_whilst_fleeing = true
				if combat_brain._melee_attack(threat, false):
					state += "_" + combat_brain.combat_state
					has_target_whilst_fleeing = true
			
			if not has_target_whilst_fleeing:
				combat_brain.current_target = null
			return
	
	var new_all_visible_entities: Dictionary = TargetingUtils.get_all_potential_targets(npc.global_position, detection_area, npc.team_id, combat_brain.blacklisted_target)
	if all_visible_entities != null:
		if new_all_visible_entities != all_visible_entities: # Only considers re targeting if the visible entities map changes
			all_visible_entities = new_all_visible_entities
			if combat_brain._process_targeting(all_visible_entities): # If a new target is taken
				return

	var in_combat: bool = false
	if is_instance_valid(combat_brain.current_target) and not combat_brain.current_target.is_queued_for_deletion():
		in_combat = combat_brain._process_combat_state(delta)
		state = combat_brain.combat_state

	if not in_combat:
		_process_wander_state()

# Wanders to a random position
func _process_wander_state() -> bool:
	if wander_target == Vector2.ZERO or npc.global_position.distance_to(wander_target) < 50.0:
		wander_target = _get_valid_wander_pos()
	
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
func _move_towards(_pos: Vector2, _t_pos: Vector2) -> bool:
	move_comp.set("speed_limit_multiplier", 1.0)
	return true

# Provides the raw heading toward the current target for the context steering system.
func get_desired_direction() -> Vector2:
	if state.contains("Fleeing") and fleeing_brain.last_threat_pos != Vector2.ZERO:
		return fleeing_brain.last_threat_pos.direction_to(npc.global_position)
	if state == "Repositioning" and is_instance_valid(combat_brain.current_target):
		return combat_brain.current_target.global_position.direction_to(npc.global_position)
	if state in ["Ranged_Attack", "Melee_Attack"] or state.contains("Last_Stand"):
		return Vector2.ZERO
	if state.contains("Ranged_Attack_TC") and is_instance_valid(combat_brain.current_target):
		return combat_brain.target.global_position.direction_to(npc.global_position)
	if is_instance_valid(combat_brain.current_target):
		return npc.global_position.direction_to(combat_brain.current_target.global_position)
	if state == "Wandering" and wander_target != Vector2.ZERO:
		return npc.global_position.direction_to(wander_target)
	return Vector2.ZERO
