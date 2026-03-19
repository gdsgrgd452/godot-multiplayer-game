extends Node

signal show_promotion_menu(available_classes: Array[String])

var pending_promotions: int = 0

var promotion_tree: Dictionary = {
	"Pawn": ["Pawn_I"], #Rank 1
	
	"Pawn_I": ["Pawn_II"], #Rank 2
	
	"Pawn_II": ["Knight", "Mini_Rook"], #Rank 3
	
	"Knight": ["Shadow_Knight", "Flowers_Knight", "Bishop"], #Rank 4
	"Mini_Rook": ["Rook", "Bishop"],
	
	"Shadow_Knight": ["Ottoman_Knight"], #TODO Think of idea!  Rank 5
	"Flowers_Knight": ["Ottoman_Knight"],
	"Rook": ["Rook_Knight"],
	"Bishop": ["Bishop_Knight"],
	
	"Ottoman_Knight": ["King_Knight"], #Rank 6
	"Rook_Knight": ["King_Knight"], # TODO Need to add king rook and bishop
	"Bishop_Knight": ["King_Knight"],
	
	"King_Knight": ["King", "Queen", "Sultan", "Jester"], #Rank 7
	
	"King": ["Super_Queen", "Holy_Queen"], #Rank 8
	"Queen": ["Super_Queen", "Holy_Queen"],
	"Sultan": ["Super_Queen", "Holy_Queen"],
	"Jester": ["Super_Queen", "Holy_Queen"],
	
	"Super_Queen": ["Super_Queen"], #Rank 9
	"Holy_Queen": ["Holy_Queen"]
}

#TODO body knockback
# Defines base proficiency scaling for each class from 1 (Terrible) to 10 (Specialized).
var class_proficiency_tree: Dictionary = {
	"Pawn": {
		# General 
		"player_speed": 1,
		"max_health": 1,
		"regen_speed": 1,
		"regen_amount": 1,
		"body_damage": 1,
		
		# Melee 
		"melee_damage": 1,
		"melee_knockback": 1,
		"melee_cooldown": 1,
	}, # Rank 1
	
	"Pawn_I": {
		# General 
		"player_speed": 2,
		"max_health": 2,
		"regen_speed": 1,
		"regen_amount": 1,
		"body_damage": 1,
		
		# Melee 
		"melee_damage": 2,
		"melee_knockback": 2,
		"melee_cooldown": 2,
	}, # Rank 2
	
	"Pawn_II": {
		# General 
		"player_speed": 3,
		"max_health": 3,
		"regen_speed": 2,
		"regen_amount": 2,
		"body_damage": 2,
		
		# Melee 
		"melee_damage": 3,
		"melee_knockback": 3,
		"melee_cooldown": 3,
	}, # Rank 3
	
	"Knight": {
		# General 
		"player_speed": 7,
		"max_health": 3,
		"regen_speed": 3,
		"regen_amount": 2,
		"body_damage": 3,
		
		# Melee 
		"melee_damage": 4,
		"melee_knockback": 3,
		"melee_cooldown": 8,
	}, # Rank 4
	
	"Mini_Rook": {
		# General 
		"player_speed": 2,
		"max_health": 6,
		"regen_speed": 2,
		"regen_amount": 3,
		"body_damage": 5,
		
		# Melee 
		"melee_damage": 6,
		"melee_knockback": 6,
		"melee_cooldown": 2,
	},
	
	"Shadow_Knight": {
		# General 
		"player_speed": 8,
		"max_health": 4,
		"regen_speed": 3,
		"regen_amount": 3,
		"body_damage": 4,
		
		# Melee 
		"melee_damage": 6,
		"melee_knockback": 3,
		"melee_cooldown": 9,
	}, # Rank 5
	
	"Flowers_Knight": {
		# General 
		"player_speed": 7,
		"max_health": 5,
		"regen_speed": 7,
		"regen_amount": 6,
		"body_damage": 4,
		
		# Melee 
		"melee_damage": 5,
		"melee_knockback": 4,
		"melee_cooldown": 8,
	},
	
	"Rook": {
		# General 
		"player_speed": 2,
		"max_health": 8,
		"regen_speed": 3,
		"regen_amount": 4,
		"body_damage": 7,
		
		# Melee 
		"melee_damage": 8,
		"melee_knockback": 9,
		"melee_cooldown": 3,
	},
	
	"Bishop": {
		# General 
		"player_speed": 4,
		"max_health": 4,
		"regen_speed": 4,
		"regen_amount": 4,
		"body_damage": 2,
		
		# Ranged
		"bullet_damage": 6,
		"bullet_speed": 5,
		"reload_speed": 6,
		"accuracy": 5,
		
		# Area 
		"area_damage": 6,
		"area_knockback": 5,
		"area_radius": 6,
		"area_cooldown": 5
	},
	
	"Ottoman_Knight": {
		# General 
		"player_speed": 9,
		"max_health": 5,
		"regen_speed": 4,
		"regen_amount": 4,
		"body_damage": 5,
		
		# Melee 
		"melee_damage": 7,
		"melee_knockback": 4,
		"melee_cooldown": 9,
	}, # Rank 6
	
	"Rook_Knight": {
		# General 
		"player_speed": 5,
		"max_health": 8,
		"regen_speed": 5,
		"regen_amount": 5,
		"body_damage": 7,
		
		# Melee 
		"melee_damage": 8,
		"melee_knockback": 7,
		"melee_cooldown": 6,
	}, 
	
	"Bishop_Knight": { 
		# General 
		"player_speed": 6,
		"max_health": 5,
		"regen_speed": 5,
		"regen_amount": 5,
		"body_damage": 4,
		
		# Melee 
		"melee_damage": 5,
		"melee_knockback": 4,
		"melee_cooldown": 6,
		
		# Ranged
		"bullet_damage": 7,
		"bullet_speed": 6,
		"reload_speed": 7,
		"accuracy": 6,
		
		# Area 
		"area_damage": 7,
		"area_knockback": 6,
		"area_radius": 7,
		"area_cooldown": 6
	},
	
	"King_Knight": {
		# General 
		"player_speed": 9,
		"max_health": 8,
		"regen_speed": 7,
		"regen_amount": 7,
		"body_damage": 8,
		
		# Melee 
		"melee_damage": 9,
		"melee_knockback": 8,
		"melee_cooldown": 9,
	}, # Rank 7
	
	"King": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	}, # Rank 8
	
	"Queen": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	},
	
	"Sultan": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	},
	
	"Jester": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	},
	
	"Super_Queen": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	}, # Rank 9
	
	"Holy_Queen": {
		# General 
		"player_speed": 10,
		"max_health": 10,
		"regen_speed": 10,
		"regen_amount": 10,
		"body_damage": 10,
		
		# Melee 
		"melee_damage": 10,
		"melee_knockback": 10,
		"melee_cooldown": 10,
	}
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

# Updates the players weapon when they are promotion 
# This must be done before changing their stats or it will break
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	var new_a_weapon: String = "None"
	
	match class_choice:
		"Pawn", "Pawn_I", "Pawn_II":
			new_m_weapon = "Spear"
		"Knight", "Shadow_Knight", "Flowers_Knight", "Ottoman_Knight", "King_Knight":
			new_m_weapon = "Sword"
		"Mini_Rook", "Rook", "Rook_Knight":
			new_m_weapon = "Spear"
		"Bishop", "Bishop_Knight":
			new_r_weapon = "Ranged_Spell"
			new_a_weapon = "Magic"
		"King", "Queen", "Sultan", "Jester", "Super_Queen", "Holy_Queen":
			new_m_weapon = "Sword"
			new_r_weapon = "Ranged_Spell"
			new_a_weapon = "Magic"
	player.current_melee_weapon = new_m_weapon
	player.current_ranged_weapon = new_r_weapon
	player.current_area_weapon = new_a_weapon

# Calculates and applies stat multipliers based on the proficiency difference between the old and new class.
func apply_promotion_stats(class_choice: String) -> void:
	var old_class: String = player.current_class
	if not class_proficiency_tree.has(old_class) or not class_proficiency_tree.has(class_choice):
		return
		
	var old_prof: Dictionary = class_proficiency_tree[old_class]
	var new_prof: Dictionary = class_proficiency_tree[class_choice]
	
	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var move_comp: Node = components.get_node("MovementComponent")
	var r_weapon_comp: Node = player.ranged_w_component
	var m_weapon_comp: Node = player.melee_w_component
	var a_weapon_comp: Node = player.area_w_component

	apply_general_prom_stats(move_comp, health_comp, old_prof, new_prof)
	
	if m_weapon_comp:
		apply_melee_prom_stats(m_weapon_comp, old_prof, new_prof)
		
	if r_weapon_comp:
		print("Has ")
		apply_ranged_prom_stats(r_weapon_comp, old_prof, new_prof)
		
	if a_weapon_comp:
		apply_area_prom_stats(a_weapon_comp, old_prof, new_prof)

#The below promotional upgrades are not always positive, you can get worse at something

# Modifies general movement and health capabilities based on safely retrieved proficiency ratios.
func apply_general_prom_stats(move_comp: Node, health_comp: Node, old_prof: Dictionary, new_prof: Dictionary) -> void:
	move_comp.player_speed *= float(new_prof.get("player_speed", 1)) / float(old_prof.get("player_speed", 1))
	
	var health_ratio: float = float(new_prof.get("max_health", 1)) / float(old_prof.get("max_health", 1))
	health_comp.max_health = int(health_comp.max_health * health_ratio)
	health_comp.health = int(health_comp.health * health_ratio)
	
	health_comp.regen_speed *= float(old_prof.get("regen_speed", 1)) / float(new_prof.get("regen_speed", 1))
	health_comp.regen_amount = int(health_comp.regen_amount * (float(new_prof.get("regen_amount", 1)) / float(old_prof.get("regen_amount", 1))))
	
	player.body_damage = int(player.body_damage * (float(new_prof.get("body_damage", 1)) / float(old_prof.get("body_damage", 1))))

# Modifies melee combat capabilities based on safely retrieved proficiency ratios.
func apply_melee_prom_stats(m_weapon_comp: Node, old_prof: Dictionary, new_prof: Dictionary) -> void:
	m_weapon_comp.melee_damage = int(m_weapon_comp.melee_damage * (float(new_prof.get("melee_damage", 1)) / float(old_prof.get("melee_damage", 1))))
	m_weapon_comp.knockback_force *= float(new_prof.get("melee_knockback", 1)) / float(old_prof.get("melee_knockback", 1))
	m_weapon_comp.attack_cooldown *= float(old_prof.get("melee_cooldown", 1)) / float(new_prof.get("melee_cooldown", 1))

# Modifies ranged combat capabilities based on safely retrieved proficiency ratios.
func apply_ranged_prom_stats(r_weapon_comp: Node, old_prof: Dictionary, new_prof: Dictionary) -> void:
	r_weapon_comp.bullet_damage = int(r_weapon_comp.bullet_damage * (float(new_prof.get("bullet_damage", 1)) / float(old_prof.get("bullet_damage", 1))))
	r_weapon_comp.bullet_speed *= float(new_prof.get("bullet_speed", 1)) / float(old_prof.get("bullet_speed", 1))
	r_weapon_comp.reload_speed *= float(old_prof.get("reload_speed", 1)) / float(new_prof.get("reload_speed", 1))
	r_weapon_comp.accuracy *= float(new_prof.get("accuracy", 1)) / float(old_prof.get("accuracy", 1))
	
# Modifies area combat capabilities based on safely retrieved proficiency ratios.
func apply_area_prom_stats(a_weapon_comp: Node, old_prof: Dictionary, new_prof: Dictionary) -> void:
	a_weapon_comp.area_damage = int(a_weapon_comp.area_damage * (float(new_prof.get("area_damage", 1)) / float(old_prof.get("area_damage", 1))))
	a_weapon_comp.knockback_force *= float(new_prof.get("area_knockback", 1)) / float(old_prof.get("area_knockback", 1))
	a_weapon_comp.max_radius *= float(new_prof.get("area_radius", 1)) / float(old_prof.get("area_radius", 1))
	a_weapon_comp.attack_cooldown *= float(old_prof.get("area_cooldown", 1)) / float(new_prof.get("area_cooldown", 1))
