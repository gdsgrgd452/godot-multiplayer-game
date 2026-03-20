extends Node

signal update_ui_points(val: int)
signal show_upgrade_menu()

@export var points: int = 0:
	set(value):
		points = value
		update_ui_points.emit(points)

@export var player_level: int = 1
@export var next_level_points: int = 10

var total_score: int = 0
var pending_upgrades: int = 0

# The static increments applied to the multiplier pool upon upgrade selection.
var upgrade_increments: Dictionary = {
	"player_speed": 1.1,
	"body_damage": 1.2,
	
	#Health & Regen
	"max_health": 1.1,
	"regen_speed": 1.1,
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
	
	#Shield
	"shield_health": 1.2
}


# The cumulative multipliers tracked continuously throughout the player's life.
var stat_multipliers: Dictionary = {
	"player_speed": 1.0,
	"body_damage": 1.0,
	
	#Health & Regen
	"max_health": 1.0,
	"regen_speed": 1.0,
	"regen_amount": 1.0,
	
	#Ranged
	"projectile_damage": 1.1,
	"projectile_speed": 1.1,
	"reload_speed": 0.9,
	"accuracy": 1.1,
	
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
	
	#Shield
	"shield_health": 1.0
}

@onready var player: CharacterBody2D = get_parent().get_parent()

# Grants score and initiates level up verification.
func get_points_from_kill(amount: int) -> void:
	if not multiplayer.is_server():
		return
		
	points += amount
	total_score += amount
	request_level_up_math()

# Evaluates if current points meet the threshold for the next level.
@rpc("any_peer", "call_local", "reliable")
func request_level_up_math() -> void:
	if not multiplayer.is_server():
		return
	
	var peer_id: int = player.name.to_int()
	var leveled_up: bool = false
	
	while points >= next_level_points:
		leveled_up = true
		player_level += 1
		
		var leftover: int = points - next_level_points
		
		next_level_points = int(pow(float(player_level), 1.5) * 10.0) #Points per level calculation
		pending_upgrades += 1
		
		points = leftover
		
		# Promote if at the right level
		if player_level % 2 == 0:
			player.get_node("Components/PromotionComponent").add_pending_promotion(peer_id)
			
	# If we leveled up at least once, trigger the upgrade menu for the client
	if leveled_up and pending_upgrades > 0:
		trigger_upgrade_ui.rpc_id(peer_id)

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Applies the multiplier to the pool and immediately pushes the update to the player.
func apply_upgrade(stat_name: String) -> void:
	if pending_upgrades > 0:
		pending_upgrades -= 1
		
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())
			
		var increment: float = upgrade_increments.get(stat_name, 1.0)
		print("Before: " + str(stat_multipliers[stat_name]))
		stat_multipliers[stat_name] *= increment
		print("Applyng, Now: " + str(stat_multipliers[stat_name]))
		var promotion_comp: Node = player.get_node("Components/PromotionComponent")
		promotion_comp.apply_promotion_stats(player.current_class)

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	show_upgrade_menu.emit()
