class_name PromoUtils

var allow_repromotions: bool = true

static var promotion_tree: Dictionary = {
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
	"Super_Queen": ["Holy_Queen", "Pawn_II"], #Rank 9
	"Holy_Queen": ["Super_Queen", "Pawn_II"]
}

static var class_to_rank: Dictionary = {
	"Pawn": 1,
	"Pawn_I": 2,
	"Pawn_II": 3,
	"Knight": 4,
	"Mini_Rook": 4,
	"Shadow_Knight": 5,
	"Flowers_Knight": 5,
	"Rook": 5,
	"Bishop": 5,
	"Sultans_Knight": 6,
	"Rook_Knight": 6,
	"Bishop_Knight": 6,
	"King_Knight": 7,
	"King_Rook": 7,
	"King_Bishop": 7,
	"King": 8,
	"Queen": 8,
	"Sultan": 8,
	"Jester": 8,
	"Super_Queen": 9,
	"Holy_Queen": 9
}

# Maps each class to its specific component configuration
static var class_to_comps: Dictionary = {
	"Pawn": {
		"melee": "Spear",
		"shield": "Wooden"
	},
	"Pawn_I": {
		"melee": "Spear",
		"shield": "Wooden"
	},
	"Pawn_II": {
		"melee": "Spear",
		"shield": "Wooden"
	},
	"Knight": {
		"melee": "Sword",
		"ability": "Teleport",
		"shield": "Wooden"
	},
	"Mini_Rook": {
		"ranged": "Bow",
		"ability": "Mass_Heal"
	},
	"Shadow_Knight": {
		"melee": "Sword",
		"ability": "Stealth",
		"shield": "Wooden"
	},
	"Flowers_Knight": {
		"melee": "Sword",
		"ability": "Teleport",
		"shield": "Wooden"
	},
	"Rook": {
		"ranged": "Bow",
		"ability": "Spawner"
	},
	"Bishop": {
		"ranged": "Fireball_Shooter",
		"ability": "Magic",
		"shield": "Magic"
	},
	"Sultans_Knight": {
		"melee": "Sword",
		"ability": "Teleport_Crush",
		"shield": "Wooden"
	},
	"Rook_Knight": {
		"ranged": "Bow",
		"ability": "Spawner"
	},
	"Bishop_Knight": {
		"ranged": "Fireball_Shooter",
		"ability": "Magic",
		"shield": "Magic"
	},
	"King_Knight": {
		"melee": "Sword",
		"ability": "Teleport_Crush",
		"shield": "Wooden"
	},
	"King_Rook": {
		"ranged": "Bow",
		"ability": "Spawner"
	},
	"King_Bishop": {
		"ranged": "Fireball_Shooter",
		"ability": "Magic",
		"shield": "Magic"
	},
	"King": {
		"melee": "Sword",
		"ability": "Magic",
		"shield": "Wooden"
	},
	"Queen": {
		"ranged": "Fireball_Shooter",
		"ability": "Teleport_Crush",
		"shield": "Magic"
	},
	"Sultan": {
		"melee": "Spear",
		"ability": "Mass_Heal",
		"ability_2": "Spawner",
		"shield": "Wooden"
	},
	"Jester": {
		"ranged": "Pin_Shooter",
		"ability": "Illusion",
		"shield": "Magic"
	},
	"Super_Queen": {
		"melee": "Sword",
		"ranged": "Bow",
		"ability": "Teleport_Crush",
		"shield": "Wooden"
	},
	"Holy_Queen": {
		"melee": "Spear",
		"ranged": "Fireball_Shooter",
		"ability": "Mass_Heal",
		"ability_2": "WOF",
		"shield": "Magic"
	}
}

static func promotion_tree_contains(chosen_class: String) -> bool:
	return promotion_tree.has(chosen_class)

# Gets the options which the current class can promote to
static func get_promotion_options(chosen_class: String) -> Array[String]:
	if promotion_tree_contains(chosen_class):
		var typed_options: Array[String] = []
		typed_options.assign(promotion_tree.get(chosen_class))
		return typed_options
	else:
		printerr("No promotion options, Invalid class: " + chosen_class)
		return [""]

static func promotion_components_contains(chosen_class: String) -> bool:
	return class_to_comps.has(chosen_class)

# Gets the components a class should have
static func get_components_for_class(chosen_class: String) -> Dictionary:
	if promotion_components_contains(chosen_class):
		return class_to_comps.get(chosen_class)
	else:
		printerr("No components, Invalid class: " + chosen_class)
		return {}

static func promotion_base_stats_contains(chosen_class: String) -> bool:
	return class_base_stats.has(chosen_class)

static func get_base_stats_for_class(chosen_class: String) -> Dictionary:
	if promotion_base_stats_contains(chosen_class):
		return class_base_stats.get(chosen_class)
	else:
		printerr("No Stats, Invalid class (Default to pawn): " + chosen_class)
		return class_base_stats.get("Pawn")

static func promotion_tooltips_contains(chosen_class: String) -> bool:
	return class_tooltips.has(chosen_class)

static func get_tooltip_for_class(chosen_class: String) -> String:
	if promotion_tooltips_contains(chosen_class):
		return class_tooltips.get(chosen_class)
	else:
		printerr("No tooltip, Invalid class: " + chosen_class)
		return "ERROR - NO TOOLTIP"

static var class_tooltips: Dictionary = {
	"Pawn": "Standard Pawn, Uses a Spear and a wooden Shield", #Rank 1
	"Pawn_I": "Upgraded Pawn, Uses a Spear and a Wooden Shield", #Rank 2
	"Pawn_II": "Elite Pawn, Uses a Spear and a Wooden Shield", #Rank 3
	"Knight": "Armed with a Sword and a Wooden Shield, Abilities: Teleport", #Rank 4
	"Mini_Rook": "Armed with a Bow, Abilities: Mass Heal",
	"Shadow_Knight": "Armed with a Sword and a Wooden Shield, Abilities: Stealth", #Rank 5
	"Flowers_Knight": "Armed with a Sword and a Wooden Shield, Abilities: Teleport",
	"Rook": "Armed with a Bow, Abilities: Spawner",
	"Bishop": "Armed with Fireballs and a Magic Shield, Abilities: Magic",
	"Sultans_Knight": "Armed with a Sword and a Wooden Shield, Abilities: Teleport Crush", #Rank 6
	"Rook_Knight": "Armed with a Bow, Abilities: Spawner", 
	"Bishop_Knight": "Armed with Fireballs and a Magic Shield, Abilities: Magic",
	"King_Knight": "Armed with a Sword and a Wooden Shield, Abilities: Teleport Crush", #Rank 7
	"King_Rook": "Armed with a Bow, Abilities: Spawner",
	"King_Bishop": "Armed with Fireballs and a Magic Shield, Abilities: Magic",
	"King": "Armed with a Sword and a Wooden Shield, Abilities: Magic", #Rank 8
	"Queen": "Armed with Fireballs and a Magic Shield, Abilities: Teleport Crush",
	"Sultan": "Armed with a Spear and a Wooden Shield, Abilities: Mass Heal, Spawner",
	"Jester": "Armed with a Pin Shooter and a Magic Shield, Abilities: Illusion",
	"Super_Queen": "Armed with a Sword, a Bow and a Wooden Shield, Abilities: Teleport Crush", #Rank 9
	"Holy_Queen": "Armed with a spear, Holy Fireballs and a Magic Shield, Abilities: Mass heal, Wall of Fire"
}

# Base stats for all the classes
static var class_base_stats: Dictionary = {
	# Rank 1
	"Pawn": {
		"move_speed": 150.0,
		"max_health": 50.0,
		"regen_speed": 25.0,
		"regen_amount": 1.0,
		"body_damage": 5.0,
		"melee_damage": 10.0,
		"melee_knockback": 200.0,
		"melee_cooldown": 1.0,
		"shield_health": 20.0
	},
	
	# Rank 2
	"Pawn_I": {
		"move_speed": 160.0,
		"max_health": 65.0,
		"regen_speed": 22.5,
		"regen_amount": 2.0,
		"body_damage": 8.0,
		"melee_damage": 15.0,
		"melee_knockback": 250.0,
		"melee_cooldown": 0.9,
		"shield_health": 30.0
	},
	
	# Rank 3
	"Pawn_II": {
		"move_speed": 170.0,
		"max_health": 80.0,
		"regen_speed": 20.0,
		"regen_amount": 2.0,
		"body_damage": 10.0,
		"melee_damage": 20.0,
		"melee_knockback": 300.0,
		"melee_cooldown": 0.8,
		"shield_health": 40.0
	},

	# Rank 4
	"Knight": {
		"move_speed": 150.0,
		"max_health": 60.0,
		"regen_speed": 17.5,
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
		"move_speed": 150.0,
		"max_health": 150.0,
		"regen_speed": 15.0,
		"regen_amount": 2.0,
		"body_damage": 15.0,
		"projectile_damage": 8.0,
		"projectile_speed": 150.0,
		"max_charge_time": 2.0,
		"accuracy": 60.0,
		"mass_heal_amount": 20,
		"mass_heal_cooldown": 20.0,
		"shield_health": 80.0
	},


	# Rank 5
	"Shadow_Knight": { 
		"move_speed": 200.0,
		"max_health": 45.0,
		"regen_speed": 17.5,
		"regen_amount": 1.0,
		"body_damage": 12.0,
		"melee_damage": 40.0,
		"melee_knockback": 150.0,
		"melee_cooldown": 0.4,
		"stealth_cooldown": 12.0,
		"stealth_duration": 2.0,
		"shield_health": 25.0
	},
	"Flowers_Knight": {
		"move_speed": 175.0,
		"max_health": 80.0,
		"regen_speed": 15.0,
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
		"move_speed": 150.0,
		"max_health": 220.0,
		"regen_speed": 14.0,
		"regen_amount": 4.0,
		"body_damage": 25.0,
		"projectile_damage": 10.0,
		"projectile_speed": 250.0,
		"max_charge_time": 1.9,
		"accuracy": 70.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 3.0,
		"shield_health": 120.0
	},
	"Bishop": {
		"move_speed": 225.0,
		"max_health": 45.0,
		"regen_speed": 15.0,
		"regen_amount": 3.0,
		"body_damage": 4.0,
		"projectile_damage": 15.0,
		"projectile_speed": 200.0,
		"max_charge_time": 1.9,
		"accuracy": 70.0,
		"area_damage": 30.0,
		"area_knockback": 600.0,
		"area_radius": 150.0,
		"area_cooldown": 8.0,
		"shield_health": 50.0
	},

	# Rank 6
	"Sultans_Knight": {
		"move_speed": 250.0,
		"max_health": 70.0,
		"regen_speed": 14.0,
		"regen_amount": 3.0,
		"body_damage": 15.0,
		"melee_damage": 35.0,
		"melee_knockback": 400.0,
		"melee_cooldown": 0.5,
		"teleport_range": 450.0,
		"teleport_cooldown": 4.0,
		"area_damage": 25.0,
		"area_knockback": 500.0,
		"area_radius": 100.0,
		"shield_health": 50.0
	},
	"Rook_Knight": {
		"move_speed": 150.0,
		"max_health": 170.0,
		"regen_speed": 12.5,
		"regen_amount": 3.0,
		"body_damage": 18.0,
		"projectile_damage": 20.0,
		"projectile_speed": 275.0,
		"max_charge_time": 1.7,
		"accuracy": 75.0,
		"teleport_range": 350.0,
		"teleport_cooldown": 6.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 5.0,
		"shield_health": 100.0
	},
	"Bishop_Knight": {
		"move_speed": 210.0,
		"max_health": 60.0,
		"regen_speed": 15.0,
		"regen_amount": 4.0,
		"body_damage": 6.0,
		"projectile_damage": 25.0,
		"projectile_speed": 250.0,
		"max_charge_time": 1.7,
		"accuracy": 75.0,
		"area_damage": 45.0,
		"area_knockback": 750.0,
		"area_radius": 150.0,
		"area_cooldown": 6.0,
		"shield_health": 75.0
	},

	# Rank 7
	"King_Knight": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 12.5,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 100.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
	},
	"King_Bishop": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 12.5,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 325.0,
		"max_charge_time": 1.5,
		"accuracy": 80.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 150.0,
		"area_cooldown": 2.0,
	},
	"King_Rook": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 10.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 300.0,
		"max_charge_time": 1.5,
		"accuracy": 80.0, 
		"spawner_cooldown": 12.0,
		"max_spawns": 7.0,
		"shield_health": 200.0
	},

	# Rank 8
	"King": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 7.5,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 150.0,
		"area_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 10.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 350.0,
		"max_charge_time": 1.2,
		"accuracy": 85.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 100.0,
		"area_cooldown": 2.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Sultan": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 7.5,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"spawner_cooldown": 12.0,
		"max_spawns": 7.0,
		"mass_heal_amount": 50,
		"mass_heal_cooldown": 30.0,
		"shield_health": 200.0
	},

	"Jester": {
		"move_speed": 260.0,
		"max_health": 110.0,
		"regen_speed": 10.0,
		"regen_amount": 5.0,
		"body_damage": 12.0,
		"projectile_damage": 60.0,
		"projectile_speed": 325.0,
		"max_charge_time": 1.3,
		"accuracy": 85.0,
		"illusion_cooldown": 12.0,
		"illusion_duration": 5.0,
		"illusions_count": 6.0,
		"shield_health": 70.0,
	},

	# Rank 9
	"Super_Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 10.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"projectile_damage": 40.0,
		"projectile_speed": 375.0,
		"max_charge_time": 1.0,
		"accuracy": 90.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 100.0,
		"area_cooldown": 2.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Holy_Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 10.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"projectile_damage": 40.0,
		"projectile_speed": 375.0,
		"max_charge_time": 1.0,
		"accuracy": 90.0, 
		"wof_cooldown": 10.0,
		"wof_length": 500,
		"wof_damage": 10,
		"mass_heal_amount": 100,
		"mass_heal_cooldown": 20.0,
		"shield_health": 200.0
	},
}
