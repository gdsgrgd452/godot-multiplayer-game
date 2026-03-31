extends Node2D
class_name ComponentManager

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var components_container: Node2D = get_parent() as Node2D
@onready var ui_comp: Node2D = entity.get_node("UIComponent")

var is_player_and_UI_valid: bool = false

# Initializes the component states by hiding all equipment and processing the initial class setup.
func _ready() -> void:
	_hide_all_components()
	is_player_and_UI_valid = entity.is_in_group("player") and is_instance_valid(ui_comp)

# Disables only the non-essential equipment and ability components to ensure core entity logic remains active.
func _hide_all_components() -> void:
	var essential_nodes: Array[String] = [
		"MovementComponent",
		"HealthComponent",
		"LevelingComponent",
		"PromotionComponent",
		"ComponentManager",
		"UIComponent",
		"NPCControllerComponent"
	]
	
	for child: Node in components_container.get_children():
		if child.name in essential_nodes:
			continue
			
		if child is Node2D:
			child.hide()
			child.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

#Swaps the active melee weapon component and updates UI labels while ensuring node validity before property access.
func change_melee_weapon(weapon_type: String) -> void:
	var spear: Node2D = components_container.get_node_or_null("SpearComponent")
	var sword: Node2D = components_container.get_node_or_null("SwordComponent")
	
	if is_instance_valid(spear):
		spear.hide()
		spear.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	if is_instance_valid(sword):
		sword.hide()
		sword.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		
	var msg: String = ""
	match weapon_type:
		"Spear":
			entity.set("melee_w_component", spear)
			if is_player_and_UI_valid: ui_comp.melee_info_label.text = "Melee: Spear"
			msg = "Melee Weapon Now: Spear"
		"Sword":
			entity.set("melee_w_component", sword)
			if is_player_and_UI_valid: ui_comp.melee_info_label.text = "Melee: Sword"
			msg = "Melee Weapon Now: Sword"
		"None":
			entity.set("melee_w_component", null)
			if is_player_and_UI_valid: ui_comp.melee_info_label.text = "No Melee Weapon"
			msg = "No Melee Weapon"
			
	# Sequence the UI Message
	if is_player_and_UI_valid and msg != "":
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(ui_comp):
				ui_comp.display_message.rpc_id(entity.name.to_int(), msg)
		)
			
	var active_melee: Node2D = entity.get("melee_w_component")
	if is_instance_valid(active_melee):
		active_melee.show()
		active_melee.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		if is_player_and_UI_valid: ui_comp.melee_w_component = active_melee

# Swaps the active ranged weapon component and updates UI labels while deferring state changes to avoid physics conflicts.
func change_ranged_weapon(weapon_type: String) -> void:
	var fireball: Node = components_container.get_node_or_null("FireballShooterComponent")
	var bow: Node = components_container.get_node_or_null("BowComponent")
	var pin: Node = components_container.get_node_or_null("PinShooterComponent")
	
	for node: Node in [fireball, bow, pin]:
		if is_instance_valid(node):
			node.hide()
			node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

	var msg: String = ""
	match weapon_type:
		"Fireball_Shooter":
			entity.set("ranged_w_component", fireball)
			if is_player_and_UI_valid: ui_comp.ranged_info_label.text = "Ranged: Fireball Shooter"
			msg = "Ranged Weapon Now: Magic Fireball Shooter"
		"Bow":
			entity.set("ranged_w_component", bow)
			if is_player_and_UI_valid: ui_comp.ranged_info_label.text = "Ranged: Bow"
			msg = "Ranged Weapon Now: Bow"
		"Pin_Shooter":
			entity.set("ranged_w_component", pin)
			if is_player_and_UI_valid: ui_comp.ranged_info_label.text = "Ranged: Pin Shooter"
			msg = "Ranged Weapon Now: Juggling Pin Gun"
		"None":
			entity.set("ranged_w_component", null)
			if is_player_and_UI_valid: ui_comp.ranged_info_label.text = "No Ranged Weapon"
			msg = "No Ranged Weapon"

	if is_player_and_UI_valid and msg != "":
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(ui_comp): # Verification check in case player died in 0.3s
				ui_comp.display_message.rpc_id(entity.name.to_int(), msg)
		)
			
	var active_ranged: Node2D = entity.get("ranged_w_component")
	if is_instance_valid(active_ranged):
		active_ranged.show()
		active_ranged.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		if is_player_and_UI_valid: ui_comp.ranged_w_component = active_ranged

# Swaps the active ability component and updates UI labels while deferring state changes to avoid physics conflicts.
func change_first_ability(ability_type: String) -> void:
	var abilities: Dictionary = {
		"Magic": components_container.get_node_or_null("MagicAreaWeaponComponent"),
		"Teleport": components_container.get_node_or_null("TeleportComponent"),
		"Illusion": components_container.get_node_or_null("IllusionComponent"),
		"Stealth": components_container.get_node_or_null("StealthComponent"),
		"Spawner": components_container.get_node_or_null("SpawnerComponent"),
		"Teleport_Crush": components_container.get_node_or_null("TeleportCrushComponent"),
		"WOF": components_container.get_node_or_null("WOFComponent")
	}
	
	for key: String in abilities:
		if is_instance_valid(abilities[key]):
			abilities[key].hide()
			abilities[key].set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
			
	var msg: String = ""
	if abilities.has(ability_type) and is_instance_valid(abilities[ability_type]):
		entity.set("first_ability_component", abilities[ability_type])
		var active_ability: Node2D = entity.get("first_ability_component")
		active_ability.show()
		active_ability.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		if is_player_and_UI_valid: 
			ui_comp.ability_info_label.text = "Ability: " + ability_type.replace("_", " ")
		msg = "First Ability Now: " + ability_type.replace("_", " ")
	else:
		entity.set("first_ability_component", null)
		if is_player_and_UI_valid: ui_comp.ability_info_label.text = "No First Ability"
		msg = "No First Ability"
		
	# Sequence the UI Message
	if is_player_and_UI_valid and msg != "":
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(ui_comp):
				ui_comp.display_message.rpc_id(entity.name.to_int(), msg)
		)
		
	if is_player_and_UI_valid:
		ui_comp.first_ability_component = entity.get("first_ability_component")
		ui_comp.current_first_ability = ability_type

# Swaps the active shield component and updates the physical state while deferring property assignments.
func change_shield(shield_type: String) -> void:
	var wooden: Node = components_container.get_node_or_null("WoodenShieldComponent")
	var magic: Node = components_container.get_node_or_null("MagicShieldComponent")
	
	if is_instance_valid(wooden):
		wooden.hide()
		wooden.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	if is_instance_valid(magic):
		magic.hide()
		magic.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		
	match shield_type:
		"Wooden":
			entity.set("shield_component", wooden)
		"Magic":
			entity.set("shield_component", magic)
		"None":
			entity.set("shield_component", null)
			
	var active_shield: Node2D = entity.get("shield_component")
	if is_instance_valid(active_shield):
		active_shield.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		if is_player_and_UI_valid: ui_comp.shield_component = active_shield
