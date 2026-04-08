extends Node2D
class_name PromotionComponent

signal show_promotion_menu(available_classes: Array[String])

var pending_promotions: int = 1 # For the start when you promote to your starting class


@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Increments the promotion counter and initiates the class selection flow for the entity.
func add_pending_promotion(peer_id: int) -> void:
	if multiplayer.is_server():
		pending_promotions += 1
		if entity.is_in_group("player"):
			_send_promotion_options_to_client(peer_id)
		else:
			_npc_auto_promote()

# Identifies valid branching paths in the promotion tree and transmits them to a specific client.
func _send_promotion_options_to_client(peer_id: int) -> void:
	var current: String = entity.get("current_class")
	var options: Array[String] = PromoUtils.get_promotion_options(current)
	
	if not options.is_empty():
		trigger_promotion_ui.rpc_id(peer_id, options)

# Selects a random available class from the promotion tree for NPC entities.
func _npc_auto_promote() -> void:
	var current: String = entity.get("current_class")
	if current == "Super_Queen" or current == "Holy_Queen":
		return

	var options: Array[String] = PromoUtils.get_promotion_options(current)
			
	if not options.is_empty():
		request_promotion(options.pick_random())

# Commands the local player client to display the class promotion interface.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui(available_classes: Array[String]) -> void:
	show_promotion_menu.emit(available_classes)

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
			if entity.is_in_group("player"): # Re sends the options if there is another promotion pending
				var sender_id: int = multiplayer.get_remote_sender_id()
				_send_promotion_options_to_client(sender_id)
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
		level_comp.trigger_upgrade_ui.rpc_id(entity.name.to_int(), level_comp.pending_upgrades, level_comp.stat_levels)

# Updates weapon and ability strings based on the selected class template.
func change_weapon(class_choice: String) -> void:
	var comps: Dictionary = PromoUtils.get_components_for_class(class_choice)
	
	printerr(class_choice + str(comps))

	# Defaults to none
	var new_m: String = comps.get("melee", "None")
	var new_r: String = comps.get("ranged", "None")
	var new_a: String = comps.get("ability", "None")
	var new_a_2: String = comps.get("ability_2", "None")
	var new_s: String = comps.get("shield", "None")
	
	# Sets these to a string, their setters then call the logic to switch the component  
	entity.set("current_melee_weapon", new_m) 
	entity.set("current_ranged_weapon", new_r)
	entity.set("current_first_ability", new_a)
	entity.set("current_second_ability", new_a_2)
	entity.set("current_shield", new_s)


# Calculates and applies stat values to the entity's active components using additive level scaling.
func apply_promotion_stats(class_choice: String) -> void:
	if not PromoUtils.promotion_base_stats_contains(class_choice):
		printerr("NO")
		return
	
	var base: Dictionary = PromoUtils.get_base_stats_for_class(class_choice)
	var level_comp: LevelingComponent = entity.get_node("Components/LevelingComponent") as LevelingComponent
	var levels: Dictionary = level_comp.stat_levels
	var increments: Dictionary = level_comp.upgrade_increments
	
	var comps: Node = entity.get_node("Components")
	var h_comp: Node = comps.get_node("HealthComponent")
	var m_comp: Node = comps.get_node("MovementComponent")
	var r_w_comp: Node = entity.get("ranged_w_component")
	var m_w_comp: Node = entity.get("melee_w_component")
	var a_comp: Node = entity.get("first_ability_component")
	var a_2_comp: Node = entity.get("second_ability_component")
	var s_comp: Node = entity.get("shield_component")

	# Helper lambda to calculate the boosted value: Base + (Increment * Level)
	var calc = func(s_name: String) -> float:
		var base_val: float = float(base.get(s_name, 0.0))
		var step: float = float(increments.get(s_name, 0.0))
		var current_lvl: int = int(levels.get(s_name, 0))
		return base_val + (step * float(current_lvl))

	if m_comp and base.has("move_speed"):
		m_comp.move_speed = int(calc.call("move_speed"))
	if h_comp:
		if base.has("max_health"):
			var old_max: int = h_comp.max_health
			h_comp.max_health = int(calc.call("max_health"))
			
			# Heals the player up when they increase max health
			var health_boost: int = h_comp.max_health - old_max
			h_comp.health += health_boost
			if h_comp.health > h_comp.max_health: 
				h_comp.health = h_comp.max_health
		if base.has("regen_speed"):
			h_comp.regen_speed = calc.call("regen_speed")
		if base.has("regen_amount"):
			h_comp.regen_amount = calc.call("regen_amount")
	
	if base.has("body_damage"):
		entity.set("body_damage", int(calc.call("body_damage")))
	
	if s_comp and base.has("shield_health"):
		s_comp.max_shield_health = int(calc.call("shield_health"))
	
	if m_w_comp:
		if base.has("melee_damage"): m_w_comp.melee_damage = int(calc.call("melee_damage"))
		if base.has("melee_knockback"): m_w_comp.knockback_force = calc.call("melee_knockback")
		if base.has("melee_cooldown"): m_w_comp.attack_cooldown = calc.call("melee_cooldown")
	
	if r_w_comp:
		if base.has("projectile_damage"): r_w_comp.projectile_damage = int(calc.call("projectile_damage"))
		if base.has("projectile_speed"): r_w_comp.projectile_speed = int(calc.call("projectile_speed"))
		if base.has("reload_speed"): r_w_comp.reload_speed = calc.call("reload_speed")
		if base.has("accuracy"): r_w_comp.accuracy = calc.call("accuracy")
	
	if a_comp:
		_apply_ability_stats("current_first_ability", a_comp, base, levels, increments)
	if a_2_comp:
		_apply_ability_stats("current_second_ability", a_2_comp, base, levels, increments)

# Calculates and applies ability-specific stat values using additive scaling based on current stat levels.
func _apply_ability_stats(slot_key: String, a_node: Node, b_dict: Dictionary, lvls: Dictionary, incs: Dictionary) -> void:
	var calc = func(s_name: String) -> float:
		var base_val: float = float(b_dict.get(s_name, 0.0))
		var step: float = float(incs.get(s_name, 0.0))
		var current_lvl: int = int(lvls.get(s_name, 0))
		return base_val + (step * float(current_lvl))

	match entity.get(slot_key):
		"Magic":
			if b_dict.has("area_damage"): a_node.area_damage = int(calc.call("area_damage"))
			if b_dict.has("area_knockback"): a_node.knockback_force = int(calc.call("area_knockback"))
			if b_dict.has("area_radius"): a_node.max_radius = calc.call("area_radius")
			if b_dict.has("area_cooldown"): a_node.area_cooldown = calc.call("area_cooldown")
		"Teleport":
			if b_dict.has("teleport_range"): a_node.max_range = calc.call("teleport_range")
			if b_dict.has("teleport_cooldown"): a_node.teleport_cooldown = calc.call("teleport_cooldown")
		"Teleport_Crush":
			if b_dict.has("area_damage"): a_node.area_damage = int(calc.call("area_damage"))
			if b_dict.has("area_knockback"): a_node.knockback_force = int(calc.call("area_knockback"))
			if b_dict.has("area_radius"): a_node.max_radius = calc.call("area_radius")
			if b_dict.has("teleport_range"): a_node.max_range = calc.call("teleport_range")
			if b_dict.has("teleport_cooldown"): a_node.tp_crush_cooldown = calc.call("teleport_cooldown")
		"Illusion":
			if b_dict.has("illusion_cooldown"): a_node.illusion_cooldown = calc.call("illusion_cooldown")
			if b_dict.has("illusions_count"): a_node.illusions_count = int(calc.call("illusions_count"))
			if b_dict.has("illusion_duration"): a_node.illusion_duration = calc.call("illusion_duration")
		"Stealth":
			if b_dict.has("stealth_cooldown"): a_node.stealth_cooldown = calc.call("stealth_cooldown")
			if b_dict.has("stealth_duration"): a_node.stealth_duration = calc.call("stealth_duration")
		"Spawner":
			if b_dict.has("spawner_cooldown"): a_node.spawner_cooldown = calc.call("spawner_cooldown")
			if b_dict.has("max_spawns"): a_node.max_spawns = int(calc.call("max_spawns"))
		"WOF":
			if b_dict.has("wof_cooldown"): a_node.wof_cooldown = calc.call("wof_cooldown")
			if b_dict.has("wof_length"): a_node.max_length = calc.call("wof_length")
			if b_dict.has("wof_damage"): a_node.max_damage = calc.call("wof_damage")
		"Mass_Heal":
			if b_dict.has("mass_heal_amount"): a_node.mass_heal_amount = int(calc.call("mass_heal_amount"))
			if b_dict.has("mass_heal_cooldown"): a_node.mass_heal_cooldown = int(calc.call("mass_heal_cooldown"))
