extends Node2D
class_name LevelingComponent

signal update_ui_points(val: int)
signal show_upgrade_menu()

@onready var entity: CharacterBody2D = get_parent().get_parent()

@export var points: int = 0:
	set(value):
		points = value
		# Ensures the multiplayer API and onready player reference are valid before attempting synchronization.
		if is_inside_tree() and entity != null and multiplayer.is_server():
			update_ui_points.emit(value)


@export var entity_level: int = 1
@export var next_level_points: int = 10

var total_score: int = 0
var pending_upgrades: int = 0

@onready var npc_gains_points: bool = get_tree().current_scene.npc_gains_points
var maxed_stats_list: Array[String] = []

# The static additive values applied per level to each stat category.
var upgrade_increments: Dictionary = {
	"move_speed": 15.0,
	"body_damage": 2.0,
	
	#Health & Regen
	"max_health": 20.0,
	"regen_speed": -0.05,
	"regen_amount": 1.0,
	
	#Ranged
	"projectile_damage": 4.0,
	"projectile_speed": 10.0,
	"reload_speed": -0.015,
	"accuracy": 5.0,
	
	#Melee
	"melee_damage": 6.0,
	"melee_knockback": 80.0,
	"melee_cooldown": -0.01,
	
	#Area
	"area_damage": 7.5,
	"area_knockback": 120.0,
	"area_radius": 15.0,
	"area_cooldown": -0.1,
	
	#Teleport
	"teleport_range": 100.0,
	"teleport_cooldown": -0.1,

	#Illusion
	"illusion_cooldown": -0.8,
	"illusion_duration": 0.5,
	"illusions_count": 1.0,

	#Stealth
	"stealth_cooldown": -0.6,
	"stealth_duration": 0.4,
	
	#Spawning
	"spawner_cooldown": -0.6,
	"max_spawns": 1.0,
	
	#Shield
	"shield_health": 20.0,
	
	#Healing
	"mass_heal_amount": 15.0,
	"mass_heal_cooldown": -0.2,

	#WOF
	"wof_cooldown": -0.5,
	"wof_length": 40.0,
	"wof_damage": 5.0
}

# Tracks the current upgrade level for every entity attribute.
var stat_levels: Dictionary = {
	"move_speed": 0,
	"body_damage": 0,
	"max_health": 0,
	"regen_speed": 0,
	"regen_amount": 0,
	"projectile_damage": 0,
	"projectile_speed": 0,
	"reload_speed": 0,
	"accuracy": 0,
	"melee_damage": 0,
	"melee_knockback": 0,
	"melee_cooldown": 0,
	"area_damage": 0,
	"area_knockback": 0,
	"area_radius": 0,
	"area_cooldown": 0,
	"teleport_cooldown": 0,
	"teleport_range": 0,
	"illusion_cooldown": 0,
	"illusion_duration": 0,
	"illusions_count": 0,
	"stealth_cooldown": 0,
	"stealth_duration": 0,
	"spawner_cooldown": 0,
	"max_spawns": 0,
	"mass_heal_amount": 0,
	"mass_heal_cooldown": 0,
	"wof_cooldown": 0,
	"wof_length": 0,
	"wof_damage": 0,
	"shield_health": 0
}

# Grants score and initiates level up verification.
func get_points(amount: int) -> void:
	if not multiplayer.is_server():
		return
	points += amount
	total_score += amount
	request_level_up_math()

# Calculates level thresholds and manages pending upgrades for both players and NPCs.
func request_level_up_math() -> void:
	if not multiplayer.is_server():
		return
		
	if entity.is_in_group("npc") and not npc_gains_points: # Blocks NPCs from gaining points
		print("Blocked NPC from gaining points")
		return
		
	var is_player: bool = entity.is_in_group("player")
	var peer_id: int = entity.peer_id if is_player else -1
	
	while points >= next_level_points:
		entity_level += 1
		var ui_comp: Node2D = entity.get_node_or_null("UIComponent")
		if is_instance_valid(ui_comp):
			ui_comp.spawn_floating_number.rpc(1, "level")
		
		var leftover: int = points - next_level_points
		
		if is_player:
			sync_points_to_client.rpc_id(peer_id, next_level_points)
		
		next_level_points = int(pow(float(entity_level), 1.5) * 10.0)
		pending_upgrades += 1
		points = leftover
		
		if not is_player and entity_level % 3 == 0:
			var promo: Node = entity.get_node("Components/PromotionComponent")
			promo.add_pending_promotion(peer_id)

		if is_player and entity_level % 2 == 0:
			var promo: Node = entity.get_node("Components/PromotionComponent")
			promo.add_pending_promotion(peer_id)
		
		if is_player:
			sync_points_to_client.rpc_id(peer_id, leftover)
		
	if pending_upgrades > 0:
		if is_player:
			trigger_upgrade_ui.rpc_id(peer_id, pending_upgrades)
		else:
			_npc_auto_upgrade()

# Identifies non-maxed stats relevant to current equipment and applies a random upgrade for NPCs.
func _npc_auto_upgrade() -> void:
	var promo_comp: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
	
	var curr_class: String = entity.current_class
	var valid_stats_dict: Dictionary = promo_comp.class_base_stats[curr_class] # The base stats
	var available_choices: Array = valid_stats_dict.keys() # The stats the class has
	available_choices = available_choices.filter(func(stat): return not is_stat_maxed(stat)) # Remove any stats that are already maxed
			
	if not available_choices.is_empty():
		var chosen: String = available_choices.pick_random()
		#print("NPC upgraded: " + chosen)
		apply_upgrade(chosen)
	else:
		printerr("No valid")

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Updates stat multipliers and refreshes the entity's base attributes.
func apply_upgrade(button_info: String) -> void:
	if pending_upgrades > 0:
		
		var stat_name: String = button_info.split(" ")[0]
		
		#print("Stat b4: " + str(stat_levels[stat_name]))

		if stat_levels[stat_name] >= 10:
			printerr("Stat is maxed")
			return

		pending_upgrades -= 1
		stat_levels[stat_name] += 1

		#print("Stat after: " + str(stat_levels[stat_name]))

		if stat_levels[stat_name] == 10:
			if not maxed_stats_list.has(stat_name):
				maxed_stats_list.append(stat_name)
				#print("Added to max stats")

		var promo: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
		promo.apply_promotion_stats(entity.get("current_class"))
		
		var ui_comp = entity.get_node_or_null("UIComponent")

		if entity.is_in_group("player"):
			if pending_upgrades > 0: 
				trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id(), pending_upgrades)

			if ui_comp:
				ui_comp.display_message.rpc_id(entity.peer_id, "Upgraded: " + stat_name)

# If a stat is maxed out
func is_stat_maxed(stat_name: String) -> bool:
	return stat_name in maxed_stats_list

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui(upgrade_count: int) -> void:
	show_upgrade_menu.emit(upgrade_count)

# Commands the client to update the level bar
@rpc("authority", "call_local", "reliable")
func sync_points_to_client(val: int) -> void:
	update_ui_points.emit(val)
