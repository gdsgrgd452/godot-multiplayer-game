extends Node

signal update_ui_points(val: int)
signal show_upgrade_menu()
signal show_promotion_menu()

@export var points: int = 0:
	set(value):
		points = value
		update_ui_points.emit(points)

@export var player_level: int = 1
@export var next_level_points: int = 10

var total_score: int = 0
var pending_upgrades: int = 0
var pending_promotions: int = 0

var upgradeable_stats: Dictionary = {
	"max_health": 50,
	"bullet_damage": 10,
	"bullet_speed": 50,
	"body_damage": 10,
	"reload_speed": -0.01
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
		next_level_points = int(pow(player_level, 1.5) * 10)
		print("In Component: " + str(next_level_points)) 
		pending_upgrades += 1
		
		if player_level % 3 == 0:
			pending_promotions += 1
			
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Applies a standard level-up stat increase to the player components.
func apply_upgrade(stat_name: String) -> void:
	if pending_upgrades > 0:
		pending_upgrades -= 1
		
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())

			# TODO: Route the explicit stat logic to Health/Weapon components here

# Processes the client's class choice and checks for remaining backlogged promotions.
@rpc("any_peer", "call_local", "reliable")
func request_promotion(choice: String) -> void:
	if not multiplayer.is_server():
		return
		
	if pending_promotions > 0:
		apply_promotion_stats(choice)
		pending_promotions -= 1
		
		# Update the synchronized variable instead of using an RPC
		player.current_class = choice 
		
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	print("Emitting upgrade")
	show_upgrade_menu.emit()

# Commands the local client to open the promotion selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui() -> void:
	show_promotion_menu.emit()

# Applies specific stat packages based on the chosen chess class.
func apply_promotion_stats(choice: String) -> void:
	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var weapon_comp: Node = components.get_node("RangedWeaponComponent")
	var move_comp: Node = components.get_node("MovementComponent")
	
	match choice:
		"Knight":
			move_comp.player_speed += 50.0
			health_comp.max_health += 20.0
			health_comp.health += 20.0
		"Rook":
			health_comp.max_health += 100.0
			health_comp.health += 100.0
			move_comp.player_speed -= 20.0
			weapon_comp.bullet_damage += 15.0
		"Bishop":
			weapon_comp.bullet_speed += 200.0
			weapon_comp.reload_speed *= 0.8
			health_comp.max_health += 10.0
