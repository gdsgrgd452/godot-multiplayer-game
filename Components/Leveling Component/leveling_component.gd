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

var upgradeable_stats: Dictionary = {
	"player_speed": 1.1,
	"body_damage": 1.2,
	
	#Health & Regen
	"max_health": 1.1,
	"regen_speed": 1.1,
	"regen_amount": 1.1,
	
	#Ranged
	"bullet_damage": 1.1,
	"bullet_speed": 1.1,
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
	"teleport_range": 1.1
}

@onready var player: CharacterBody2D = get_parent().get_parent()

# Grants score and initiates level up verification.
func get_points_from_kill(amount: int) -> void:
	if not multiplayer.is_server():
		return
		
	points += amount
	total_score += amount
	# update_ui_points.emit(points) is removed from here because the setter now handles it automatically.
	request_level_up_math()

# Evaluates if current points meet the threshold for the next level.
@rpc("any_peer", "call_local", "reliable")
func request_level_up_math() -> void:
	if not multiplayer.is_server():
		return
	
	if points >= next_level_points:
		player_level += 1
		points -= next_level_points
		next_level_points = int(pow(float(player_level), 1.5) * 10.0)
		pending_upgrades += 1
		
		if player_level % 2 == 0:
			player.get_node("Components/PromotionComponent").add_pending_promotion(multiplayer.get_remote_sender_id())
			
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Applies a standard multiplicative stat increase to the appropriate player component.
func apply_upgrade(stat_name: String) -> void:
	if pending_upgrades > 0:
		pending_upgrades -= 1
		
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())
			
		var multiplier: float = upgradeable_stats.get(stat_name, 1.0)
		
		match stat_name:
			"player_speed":
				if player.movement_component:
					player.movement_component.player_speed = player.movement_component.player_speed * multiplier
			
			"max_health", "regen_speed", "regen_amount":
				if player.health_component:
					match stat_name:
						"max_health":
							player.health_component.max_health = int(player.health_component.max_health * multiplier)
							player.health_component.health = int(player.health_component.health * multiplier)
						"regen_speed":
							player.health_component.regen_speed = player.health_component.regen_speed * multiplier
						"regen_amount":
							player.health_component.regen_amount = player.health_component.regen_amount * multiplier
							
			"body_damage":
				player.body_damage = int(player.body_damage * multiplier) 
				
			"bullet_damage", "bullet_speed", "reload_speed", "accuracy":
				if player.ranged_w_component:
					match stat_name:
						"bullet_damage":
							player.ranged_w_component.bullet_damage = int(player.ranged_w_component.bullet_damage * multiplier)
						"bullet_speed":
							player.ranged_w_component.bullet_speed = min(int(player.ranged_w_component.bullet_speed * multiplier), 2500)
						"reload_speed":
							player.ranged_w_component.reload_speed = max(player.ranged_w_component.reload_speed * multiplier, 0.2)
						"accuracy":
							player.ranged_w_component.accuracy = min(player.ranged_w_component.accuracy * multiplier, 100.0)
							
			"melee_damage", "melee_knockback", "melee_cooldown":
				if player.melee_w_component:
					match stat_name:
						"melee_damage":
							player.melee_w_component.melee_damage = int(player.melee_w_component.melee_damage * multiplier)
						"melee_knockback":
							player.melee_w_component.knockback_force = min(player.melee_w_component.knockback_force * multiplier, 4000.0)
						"melee_cooldown":
							player.melee_w_component.attack_cooldown *= multiplier
							
			"area_damage", "area_knockback", "area_radius", "area_cooldown", "teleport_cooldown", "teleport_range":
				if player.first_ability_component:
					match stat_name:
						"area_damage":
							player.first_ability_component.area_damage = int(player.first_ability_component.area_damage * multiplier)
						"area_knockback":
							player.first_ability_component.knockback_force *= multiplier
						"area_radius":
							player.first_ability_component.max_radius *= multiplier
						"area_cooldown", "teleport_cooldown":
							player.first_ability_component.max_cooldown *= multiplier
						"teleport_range":
							player.first_ability_component.max_range *= multiplier

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	show_upgrade_menu.emit()

# Updates the synchronized weapon variables on the server so all clients receive the change.
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	var new_first_ability: String = "None"
	
	match class_choice:
		"Knight":
			new_m_weapon = "Sword"
		"Rook":
			new_m_weapon = "Spear"
		"Bishop":
			new_r_weapon = "Ranged_Spell" 
			new_first_ability = "Magic"

	player.current_melee_weapon = new_m_weapon
	player.current_ranged_weapon = new_r_weapon
	player.current_first_ability = new_first_ability
