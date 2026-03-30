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

var ai_gains_points: bool = true

# The static increments applied to the multiplier pool upon upgrade selection.
var upgrade_increments: Dictionary = {
	"move_speed": 1.1,
	"body_damage": 1.2,
	
	#Health & Regen
	"max_health": 1.1,
	"regen_speed": 0.9,
	"regen_amount": 1.1,
	
	#Ranged
	"projectile_damage": 1.1,
	"projectile_speed": 1.1,
	"reload_speed": 0.9,
	"accuracy": 1.1,
	
	#Melee
	"melee_damage": 1.1,
	"melee_knockback": 1.1,
	"melee_cooldown": 0.9,
	
	#Area
	"area_damage": 1.1,
	"area_knockback": 1.1,
	"area_radius": 1.1,
	"area_cooldown": 0.9,
	
	#Teleport
	"teleport_cooldown": 0.9,
	"teleport_range": 1.1,

	#Illusion
	"illusion_cooldown": 0.9,
	"illusion_duration": 1.2,
	"illusion_amount": 1.2,

	#Stealth
	"stealth_cooldown": 0.9,
	"stealth_duration": 1.2,
	
	#Spawning
	"spawner_cooldown": 0.9,
	"max_spawns": 1.4,
	
	#Shield
	"shield_health": 1.2
}

# The cumulative multipliers tracked continuously throughout the player's life.
var stat_multipliers: Dictionary = {
	"move_speed": 1.0,
	"body_damage": 1.0,
	
	#Health & Regen
	"max_health": 1.0,
	"regen_speed": 1.0,
	"regen_amount": 1.0,
	
	#Ranged
	"projectile_damage": 1.0,
	"projectile_speed": 1.0,
	"reload_speed": 0.9,
	"accuracy": 1.0,
	
	#Melee
	"melee_damage": 1.0,
	"melee_knockback": 1.0,
	"melee_cooldown": 1.0,
	
	#Area
	"area_damage": 1.0,
	"area_knockback": 1.0,
	"area_radius": 1.0,
	"area_cooldown": 1.0,
	
	#Teleport
	"teleport_cooldown": 1.0,
	"teleport_range": 1.0,
	
	#Illusion
	"illusion_cooldown": 1.0,
	"illusion_duration": 1.0,
	"illusions_count": 1.0,

	#Stealth
	"stealth_cooldown": 1.0,
	"stealth_duration": 1.0,
	
	#Spawning
	"spawner_cooldown": 1.0,
	"max_spawns": 1.0,
	
	#Shield
	"shield_health": 1.0
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
		
	if entity.is_in_group("npc") and not ai_gains_points:
		print("Blocked AI from gaining points")
		return
		
	var is_player: bool = entity.is_in_group("player")
	var peer_id: int = entity.name.to_int() if is_player else -1
	
	while points >= next_level_points:
		entity_level += 1
		spawn_floating_text.rpc(1)
		
		var leftover: int = points - next_level_points
		
		if is_player:
			sync_points_to_client.rpc_id(peer_id, next_level_points)
		
		next_level_points = int(pow(float(entity_level), 1.5) * 10.0)
		pending_upgrades += 1
		points = leftover
		
		#print(str(stat_multipliers))
		
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
			trigger_upgrade_ui.rpc_id(peer_id)
		else:
			_npc_auto_upgrade()

# Identifies non-maxed stats relevant to current equipment and applies a random upgrade for NPCs.
func _npc_auto_upgrade() -> void:
	var promo_comp: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
	
	var curr_class: String = entity.current_class
	var valid_stats_dict: Dictionary = promo_comp.class_base_stats[curr_class] # The base stats
	var available_choices: Array = valid_stats_dict.keys() # The stats the class has
	#print(str(available_choices))
	available_choices = available_choices.filter(func(stat): return not promo_comp.is_stat_maxed(stat)) # Remove any stats that are already maxed
			
	if not available_choices.is_empty():
		var chosen: String = available_choices.pick_random()
		#print("Ai upgraded: " + chosen)
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
		pending_upgrades -= 1
		
		var stat_name: String = button_info.split(" ")[0]
		
		var increment: float = upgrade_increments.get(stat_name, 1.0)
		stat_multipliers[stat_name] *= increment
		
		var promo: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
		promo.apply_promotion_stats(entity.get("current_class"))
		
		var ui_comp = entity.get_node_or_null("UIComponent")

		# If the stat is maxed
		if promo.is_stat_maxed(stat_name):
			printerr("Trying to upgrade manual but maxed: " + stat_name)
			pending_upgrades += 1
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id()) # Re show the upgrade buttons
			
			if entity.is_in_group("player") and ui_comp:
				ui_comp.display_message.rpc_id(entity.name.to_int(), "ERROR MAX: " + stat_name)
			
		if entity.is_in_group("player"):
			if pending_upgrades > 0: 
				trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())  # Re show the upgrade buttons

			if ui_comp:
				ui_comp.display_message.rpc_id(entity.name.to_int(), "Upgraded: " + stat_name)

# Spawns or updates a floating, vanishing label on all clients to stack level changes dynamically from the base position.
@rpc("authority", "call_local", "unreliable")
func spawn_floating_text(amount: int) -> void:
	if not entity:
		return

	var vertical_offset: float = -20.0 * entity.scale.y
	var random_offset_x: float = randf_range(-15.0, 15.0) - 18.0 
	var label: Label = Label.new()
	
	label.top_level = true
	label.text = "+" + str(amount)
	label.add_theme_font_size_override("font_size", 30)
	label.modulate = Color(0.0, 0.0, 1.0, 1.0)
	
	label.global_position = entity.global_position + Vector2(random_offset_x, vertical_offset)
	
	entity.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(0.5, 0.5), 1.0).from(Vector2(1.5, 1.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	show_upgrade_menu.emit()

# Commands the client to update the level bar
@rpc("authority", "call_local", "reliable")
func sync_points_to_client(val: int) -> void:
	update_ui_points.emit(val)
