extends Node

signal update_ui_points(val: int)
signal show_upgrade_menu()
signal show_promotion_menu()
signal change_m_weapon(weapon_type: String)
signal change_r_weapon(weapon_type: String)

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
		#print("In Component: " + str(next_level_points)) 
		pending_upgrades += 1
		
		if player_level % 8 == 0:
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
func apply_upgrade(_stat_name: String) -> void:
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
		change_weapon(choice)
		apply_promotion_stats(choice)
		pending_promotions -= 1
		
		# Update the synchronized variable instead of using an RPC
		player.current_class = choice 
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	#print("Emitting upgrade")
	show_upgrade_menu.emit()

# Commands the local client to open the promotion selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui() -> void:
	show_promotion_menu.emit()

#Changes the weapon before applying the stats to prevent them applying to the previous weapon
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	
	match class_choice:
		"Knight":
			new_m_weapon = "Sword"
			new_r_weapon = "None"
		"Rook":
			new_m_weapon = "Spear"
			new_r_weapon = "None"
		"Bishop":
			new_m_weapon = "None"
			new_r_weapon = "Ranged_Spell"

	change_m_weapon.emit(new_m_weapon)
	change_r_weapon.emit(new_r_weapon)

# Applies default and specific stat packages based on the chosen chess class.
func apply_promotion_stats(class_choice: String) -> void:
	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var r_weapon_comp: Node = player.ranged_w_component
	var m_weapon_comp: Node = player.melee_w_component	
	var move_comp: Node = components.get_node("MovementComponent")

	print("Applying stats for: " + str(class_choice))
	
	match class_choice:
		"Knight": #Knights are faster (Swords are naturally faster so no change to melee speed)
			move_comp.player_speed += 300.0
			health_comp.max_health = health_comp.max_health * 0.8
			health_comp.health = health_comp.max_health
			m_weapon_comp.melee_damage = m_weapon_comp.melee_damage * 1.5
			
		"Rook": #Rooks are tanks, High health high damage
			health_comp.max_health = health_comp.max_health * 2
			move_comp.player_speed = move_comp.player_speed * 0.5
			m_weapon_comp.melee_damage = m_weapon_comp.melee_damage * 1.5
			m_weapon_comp.knockback_force = m_weapon_comp.knockback_force * 2
			
		"Bishop": #Bishops are ranged with magic
			r_weapon_comp.bullet_speed = r_weapon_comp.bullet_speed * 2
			r_weapon_comp.reload_speed = r_weapon_comp.reload_speed * 0.5
			
