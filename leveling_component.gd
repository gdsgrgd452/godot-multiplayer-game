extends Node

signal update_ui_points(kill_value: int)
signal show_upgrade_menu

@onready var player: Node = get_parent().get_parent()
@onready var health_component: Node = $"../HealthComponent"
@onready var ranged_w_component: Node = $"../RangedWeaponComponent"

var upgradeable_stats: Dictionary = {"max_health": 100, "body_damage": 5, "bullet_damage": 5, "bullet_speed": 75, "reload_speed": -0.1}

var player_level: int = 0
var next_level_points: int = 10
var points: int = 0
var total_score: int = 0
var pending_upgrades: int = 0

# Gives the player points and updates their local UI
func get_points_from_kill(kill_value: int) -> void:
	if multiplayer.is_server():
		points += kill_value
		total_score += kill_value
		rpc_id(player.name.to_int(), "animate_points_ui", kill_value)

# Tells the UI to animate the point gain locally
@rpc("authority", "call_local", "reliable")
func animate_points_ui(kill_value: int) -> void:
	update_ui_points.emit(kill_value)

# Checks if the player has enough points to level up
@rpc("any_peer", "call_local", "reliable")
func request_level_up_math() -> void:
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == player.name:
			var leveled_up: bool = false
			
			# While loop handles multiple level ups at once
			while points >= next_level_points:
				points -= next_level_points 
				player_level += 1
				next_level_points = next_level_points * 2
				pending_upgrades += 1 
				leveled_up = true
			
			if leveled_up:
				rpc_id(player.name.to_int(), "trigger_show_upgrade_ui")

# Tells the player node to show the upgrade menu
@rpc("authority", "call_local", "reliable")
func trigger_show_upgrade_ui() -> void:
	show_upgrade_menu.emit()

# Routes the clients upgrade choice to the server
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(chosen_stat: String) -> void:
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == player.name:
			apply_upgrade(chosen_stat)

# Actually applies the upgrade stats (Server Side Only)
func apply_upgrade(chosen_stat: String) -> void:
	if pending_upgrades <= 0:
		return 
		
	pending_upgrades -= 1
	
	match chosen_stat:
		"max_health":
			health_component.max_health += upgradeable_stats.get("max_health")
			health_component.heal(upgradeable_stats.get("max_health"))
		"bullet_damage":
			ranged_w_component.bullet_damage += upgradeable_stats.get("bullet_damage")
		"bullet_speed":
			ranged_w_component.bullet_speed += upgradeable_stats.get("bullet_speed")
		"body_damage":
			player.body_damage += upgradeable_stats.get("body_damage") 
		"reload_speed":
			ranged_w_component.reload_speed += upgradeable_stats.get("reload_speed")
			ranged_w_component.reload_speed = max(0.05, ranged_w_component.reload_speed)
	
	# If they still have upgrades waiting, show the buttons
	if pending_upgrades > 0:
		rpc_id(player.name.to_int(), "trigger_show_upgrade_ui")
