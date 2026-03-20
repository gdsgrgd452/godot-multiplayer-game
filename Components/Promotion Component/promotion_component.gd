extends Node

signal show_promotion_menu(available_classes: Array[String])

var pending_promotions: int = 1

var promotion_tree: Dictionary = {
	"Pawn": ["Pawn_I", "Knight", "Bishop", "Mini_Rook"], #Rank 1
	"Pawn_I": ["Pawn_II"], #Rank 2
	"Pawn_II": ["Knight", "Mini_Rook"], #Rank 3
	"Knight": ["Shadow_Knight", "Flowers_Knight", "Bishop"], #Rank 4
	"Mini_Rook": ["Rook", "Bishop"],
	"Shadow_Knight": ["Ottoman_Knight"], #Rank 5
	"Flowers_Knight": ["Ottoman_Knight"],
	"Rook": ["Rook_Knight"],
	"Bishop": ["Bishop_Knight"],
	"Ottoman_Knight": ["King_Knight"], #Rank 6
	"Rook_Knight": ["King_Knight"], 
	"Bishop_Knight": ["King_Knight"],
	"King_Knight": ["King", "Queen", "Sultan", "Jester"], #Rank 7
	"King": ["Super_Queen", "Holy_Queen"], #Rank 8
	"Queen": ["Super_Queen", "Holy_Queen"],
	"Sultan": ["Super_Queen", "Holy_Queen"],
	"Jester": ["Super_Queen", "Holy_Queen"],
	"Super_Queen": ["Super_Queen"], #Rank 9
	"Holy_Queen": ["Holy_Queen"]
}

var max_tier_template: Dictionary = {
	"player_speed": 600.0,
	"max_health": 200.0,
	"regen_speed": 3.0,
	"regen_amount": 10.0,
	"body_damage": 20.0,
	"melee_damage": 60.0,
	"melee_knockback": 800.0,
	"melee_cooldown": 0.2, 
	"bullet_damage": 40.0,
	"bullet_speed": 1500.0,
	"reload_speed": 0.3, 
	"accuracy": 100.0, 
	"area_damage": 75.0,
	"area_knockback": 800.0,
	"area_radius": 300.0,
	"area_cooldown": 2.0,
	"teleport_range": 1000.0,
	"teleport_cooldown": 2.0,
	"shield_health": 200.0
}

var class_base_stats: Dictionary = {
	
	# Rank 1
	"Pawn": {
		"player_speed": 300.0,
		"max_health": 50.0,
		"regen_speed": 1.0,
		"regen_amount": 1.0,
		"body_damage": 5.0,
		"melee_damage": 10.0,
		"melee_knockback": 200.0,
		"melee_cooldown": 1.0,
		"shield_health": 20.0
	},
	
	# Rank 2
	"Pawn_I": {
		"player_speed": 320.0,
		"max_health": 65.0,
		"regen_speed": 1.2,
		"regen_amount": 2.0,
		"body_damage": 8.0,
		"melee_damage": 15.0,
		"melee_knockback": 250.0,
		"melee_cooldown": 0.9,
		"shield_health": 30.0
	},
	
	# Rank 3
	"Pawn_II": {
		"player_speed": 340.0,
		"max_health": 80.0,
		"regen_speed": 1.5,
		"regen_amount": 2.0,
		"body_damage": 10.0,
		"melee_damage": 20.0,
		"melee_knockback": 300.0,
		"melee_cooldown": 0.8,
		"shield_health": 40.0
	},

	# Rank 4
	"Knight": {
		"player_speed": 450.0,
		"max_health": 60.0,
		"regen_speed": 1.5,
		"regen_amount": 2.0,
		"body_damage": 8.0,
		"melee_damage": 25.0,
		"melee_knockback": 300.0,
		"melee_cooldown": 0.6,
		"teleport_range": 400.0,
		"teleport_cooldown": 5.0,
		"shield_health": 40.0
	},
	"Mini_Rook": {
		"player_speed": 200.0,
		"max_health": 150.0,
		"regen_speed": 1.0,
		"regen_amount": 2.0,
		"body_damage": 15.0,
		"melee_damage": 25.0,
		"melee_knockback": 500.0,
		"melee_cooldown": 1.2,
		"shield_health": 80.0
	},
	"Bishop": {
		"player_speed": 350.0,
		"max_health": 45.0,
		"regen_speed": 1.0,
		"regen_amount": 3.0,
		"body_damage": 4.0,
		"bullet_damage": 15.0,
		"bullet_speed": 800.0,
		"reload_speed": 1.2,
		"accuracy": 70.0,
		"area_damage": 30.0,
		"area_knockback": 400.0,
		"area_radius": 150.0,
		"area_cooldown": 8.0,
		"shield_health": 50.0
	},

	# Rank 5
	"Shadow_Knight": { 
		"player_speed": 550.0,
		"max_health": 45.0,
		"regen_speed": 1.0,
		"regen_amount": 1.0,
		"body_damage": 12.0,
		"melee_damage": 40.0,
		"melee_knockback": 150.0,
		"melee_cooldown": 0.4,
		"teleport_range": 600.0,
		"teleport_cooldown": 3.5,
		"shield_health": 25.0
	},
	"Flowers_Knight": {
		"player_speed": 400.0,
		"max_health": 80.0,
		"regen_speed": 2.5,
		"regen_amount": 5.0,
		"body_damage": 10.0,
		"melee_damage": 22.0,
		"melee_knockback": 350.0,
		"melee_cooldown": 0.7,
		"teleport_range": 300.0,
		"teleport_cooldown": 6.0,
		"shield_health": 80.0
	},
	"Rook": {
		"player_speed": 150.0,
		"max_health": 220.0,
		"regen_speed": 1.5,
		"regen_amount": 4.0,
		"body_damage": 25.0,
		"melee_damage": 40.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 1.5,
		"shield_health": 120.0
	},

	# Rank 6
	"Ottoman_Knight": {
		"player_speed": 500.0,
		"max_health": 70.0,
		"regen_speed": 1.5,
		"regen_amount": 3.0,
		"body_damage": 15.0,
		"melee_damage": 35.0,
		"melee_knockback": 400.0,
		"melee_cooldown": 0.5,
		"teleport_range": 450.0,
		"teleport_cooldown": 4.0,
		"shield_health": 50.0
	},
	"Rook_Knight": {
		"player_speed": 300.0,
		"max_health": 170.0,
		"regen_speed": 1.5,
		"regen_amount": 3.0,
		"body_damage": 18.0,
		"melee_damage": 35.0,
		"melee_knockback": 600.0,
		"melee_cooldown": 1.0,
		"teleport_range": 350.0,
		"teleport_cooldown": 6.0,
		"shield_health": 100.0
	},
	"Bishop_Knight": {
		"player_speed": 420.0,
		"max_health": 60.0,
		"regen_speed": 1.5,
		"regen_amount": 4.0,
		"body_damage": 6.0,
		"bullet_damage": 25.0,
		"bullet_speed": 1000.0,
		"reload_speed": 0.9,
		"accuracy": 85.0,
		"area_damage": 45.0,
		"area_knockback": 500.0,
		"area_radius": 200.0,
		"area_cooldown": 6.0,
		"shield_health": 75.0
	},

	# Rank 7
	"King_Knight": max_tier_template.duplicate(),

	# Rank 8
	"King": max_tier_template.duplicate(),
	"Queen": max_tier_template.duplicate(),
	"Sultan": max_tier_template.duplicate(),
	"Jester": max_tier_template.duplicate(),

	# Rank 9
	"Super_Queen": max_tier_template.duplicate(),
	"Holy_Queen": max_tier_template.duplicate()
}

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Grants a pending promotion and notifies the client to open the UI.
func add_pending_promotion(peer_id: int) -> void:
	if multiplayer.is_server():
		pending_promotions += 1
		trigger_promotion_ui.rpc_id(peer_id)

# Commands the local client to open the promotion selection interface with branch options.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui() -> void:
	var current: String = player.current_class
	var options: Array[String] = []
	
	if promotion_tree.has(current):
		var raw_options: Array = promotion_tree[current]
		for opt: Variant in raw_options:
			options.append(opt as String)
			
	show_promotion_menu.emit(options)

# Processes the class choice and applies stats on the server.
@rpc("any_peer", "call_local", "reliable")
func request_promotion(choice: String) -> void:
	if not multiplayer.is_server():
		return
		
	if pending_promotions > 0:
		pending_promotions -= 1
		
		change_weapon(choice)
		apply_promotion_stats(choice)
		
		player.current_class = choice 
		
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())

# Updates the active components based on the chosen class.
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	var new_first_ability: String = "None"
	var new_shield: String = "Wooden"
	
	match class_choice:
		"Pawn", "Pawn_I", "Pawn_II":
			new_m_weapon = "Spear"
		"Knight", "Shadow_Knight", "Flowers_Knight", "Ottoman_Knight", "King_Knight":
			new_m_weapon = "Sword"
			new_first_ability = "Teleport"
		"Mini_Rook", "Rook", "Rook_Knight":
			new_m_weapon = "Spear"
		"Bishop", "Bishop_Knight":
			new_r_weapon = "Ranged_Spell"
			new_first_ability = "Magic"
			new_shield = "Magic"
		"King", "Queen", "Sultan", "Jester", "Super_Queen", "Holy_Queen":
			new_m_weapon = "Sword"
			new_r_weapon = "Ranged_Spell"
			new_first_ability = "Magic"
			new_shield = "Magic"
			
	player.current_melee_weapon = new_m_weapon
	player.current_ranged_weapon = new_r_weapon
	player.current_first_ability = new_first_ability
	player.current_shield = new_shield

# Recalculates stats using the new class's baseline multiplied by the player's lifetime stat upgrades.
func apply_promotion_stats(class_choice: String) -> void:
	if not class_base_stats.has(class_choice):
		return
		
	var base_stats: Dictionary = class_base_stats[class_choice]
	var leveling: Node = player.get_node("Components/LevelingComponent")
	var upgrades: Dictionary = leveling.stat_multipliers
	
	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var move_comp: Node = components.get_node("MovementComponent")
	var r_weapon_comp: Node = player.ranged_w_component
	var m_weapon_comp: Node = player.melee_w_component
	var first_ability_comp: Node = player.first_ability_component
	var shield_comp: Node = player.shield_component
	
	if move_comp and base_stats.has("player_speed"):
		move_comp.player_speed = float(base_stats["player_speed"]) * float(upgrades["player_speed"])
		
	if health_comp:
		if base_stats.has("max_health"):
			health_comp.max_health = int(float(base_stats["max_health"]) * float(upgrades["max_health"]))
			health_comp.health = health_comp.max_health # Full heal on promotion
		if base_stats.has("regen_speed"):
			health_comp.regen_speed = float(base_stats["regen_speed"]) * float(upgrades["regen_speed"])
		if base_stats.has("regen_amount"):
			health_comp.regen_amount = int(float(base_stats["regen_amount"]) * float(upgrades["regen_amount"]))
			
	if base_stats.has("body_damage"):
		player.body_damage = int(float(base_stats["body_damage"]) * float(upgrades["body_damage"]))
		
	if shield_comp and base_stats.has("shield_health"):
		shield_comp.max_shield_health = int(float(base_stats["shield_health"]) * float(upgrades["shield_health"]))
		
	if m_weapon_comp:
		if base_stats.has("melee_damage"):
			m_weapon_comp.melee_damage = int(float(base_stats["melee_damage"]) * float(upgrades["melee_damage"]))
		if base_stats.has("melee_knockback"):
			m_weapon_comp.knockback_force = minf(float(base_stats["melee_knockback"]) * float(upgrades["melee_knockback"]), 4000.0)
		if base_stats.has("melee_cooldown"):
			m_weapon_comp.attack_cooldown = float(base_stats["melee_cooldown"]) * float(upgrades["melee_cooldown"])
			
	if r_weapon_comp:
		if base_stats.has("bullet_damage"):
			r_weapon_comp.bullet_damage = int(float(base_stats["bullet_damage"]) * float(upgrades["bullet_damage"]))
		if base_stats.has("bullet_speed"):
			r_weapon_comp.bullet_speed = minf(float(base_stats["bullet_speed"]) * float(upgrades["bullet_speed"]), 2500.0)
		if base_stats.has("reload_speed"):
			r_weapon_comp.reload_speed = maxf(float(base_stats["reload_speed"]) * float(upgrades["reload_speed"]), 0.2)
		if base_stats.has("accuracy"):
			r_weapon_comp.accuracy = minf(float(base_stats["accuracy"]) * float(upgrades["accuracy"]), 100.0)
			
	if first_ability_comp:
		match player.current_first_ability:
			"Magic":
				if base_stats.has("area_damage"):
					first_ability_comp.area_damage = int(float(base_stats["area_damage"]) * float(upgrades["area_damage"]))
				if base_stats.has("area_knockback"):
					first_ability_comp.knockback_force = float(base_stats["area_knockback"]) * float(upgrades["area_knockback"])
				if base_stats.has("area_radius"):
					first_ability_comp.max_radius = float(base_stats["area_radius"]) * float(upgrades["area_radius"])
				if base_stats.has("area_cooldown"):
					first_ability_comp.max_cooldown = float(base_stats["area_cooldown"]) * float(upgrades["area_cooldown"])
			"Teleport":
				if base_stats.has("teleport_range"):
					first_ability_comp.max_range = float(base_stats["teleport_range"]) * float(upgrades["teleport_range"])
				if base_stats.has("teleport_cooldown"):
					first_ability_comp.max_cooldown = float(base_stats["teleport_cooldown"]) * float(upgrades["teleport_cooldown"])
