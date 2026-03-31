extends Node2D
class_name PromotionComponent

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
	"Super_Queen": ["Holy_Queen", "Pawn_II"], #Rank 9
	"Holy_Queen": ["Super_Queen", "Pawn_II"]
}


var class_base_stats: Dictionary = {
	
	# Rank 1
	"Pawn": {
		"move_speed": 150.0,
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
		"move_speed": 160.0,
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
		"move_speed": 170.0,
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
		"move_speed": 150.0,
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
		"move_speed": 150.0,
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
		"move_speed": 200.0,
		"max_health": 45.0,
		"regen_speed": 1.0,
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
		"move_speed": 150.0,
		"max_health": 220.0,
		"regen_speed": 1.5,
		"regen_amount": 4.0,
		"body_damage": 25.0,
		"projectile_damage": 10.0,
		"projectile_speed": 500.0,
		"reload_speed": 1.5,
		"accuracy": 60.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 3.0,
		"shield_health": 120.0
	},
	"Bishop": {
		"move_speed": 225.0,
		"max_health": 45.0,
		"regen_speed": 1.0,
		"regen_amount": 3.0,
		"body_damage": 4.0,
		"projectile_damage": 15.0,
		"projectile_speed": 400.0,
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
		"move_speed": 250.0,
		"max_health": 70.0,
		"regen_speed": 1.5,
		"regen_amount": 3.0,
		"body_damage": 15.0,
		"melee_damage": 35.0,
		"melee_knockback": 400.0,
		"melee_cooldown": 0.5,
		"teleport_range": 450.0,
		"teleport_cooldown": 4.0,
		"area_damage": 25.0,
		"area_knockback": 500.0,
		"area_radius": 300.0,
		"shield_health": 50.0
	},
	"Rook_Knight": {
		"move_speed": 150.0,
		"max_health": 170.0,
		"regen_speed": 1.5,
		"regen_amount": 3.0,
		"body_damage": 18.0,
		"projectile_damage": 20.0,
		"projectile_speed": 550.0,
		"reload_speed": 1.0,
		"accuracy": 80.0,
		"teleport_range": 350.0,
		"teleport_cooldown": 6.0,
		"spawner_cooldown": 12.0,
		"max_spawns": 5.0,
		"shield_health": 100.0
	},
	"Bishop_Knight": {
		"move_speed": 210.0,
		"max_health": 60.0,
		"regen_speed": 1.5,
		"regen_amount": 4.0,
		"body_damage": 6.0,
		"projectile_damage": 25.0,
		"projectile_speed": 500.0,
		"reload_speed": 0.9,
		"accuracy": 85.0,
		"area_damage": 45.0,
		"area_knockback": 750.0,
		"area_radius": 350.0,
		"area_cooldown": 6.0,
		"shield_health": 75.0
	},

	# Rank 7
	"King_Knight": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 500.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
	},
	"King_Bishop": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 650.0,
		"reload_speed": 0.3,
		"accuracy": 100.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 500.0,
		"area_cooldown": 2.0,
	},
	"King_Rook": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 600.0,
		"reload_speed": 0.3,
		"accuracy": 100.0, 
		"spawner_cooldown": 12.0,
		"max_spawns": 7.0,
		"shield_health": 200.0
	},

	# Rank 8
	"King": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 500.0,
		"area_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"projectile_damage": 40.0,
		"projectile_speed": 700.0,
		"reload_speed": 0.3,
		"accuracy": 100.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 500.0,
		"area_cooldown": 2.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Sultan": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"spawner_cooldown": 12.0,
		"max_spawns": 7.0,
		"shield_health": 200.0
	},

	"Jester": {
		"move_speed": 260.0,
		"max_health": 110.0,
		"regen_speed": 2.0,
		"regen_amount": 5.0,
		"body_damage": 12.0,
		"projectile_damage": 60.0,
		"projectile_speed": 650.0,
		"reload_speed": 0.8,
		"accuracy": 95.0,
		"illusion_cooldown": 12.0,
		"illusion_duration": 5.0,
		"illusions_count": 6.0,
		"shield_health": 70.0,
	},

	# Rank 9
	"Super_Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"projectile_damage": 40.0,
		"projectile_speed": 750.0,
		"reload_speed": 0.3,
		"accuracy": 100.0, 
		"area_damage": 75.0,
		"area_knockback": 1000.0,
		"area_radius": 500.0,
		"area_cooldown": 2.0,
		"teleport_range": 1000.0,
		"teleport_cooldown": 2.0,
		"shield_health": 200.0
	},
	"Holy_Queen": {
		"move_speed": 250.0,
		"max_health": 200.0,
		"regen_speed": 3.0,
		"regen_amount": 10.0,
		"body_damage": 20.0,
		"melee_damage": 60.0,
		"melee_knockback": 800.0,
		"melee_cooldown": 0.2, 
		"projectile_damage": 40.0,
		"projectile_speed": 750.0,
		"reload_speed": 0.3,
		"accuracy": 100.0, 
		"illusion_cooldown": 12.0,
		"illusion_duration": 5.0,
		"illusions_count": 6.0,
		"shield_health": 200.0
	},
}

var max_stats: Dictionary = {
	"move_speed": 400.0,
	"body_damage": 40.0,
	
	#Health & Regen
	"max_health": 400.0,
	"regen_speed": 0.5,
	"regen_amount": 20.0,

	#Ranged
	"projectile_damage": 80.0,
	"projectile_speed": 850.0,
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

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Increments the promotion counter and triggers appropriate selection logic for players or NPCs.
func add_pending_promotion(peer_id: int) -> void:
	if multiplayer.is_server():
		pending_promotions += 1
		if entity.is_in_group("player"):
			trigger_promotion_ui.rpc_id(peer_id)
		else:
			_npc_auto_promote()

# Selects a random available class from the promotion tree for NPC entities.
func _npc_auto_promote() -> void:
	var options: Array[String] = []
	var current: String = entity.get("current_class")
	#print("NPC promting from: " + current)
	if current == "Super_Queen" or current == "Holy_Queen":
		#print("NPC maxed")
		return

	if promotion_tree.has(current):
		for opt: Variant in promotion_tree[current]:
			options.append(opt as String)
			
	if not options.is_empty():
		request_promotion(options.pick_random())

# Commands the local player client to display the class promotion interface.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui() -> void:
	var current: String = entity.get("current_class")
	var options: Array[String] = []
	
	if promotion_tree.has(current):
		for opt: Variant in promotion_tree[current]:
			options.append(opt as String)
			
	show_promotion_menu.emit(options)

# Handles the transition to a new class and updates components on the server.
@rpc("any_peer", "call_local", "reliable")
func request_promotion(choice: String) -> void:
	if not multiplayer.is_server():
		return
		
	if pending_promotions > 0:
		pending_promotions -= 1
		change_weapon(choice)
		apply_promotion_stats(choice)
		entity.set("current_class", choice)

		if entity.is_in_group("player"):
			player_promotion_UI_and_reroll(choice)
		
		if pending_promotions > 0:
			if entity.is_in_group("player"):
				trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())
			else:
				_npc_auto_promote()

# Updates the players UI and re rolls their upgrades
func player_promotion_UI_and_reroll(choice: String) -> void:
	#Displays the promotion info to the player
	var ui_comp: Node = entity.get_node_or_null("UIComponent")
	if ui_comp:
		ui_comp.display_message.rpc_id(entity.name.to_int(), "Promoted to " + choice.replace("_", " "))

	# Re rolls as player may now have new components > new things to upgrade
	var level_comp: LevelingComponent = entity.get_node_or_null("Components/LevelingComponent") as LevelingComponent
	if level_comp and level_comp.is_inside_tree() and level_comp.pending_upgrades > 0:
		level_comp.trigger_upgrade_ui.rpc_id(entity.name.to_int(), level_comp.pending_upgrades)

# Updates weapon and ability strings based on the selected class template.
func change_weapon(class_choice: String) -> void:
	var new_m: String = "None"
	var new_r: String = "None"
	var new_a: String = "None"
	var new_a_2: String = "None"
	var new_s: String = "None"
	
	match class_choice:
		"Pawn", "Pawn_I", "Pawn_II":
			new_m = "Spear"; new_s = "Wooden"
		"Knight", "Flowers_Knight":
			new_m = "Sword"; new_a = "Teleport"; new_s = "Wooden"
		"Shadow_Knight":
			new_m = "Sword"; new_a = "Stealth"; new_s = "Wooden"
		"Sultans_Knight", "King_Knight":
			new_m = "Sword"; new_a = "Teleport_Crush"; new_s = "Wooden"
		"Mini_Rook": 
			new_r = "Bow"; new_a = "Mass_Heal";
		"Rook", "Rook_Knight", "King_Rook": 
			new_r = "Bow"; new_a = "Spawner"
		"Bishop", "Bishop_Knight", "King_Bishop": 
			new_r = "Fireball_Shooter"; new_a = "Magic"; new_s = "Magic"
		"King": 
			new_m = "Sword"; new_a = "Magic"; new_s = "Wooden"
		"Sultan": 
			new_m = "Spear"; new_a = "Mass_Heal"; new_a_2 = "Spawner"; new_s = "Wooden"
		"Queen": 
			new_r = "Fireball_Shooter"; new_a = "Teleport_Crush"; new_s = "Magic"
		"Jester": 
			new_r = "Pin_Shooter"; new_a = "Illusion"; new_s = "Magic"
		"Super_Queen": 
			new_m = "Sword"; new_r = "Bow"; new_a = "Teleport_Crush"; new_s = "Wooden"
		"Holy_Queen": 
			new_m = "Spear"; new_r = "Fireball_Shooter"; new_a = "WOF"; new_s = "Magic"
			
	entity.set("current_melee_weapon", new_m)
	entity.set("current_ranged_weapon", new_r)
	entity.set("current_first_ability", new_a)
	entity.set("current_second_ability", new_a_2)
	entity.set("current_shield", new_s)


# Calculates and applies capped stat values to the entity's active components.
func apply_promotion_stats(class_choice: String) -> void:
	if not class_base_stats.has(class_choice):
		return
	
	var base: Dictionary = class_base_stats[class_choice]
	var level: LevelingComponent = entity.get_node("Components/LevelingComponent") as LevelingComponent
	var mults: Dictionary = level.stat_levels
	
	var comps: Node = entity.get_node("Components")
	var h_comp: Node = comps.get_node("HealthComponent")
	var m_comp: Node = comps.get_node("MovementComponent")
	var r_w_comp: Node = entity.get("ranged_w_component")
	var m_w_comp: Node = entity.get("melee_w_component")
	var a_comp: Node = entity.get("first_ability_component")
	var a_2_comp: Node = entity.get("second_ability_component")
	var s_comp: Node = entity.get("shield_component")

	if m_comp and base.has("move_speed"):
		m_comp.move_speed = _get_capped_value("move_speed", base["move_speed"] * mults["move_speed"], max_stats["move_speed"], m_comp.move_speed)
	if h_comp:
		if base.has("max_health"):
			h_comp.max_health = int(_get_capped_value("max_health", base["max_health"] * mults["max_health"], max_stats["max_health"], h_comp.max_health))
			h_comp.health = h_comp.max_health
		if base.has("regen_speed"):
			h_comp.regen_speed = _get_capped_value("regen_speed", base["regen_speed"] * mults["regen_speed"], max_stats["regen_speed"], h_comp.regen_speed, true)
		if base.has("regen_amount"):
			h_comp.regen_amount = _get_capped_value("regen_amount", base["regen_amount"] * mults["regen_amount"], max_stats["regen_amount"], h_comp.regen_amount)
	if base.has("body_damage"):
		entity.set("body_damage", int(_get_capped_value("body_damage", base["body_damage"] * mults["body_damage"], max_stats["body_damage"], entity.get("body_damage"))))
	if s_comp and base.has("shield_health"):
		s_comp.max_shield_health = int(_get_capped_value("shield_health", base["shield_health"] * mults["shield_health"], max_stats["shield_health"], s_comp.max_shield_health))
	if m_w_comp:
		if base.has("melee_damage"): m_w_comp.melee_damage = int(_get_capped_value("melee_damage", base["melee_damage"] * mults["melee_damage"], max_stats["melee_damage"], m_w_comp.melee_damage))
		if base.has("melee_knockback"): m_w_comp.knockback_force = _get_capped_value("melee_knockback", base["melee_knockback"] * mults["melee_knockback"], max_stats["melee_knockback"], m_w_comp.knockback_force)
		if base.has("melee_cooldown"): m_w_comp.attack_cooldown = _get_capped_value("melee_cooldown", base["melee_cooldown"] * mults["melee_cooldown"], max_stats["melee_cooldown"], m_w_comp.attack_cooldown, true)
	if r_w_comp:
		if base.has("projectile_damage"): r_w_comp.projectile_damage = int(_get_capped_value("projectile_damage", base["projectile_damage"] * mults["projectile_damage"], max_stats["projectile_damage"], r_w_comp.projectile_damage))
		if base.has("projectile_speed"): r_w_comp.projectile_speed = _get_capped_value("projectile_speed", base["projectile_speed"] * mults["projectile_speed"], max_stats["projectile_speed"], r_w_comp.projectile_speed)
		if base.has("reload_speed"): r_w_comp.reload_speed = _get_capped_value("reload_speed", base["reload_speed"] * mults["reload_speed"], max_stats["reload_speed"], r_w_comp.reload_speed, true)
		if base.has("accuracy"): r_w_comp.accuracy = _get_capped_value("accuracy", base["accuracy"] * mults["accuracy"], max_stats["accuracy"], r_w_comp.accuracy)
	if a_comp:
		_apply_ability_stats("current_first_ability", a_comp, base, mults)
	if a_2_comp:
		_apply_ability_stats("current_second_ability", a_2_comp, base, mults)

# Applies ability upgrades
func _apply_ability_stats(first_second: String, a: Node, b: Dictionary, m: Dictionary) -> void:
	match entity.get(first_second):
		"Magic":
			if b.has("area_damage"): a.area_damage = int(_get_capped_value("area_damage", b["area_damage"] * m["area_damage"], max_stats["area_damage"], a.area_damage))
			if b.has("area_radius"): a.max_radius = _get_capped_value("area_radius", b["area_radius"] * m["area_radius"], max_stats["area_radius"], a.max_radius)
			if b.has("area_cooldown"): a.max_cooldown = _get_capped_value("area_cooldown", b["area_cooldown"] * m["area_cooldown"], max_stats["area_cooldown"], a.max_cooldown, true)
		"Teleport":
			if b.has("teleport_range"): a.max_range = _get_capped_value("teleport_range", b["teleport_range"] * m["teleport_range"], max_stats["teleport_range"], a.max_range)
			if b.has("teleport_cooldown"): a.max_cooldown = _get_capped_value("teleport_cooldown", b["teleport_cooldown"] * m["teleport_cooldown"], max_stats["teleport_cooldown"], a.max_cooldown, true)
		"Teleport_Crush":
			if b.has("area_damage"): a.area_damage = int(_get_capped_value("area_damage", b["area_damage"] * m["area_damage"], max_stats["area_damage"], a.area_damage))
			if b.has("teleport_range"): a.max_range = _get_capped_value("teleport_range", b["teleport_range"] * m["teleport_range"], max_stats["teleport_range"], a.max_range)
			if b.has("teleport_cooldown"): a.max_cooldown = _get_capped_value("teleport_cooldown", b["teleport_cooldown"] * m["teleport_cooldown"], max_stats["teleport_cooldown"], a.max_cooldown, true)
		"Illusion":
			if b.has("illusion_cooldown"): a.max_cooldown = _get_capped_value("illusion_cooldown", b["illusion_cooldown"] * m["illusion_cooldown"], max_stats["illusion_cooldown"], a.max_cooldown, true)
			if b.has("illusions_count"): a.illusions_count = int(_get_capped_value("illusions_count", b["illusions_count"] * m["illusions_count"], max_stats["illusions_count"], a.illusions_count))
		"Stealth":
			if b.has("stealth_cooldown"): a.max_cooldown = _get_capped_value("stealth_cooldown", b["stealth_cooldown"] * m["stealth_cooldown"], max_stats["stealth_cooldown"], a.max_cooldown, true)
			print("Current: " + str(a.stealth_duration), " M: " + str(m["stealth_duration"]) + " B: " + str(b["stealth_duration"]))
			if b.has("stealth_duration"): a.stealth_duration = _get_capped_value("stealth_duration", b["stealth_duration"] * m["stealth_duration"], max_stats["stealth_duration"], a.stealth_duration, false)
		"Spawner":
			if b.has("spawner_cooldown"): a.max_cooldown = _get_capped_value("spawner_cooldown", b["spawner_cooldown"] * m["spawner_cooldown"], max_stats["spawner_cooldown"], a.max_cooldown, true)
			if b.has("max_spawns"): a.max_spawns = int(_get_capped_value("max_spawns", b["max_spawns"] * m["max_spawns"], max_stats["max_spawns"], a.max_spawns))
		"Spawner":
			printerr("Add this")

func is_stat_maxed(stat_name: String) -> bool:
	var level_comp: LevelingComponent = entity.get_node("Components/LevelingComponent")
	return level_comp.maxed_stats_list.contains(stat_name)

# Calculates and logs stat changes, returning the clamped result.
func _get_capped_value(s_name: String, n_val: float, c_val: float, o_val: float, is_cd: bool = false) -> float:
	var reached: bool = n_val <= c_val if is_cd else n_val >= c_val
	var final: float = c_val if reached else n_val
	if snapped(final, 0.001) != snapped(o_val, 0.001) and entity.is_in_group("player"):
		print("Stat Log: " + s_name + (" reached MAX CAP: " if reached else " changed to ") + str(snapped(final, 0.01)))
	return final
