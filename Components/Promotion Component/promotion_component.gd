extends Node

signal show_promotion_menu(available_classes: Array[String])

var pending_promotions: int = 1 # For the start when you promote to your starting class

var promotion_tree: Dictionary = {
	"Pawn": ["Pawn_I"], #Rank 1
	"Pawn_I": ["Pawn_II"], #Rank 2
	"Pawn_II": ["Knight", "Mini_Rook"], #Rank 3
	"Knight": ["Shadow_Knight", "Flowers_Knight", "Bishop"], #Rank 4
	"Mini_Rook": ["Rook", "Bishop"],
	"Shadow_Knight": ["Sultans_Knight"], #Rank 5
	"Flowers_Knight": ["Sultans_Knight"],
	"Rook": ["Rook_Knight"],
	"Bishop": ["Bishop_Knight"],
	"Sultans_Knight": ["King_Knight"], #Rank 6
	"Rook_Knight": ["King_Rook"], 
	"Bishop_Knight": ["King_Bishop"],
	"King_Knight": ["King", "Queen", "Sultan", "Jester"], #Rank 7
	"King_Rook": ["King", "Queen", "Sultan", "Jester"],
	"King_Bishop": ["King", "Queen", "Sultan", "Jester"],
	"King": ["Super_Queen", "Holy_Queen"], #Rank 8
	"Queen": ["Super_Queen", "Holy_Queen"],
	"Sultan": ["Super_Queen", "Holy_Queen"],
	"Jester": ["Super_Queen", "Holy_Queen"],
	"Super_Queen": ["Super_Queen", "Pawn_II"], #Rank 9
	"Holy_Queen": ["Holy_Queen", "Pawn_II"]
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
	"projectile_damage": 40.0,
	"projectile_speed": 1000.0,
	"reload_speed": 0.3,
	"accuracy": 100.0, 
	"area_damage": 75.0,
	"area_knockback": 1000.0,
	"area_radius": 500.0,
	"area_cooldown": 2.0,
	"teleport_range": 1000.0,
	"teleport_cooldown": 2.0,
	"stealth_cooldown": 12.0,
	"stealth_duration": 3.0,
	"spawner_cooldown": 12.0,
	"max_spawns": 7.0,
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
		"projectile_damage": 8.0,
		"projectile_speed": 300.0,
		"reload_speed": 2.0,
		"accuracy": 60.0,
		"shield_health": 80.0
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
		"projectile_damage": 10.0,
		"projectile_speed": 400.0,
		"reload_speed": 1.5,
		"accuracy": 60.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 3.0,
		"shield_health": 120.0
	},
	"Bishop": {
		"player_speed": 350.0,
		"max_health": 45.0,
		"regen_speed": 1.0,
		"regen_amount": 3.0,
		"body_damage": 4.0,
		"projectile_damage": 15.0,
		"projectile_speed": 600.0,
		"reload_speed": 1.2,
		"accuracy": 70.0,
		"area_damage": 30.0,
		"area_knockback": 600.0,
		"area_radius": 250.0,
		"area_cooldown": 8.0,
		"shield_health": 50.0
	},

	# Rank 6
	"Sultans_Knight": {
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
		"projectile_damage": 20.0,
		"projectile_speed": 600.0,
		"reload_speed": 1.0,
		"accuracy": 80.0,
		"teleport_range": 350.0,
		"teleport_cooldown": 6.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 5.0,
		"shield_health": 100.0
	},
	"Bishop_Knight": {
		"player_speed": 420.0,
		"max_health": 60.0,
		"regen_speed": 1.5,
		"regen_amount": 4.0,
		"body_damage": 6.0,
		"projectile_damage": 25.0,
		"projectile_speed": 800.0,
		"reload_speed": 0.9,
		"accuracy": 85.0,
		"area_damage": 45.0,
		"area_knockback": 750.0,
		"area_radius": 350.0,
		"area_cooldown": 6.0,
		"shield_health": 75.0
	},

	# Rank 7
	"King_Knight": max_tier_template.duplicate(),
	"King_Bishop": max_tier_template.duplicate(),
	"King_Rook": max_tier_template.duplicate(),

	# Rank 8
	"King": max_tier_template.duplicate(),
	"Queen": max_tier_template.duplicate(),
	"Sultan": max_tier_template.duplicate(),

	"Jester": {
		"player_speed": 520.0,
		"max_health": 110.0,
		"regen_speed": 2.0,
		"regen_amount": 5.0,
		"body_damage": 12.0,
		"projectile_damage": 60.0,
		"projectile_speed": 400.0,
		"reload_speed": 0.8,
		"accuracy": 95.0,
		"illusion_cooldown": 12.0,
		"illusion_duration": 5.0,
		"illusions_count": 6.0,
		"shield_health": 70.0
	},

	# Rank 9
	"Super_Queen": max_tier_template.duplicate(),
	"Holy_Queen": max_tier_template.duplicate()
}

var max_stats: Dictionary = {
	"player_speed": 1200.0,
	"body_damage": 40.0,
	
	#Health & Regen
	"max_health": 400.0,
	"regen_speed": 0.5,
	"regen_amount": 20.0,

	#Ranged
	"projectile_damage": 80.0,
	"projectile_speed": 1100.0,
	"reload_speed": 0.15,
	"accuracy": 100.0,

	#Melee
	"melee_damage": 120.0,
	"melee_knockback": 1600.0,
	"melee_cooldown": 0.1,

	#Area
	"area_damage": 150.0,
	"area_knockback": 2000.0,
	"area_radius": 1000.0,
	"area_cooldown": 1.0,

	#Teleport
	"teleport_cooldown": 1.0,
	"teleport_range": 2000.0,

	#Illusion
	"illusion_cooldown": 4.0,
	"illusion_duration": 10.0,
	"illusions_count": 12.0,

	#Stealth
	"stealth_cooldown": 6.0,
	"stealth_duration": 6.0,

	#Spawning
	"spawner_cooldown": 6.0,
	"max_spawns": 10.0,

	#Shield
	"shield_health": 400.0
}

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var player_UI: Node2D = player.get_node("PlayerUI")

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
		
		player.current_class = choice # TODO Add a check the class is in the dict !!
		
		# Ensure we are not RPCing a client that hasn't finished loading sub-nodes
		var peer_id: int = player.name.to_int()

		# Notify the specific client's UI about the promotion.
		var info_bar: Node = player.get_node_or_null("HUD/InfoLabel")
		# Verify the node exists and is inside the tree before calling an RPC
		if info_bar and info_bar.is_inside_tree():
			var formatted_class: String = choice.replace("_", " ")
			info_bar.display_message.rpc_id(peer_id, "Promoted to " + formatted_class)
		else:
			printerr("No info bar when promoting")
			
		# Re rolls as player may now have new components > new things to upgrade
		var level_comp: Node2D = player.get_node_or_null("Components/LevelingComponent")
		if level_comp and level_comp.is_inside_tree():
			level_comp.trigger_upgrade_ui.rpc_id(peer_id)
		
		if pending_promotions > 0: # ERROR? Is this causing the duplicate promotion visuals
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())

# Updates the active components based on the chosen class.
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	var new_first_ability: String = "None"
	var new_shield: String = "None"
	
	match class_choice:
		"Pawn", "Pawn_I", "Pawn_II":
			new_m_weapon = "Spear"
			new_shield = "Wooden"

		"Knight", "Flowers_Knight":
			new_m_weapon = "Sword"
			new_first_ability = "Teleport"
			new_shield = "Wooden"
			
		"Shadow_Knight":
			new_m_weapon = "Sword"
			new_first_ability = "Stealth"
			new_shield = "Wooden"
			
		"Sultans_Knight", "King_Knight":
			new_m_weapon = "Sword"
			new_first_ability = "Teleport_Crush"
			new_shield = "Wooden"
			
		"Mini_Rook":
			new_r_weapon = "Bow"
			
		"Rook", "Rook_Knight", "King_Rook":
			new_r_weapon = "Bow"
			new_first_ability = "Spawner"
			
		"Bishop", "Bishop_Knight", "King_Bishop":
			new_r_weapon = "Fireball_Shooter"
			new_first_ability = "Magic"
			new_shield = "Magic"
			
		"King":
			new_m_weapon = "Sword"
			new_first_ability = "Magic"
			new_shield = "Wooden"
			
		"Sultan":
			new_m_weapon = "Spear"
			new_first_ability = "Spawner"
			new_shield = "Wooden"
			
		"Queen":
			new_r_weapon = "Fireball_Shooter"
			new_first_ability = "Teleport_Crush"
			new_shield = "Magic"
			
		"Jester":
			new_r_weapon = "Pin_Shooter"
			new_first_ability = "Illusion"
			new_shield = "Magic"
			
		"Super_Queen":
			new_m_weapon = "Sword"
			new_r_weapon = "Bow"
			new_first_ability = "Teleport_Crush"
			new_shield = "Wooden"
			
		"Holy_Queen":
			new_m_weapon = "Spear"
			new_r_weapon = "Fireball_Shooter"
			new_first_ability = "Illusion"
			new_shield = "Magic"
			
	player.current_melee_weapon = new_m_weapon
	player.current_ranged_weapon = new_r_weapon
	player.current_first_ability = new_first_ability
	player.current_shield = new_shield

#For testing
func _get_capped_value(stat_name: String, new_val: float, cap_val: float, old_val: float, is_cooldown: bool = false) -> float:
	var reached_cap: bool = new_val <= cap_val if is_cooldown else new_val >= cap_val
	var final_val: float = cap_val if reached_cap else new_val
	# Only proceed with logging if the rounded values differ.
	if snapped(final_val, 0.01) != snapped(old_val, 0.01):
		if reached_cap:
			print("Stat Log: " + stat_name + " reached MAX CAP: " + str(cap_val))
		else:
			print("Stat Log: " + stat_name + " changed from " + str(snapped(old_val, 0.01)) + " to " + str(snapped(final_val, 0.01)))
			
	return final_val

# Recalculates stats using the new class's baseline multiplied by the player's lifetime stat upgrades.
func apply_promotion_stats(class_choice: String) -> void:
	if not class_base_stats.has(class_choice):
		printerr("Trying to upgrade a non existent class")
		return
	print("Promoting: " + class_choice)
	
	var base_stats: Dictionary = class_base_stats[class_choice]
	var leveling: Node = player.get_node("Components/LevelingComponent")
	var upgrades: Dictionary = leveling.stat_multipliers
	var caps: Dictionary = max_stats

	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var move_comp: Node = components.get_node("MovementComponent")
	var r_weapon_comp: Node = player.ranged_w_component
	var m_weapon_comp: Node = player.melee_w_component
	var first_ability_comp: Node = player.first_ability_component
	var shield_comp: Node = player.shield_component

	if move_comp and base_stats.has("player_speed"):
		move_comp.player_speed = _get_capped_value("player_speed", float(base_stats["player_speed"]) * float(upgrades["player_speed"]), caps["player_speed"], move_comp.player_speed)
		
	if health_comp:
		if base_stats.has("max_health"):
			health_comp.max_health = int(_get_capped_value("max_health", float(base_stats["max_health"]) * float(upgrades["max_health"]), caps["max_health"], health_comp.max_health))
			health_comp.health = health_comp.max_health
		if base_stats.has("regen_speed"):
			health_comp.regen_speed = _get_capped_value("regen_speed", float(base_stats["regen_speed"]) * float(upgrades["regen_speed"]), caps["regen_speed"], health_comp.regen_speed, true)
		if base_stats.has("regen_amount"):
			health_comp.regen_amount = _get_capped_value("regen_amount", float(base_stats["regen_amount"]) * float(upgrades["regen_amount"]), caps["regen_amount"], health_comp.regen_amount)
			
	if base_stats.has("body_damage"):
		player.body_damage = int(_get_capped_value("body_damage", float(base_stats["body_damage"]) * float(upgrades["body_damage"]), caps["body_damage"], player.body_damage))
		
	if shield_comp and base_stats.has("shield_health"):
		shield_comp.max_shield_health = int(_get_capped_value("shield_health", float(base_stats["shield_health"]) * float(upgrades["shield_health"]), caps["shield_health"], shield_comp.max_shield_health))
		
	if m_weapon_comp:
		if base_stats.has("melee_damage"):
			m_weapon_comp.melee_damage = int(_get_capped_value("melee_damage", float(base_stats["melee_damage"]) * float(upgrades["melee_damage"]), caps["melee_damage"], m_weapon_comp.melee_damage))
		if base_stats.has("melee_knockback"):
			m_weapon_comp.knockback_force = _get_capped_value("melee_knockback", float(base_stats["melee_knockback"]) * float(upgrades["melee_knockback"]), caps["melee_knockback"], m_weapon_comp.knockback_force)
		if base_stats.has("melee_cooldown"):
			m_weapon_comp.attack_cooldown = _get_capped_value("melee_cooldown", float(base_stats["melee_cooldown"]) * float(upgrades["melee_cooldown"]), caps["melee_cooldown"], m_weapon_comp.attack_cooldown, true)
			
	if r_weapon_comp:
		if base_stats.has("projectile_damage"):
			r_weapon_comp.projectile_damage = int(_get_capped_value("projectile_damage", float(base_stats["projectile_damage"]) * float(upgrades["projectile_damage"]), caps["projectile_damage"], r_weapon_comp.projectile_damage))
		if base_stats.has("projectile_speed"):
			r_weapon_comp.projectile_speed = _get_capped_value("projectile_speed", float(base_stats["projectile_speed"]) * float(upgrades["projectile_speed"]), caps["projectile_speed"], r_weapon_comp.projectile_speed)
		if base_stats.has("reload_speed"):
			r_weapon_comp.reload_speed = _get_capped_value("reload_speed", float(base_stats["reload_speed"]) * float(upgrades["reload_speed"]), caps["reload_speed"], r_weapon_comp.reload_speed, true)
		if base_stats.has("accuracy"):
			r_weapon_comp.accuracy = _get_capped_value("accuracy", float(base_stats["accuracy"]) * float(upgrades["accuracy"]), caps["accuracy"], r_weapon_comp.accuracy)
			
	if first_ability_comp:
		match player.current_first_ability:
			"Magic":
				if base_stats.has("area_damage"):
					first_ability_comp.area_damage = int(_get_capped_value("area_damage", float(base_stats["area_damage"]) * float(upgrades["area_damage"]), caps["area_damage"], first_ability_comp.area_damage))
				if base_stats.has("area_knockback"):
					first_ability_comp.knockback_force = _get_capped_value("area_knockback", float(base_stats["area_knockback"]) * float(upgrades["area_knockback"]), caps["area_knockback"], first_ability_comp.knockback_force)
				if base_stats.has("area_radius"):
					first_ability_comp.max_radius = _get_capped_value("area_radius", float(base_stats["area_radius"]) * float(upgrades["area_radius"]), caps["area_radius"], first_ability_comp.max_radius)
				if base_stats.has("area_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("area_cooldown", float(base_stats["area_cooldown"]) * float(upgrades["area_cooldown"]), caps["area_cooldown"], first_ability_comp.max_cooldown, true)
			
			"Teleport":
				if base_stats.has("teleport_range"):
					first_ability_comp.max_range = _get_capped_value("teleport_range", float(base_stats["teleport_range"]) * float(upgrades["teleport_range"]), caps["teleport_range"], first_ability_comp.max_range)
				if base_stats.has("teleport_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("teleport_cooldown", float(base_stats["teleport_cooldown"]) * float(upgrades["teleport_cooldown"]), caps["teleport_cooldown"], first_ability_comp.max_cooldown, true)
			
			"Teleport_Crush":
				if base_stats.has("area_damage"):
					first_ability_comp.area_damage = int(_get_capped_value("area_damage", float(base_stats["area_damage"]) * float(upgrades["area_damage"]), caps["area_damage"], first_ability_comp.area_damage))
				if base_stats.has("area_knockback"):
					first_ability_comp.knockback_force = _get_capped_value("area_knockback", float(base_stats["area_knockback"]) * float(upgrades["area_knockback"]), caps["area_knockback"], first_ability_comp.knockback_force)
				if base_stats.has("area_radius"):
					first_ability_comp.max_radius = _get_capped_value("area_radius", float(base_stats["area_radius"]) * float(upgrades["area_radius"]), caps["area_radius"], first_ability_comp.max_radius)
				if base_stats.has("teleport_range"):
					first_ability_comp.max_range = _get_capped_value("teleport_range", float(base_stats["teleport_range"]) * float(upgrades["teleport_range"]), caps["teleport_range"], first_ability_comp.max_range)
				if base_stats.has("teleport_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("teleport_cooldown", float(base_stats["teleport_cooldown"]) * float(upgrades["teleport_cooldown"]), caps["teleport_cooldown"], first_ability_comp.max_cooldown, true)
			
			"Illusion":
				if base_stats.has("illusion_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("illusion_cooldown", float(base_stats["illusion_cooldown"]) * float(upgrades["illusion_cooldown"]), caps["illusion_cooldown"], first_ability_comp.max_cooldown, true)
				if base_stats.has("illusion_duration"):
					first_ability_comp.illusion_duration = _get_capped_value("illusion_duration", float(base_stats["illusion_duration"]) * float(upgrades["illusion_duration"]), caps["illusion_duration"], first_ability_comp.illusion_duration)
				if base_stats.has("illusions_count"):
					first_ability_comp.illusions_count = int(_get_capped_value("illusions_count", float(base_stats["illusions_count"]) * float(upgrades["illusions_count"]), caps["illusions_count"], first_ability_comp.illusions_count))
			
			"Stealth":
				if base_stats.has("stealth_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("stealth_cooldown", float(base_stats["stealth_cooldown"]) * float(upgrades["stealth_cooldown"]), caps["stealth_cooldown"], first_ability_comp.max_cooldown, true)
				if base_stats.has("stealth_duration"):
					first_ability_comp.stealth_duration = _get_capped_value("stealth_duration", float(base_stats["stealth_duration"]) * float(upgrades["stealth_duration"]), caps["stealth_duration"], first_ability_comp.stealth_duration)
			
			"Spawner":
				if base_stats.has("spawner_cooldown"):
					first_ability_comp.max_cooldown = _get_capped_value("spawner_cooldown", float(base_stats["spawner_cooldown"]) * float(upgrades["spawner_cooldown"]), caps["spawner_cooldown"], first_ability_comp.max_cooldown, true)
				if base_stats.has("max_spawns"):
					first_ability_comp.max_spawns = int(_get_capped_value("max_spawns", float(base_stats["max_spawns"]) * float(upgrades["max_spawns"]), caps["max_spawns"], first_ability_comp.max_spawns))

func is_stat_maxed(stat_name: String) -> bool:
	if not class_base_stats.has(player.current_class):
		return false

	var leveling: Node = player.get_node("Components/LevelingComponent")
	var base_val: float = float(class_base_stats[player.current_class].get(stat_name, 0.0))
	var mult_val: float = float(leveling.stat_multipliers.get(stat_name, 1.0))
	var cap_val: float = float(leveling.max_stats.get(stat_name, INF))

	var current_total: float = base_val * mult_val

	# Cooldowns and reload speeds are maxed when they hit the minimum allowable value.
	if stat_name.contains("cooldown") or stat_name.contains("reload") or stat_name == "regen_speed":
		return current_total <= cap_val
		
	return current_total >= cap_val
