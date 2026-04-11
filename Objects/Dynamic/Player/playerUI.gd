extends UIComponent

@onready var hud: CanvasLayer = $"../HUD"
@onready var ui_container: Control = $"../UI"

@onready var movement_component: Node = $"../Components/MovementComponent"
@onready var health_component: Node = $"../Components/HealthComponent"
@onready var leveling_component: Node = $"../Components/LevelingComponent"
@onready var promotion_component: Node = $"../Components/PromotionComponent"
@onready var sprite_component: Sprite2D = $"../SpriteComponent"

@onready var melee_info_label: Label = $"../HUD/PromotionInfoLabel/Melee"
@onready var melee_info_label_image: TextureRect = $"../HUD/PromotionInfoLabel/Melee/Image"
@onready var ranged_info_label: Label = $"../HUD/PromotionInfoLabel/Ranged"
@onready var ranged_info_label_image: TextureRect = $"../HUD/PromotionInfoLabel/Ranged/Image"
@onready var ability_info_label: Label = $"../HUD/FirstAbilityBar/FirstAbilityBarLabel"
@onready var second_ability_info_label: Label = $"../HUD/SecondAbilityBar/SecondAbilityBarLabel"

var melee_w_component: Node
var ranged_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var second_ability_component: Node
var shield_component: Node

var current_first_ability: String
var current_second_ability: String

@onready var health_bar: ProgressBar = $"../UI/HealthBar"

@onready var name_label: Label = $"../UI/Name"
@onready var stats_label_one: Label = $"../HUD/StatsLabel"
@onready var stats_label_two: Label = $"../HUD/StatsLabel2"
@onready var level_label: Label = $"../HUD/LevelBar/LevelLabel"

@onready var upgrade_UI: VBoxContainer = $"../HUD/UpgradeUI"
@onready var promotion_UI_label: Label = $"../HUD/PromotionUILabel"
@onready var promotion_UI: HBoxContainer = $"../HUD/PromotionUILabel/PromotionUI"

@onready var leaderboard_container: VBoxContainer = $"../HUD/LBContainer/Leaderboard"
@export var lb_entry_scene: PackedScene

@onready var first_ability_bar: EntityBar = $"../HUD/FirstAbilityBar"
@onready var second_ability_bar: EntityBar = $"../HUD/SecondAbilityBar"

@onready var reload_bar: EntityBar = $"../UI/ReloadBar"
@onready var melee_bar: EntityBar = $"../UI/MeleeBar"

func _ready() -> void:
	ui_container.show()
	reload_bar.hide()
	melee_bar.hide()
	first_ability_bar.hide()
	second_ability_bar.hide()
	promotion_UI_label.hide()
	upgrade_UI.hide()

	if entity.name == str(multiplayer.get_unique_id()):
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		promotion_component.show_promotion_menu.connect(_show_promotion_menu)
		hud.show() 
	else: # Hides these for other players
		hud.hide()
		

# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden

# Populates the upgrade UI with valid random stat choices based on equipped capabilities.
func _show_upgrade_menu(upgrade_count: int, levels: Dictionary) -> void:
	if upgrade_count < 1:
		printerr("Called to show upgrade menu without an upgrade")
		return
	
	var ui_children: Array[Node] = upgrade_UI.get_children()
	for child: Node in ui_children: 
		child.hide()
	
	var curr_class: String = entity.current_class
	var valid_stats_dict: Dictionary = PromoUtils.get_base_stats_for_class(curr_class)
	var valid_stats: Array = valid_stats_dict.keys()
	valid_stats = valid_stats.filter(func(stat: String) -> bool:
		return levels.get(stat, 0) < 10
	)

	if valid_stats.size() <= 0:
		upgrade_UI.hide()
		return
	
	var buttons: Array[Node] = ui_children.filter(func(b: Node) -> bool: return b is Button)
	valid_stats.shuffle()

	var button_w_valid_count: int = min(buttons.size(), valid_stats.size())

	for i: int in button_w_valid_count:
		var stat: String = valid_stats[i]
		var current_lvl: int = levels.get(stat, 0)
		
		buttons[i].stat_id = stat + " Lvl " + str(current_lvl)
		buttons[i].refresh_text()
		
		# Update progress bar: (current_level / 10.0) * 100
		var progress_percent: float = (float(current_lvl) / 10.0) * 100.0
		buttons[i].update_progress_bar(progress_percent)
		buttons[i].show()
	
	ui_children[0].show() # Shows the label
	upgrade_UI.show()

# Populates the promotion UI with the available class types
func _show_promotion_menu(available_classes: Array[String]) -> void:
	var buttons: Array[Node] = promotion_UI.get_children()

	for i: int in buttons.size():
		var button: Node = buttons[i]
		
		if button is not Button: # The label
			continue
		
		if i < available_classes.size():
			var type: String = available_classes[i]
			button.type_id = type
			button.tooltip_text = PromoUtils.get_tooltip_for_class(type)
			button.show()
		else:
			button.hide()
	
	promotion_UI_label.show()
	promotion_UI.show()


# Updates the local leaderboard UI with data broadcasted from the server.
func update_leaderboard_ui(entries: Array) -> void:
	if not leaderboard_container:
		printerr("No leaderboard container found")
		return
		
	for child in leaderboard_container.get_children():
		child.queue_free()
			
	for i: int in range(entries.size()):
		var p_data: Dictionary = entries[i]
		var entry_text: String = str(i + 1) + ". " + p_data["id"] + " - Score: " + str(p_data["score"]) + " - T: " + str(p_data["team_id"])
		
		if lb_entry_scene:
			var entry: Label = lb_entry_scene.instantiate()
			var label_to_color: Label = null
			
			if entry is Label:
				entry.text = entry_text
				label_to_color = entry
			elif entry.has_node("Label"):
				var lbl: Label = entry.get_node("Label")
				lbl.text = entry_text
				label_to_color = lbl
			else:
				var lbl: Label = Label.new()
				lbl.text = entry_text
				entry.add_child(lbl)
				label_to_color = lbl
				
			if label_to_color:
				if p_data["id"] == entity.player_username:
					label_to_color.modulate = Color.GREEN
				else:
					label_to_color.modulate = Color.RED
				
				
			leaderboard_container.add_child(entry)


# Initiates the server-side logic to synchronize attack cooldown visuals for melee or ranged weapons.
func handle_attack_activated(type: String, cooldown: float) -> void:
	if not multiplayer.is_server():
		return
		
	trigger_attack_ui.rpc(type, cooldown)

# Animates the specific reload or melee bar on the local player's client to reflect weapon readiness.
@rpc("authority", "call_local", "reliable")
func trigger_attack_ui(type: String, max_cooldown: float) -> void:
	if not entity.is_in_group("player") or entity.name != str(multiplayer.get_unique_id()):
		return
		
	var bar: EntityBar = null
	match type:
		"Melee":
			bar = get("melee_bar")
		"Ranged":
			bar = get("reload_bar")
			
	if is_instance_valid(bar):
		bar.show()
		bar.max_value = max_cooldown
		bar.value = max_cooldown
		bar.animate_value(0.0, max_cooldown, max_cooldown)
		
		if bar.bar_tween:
			bar.bar_tween.finished.connect(func() -> void: 
				if is_instance_valid(bar): 
					bar.hide()
			)

# Triggers the visual message and cooldown bar animation for a specific ability slot.
func handle_ability_activated(caller: Node2D, ability_name: String, cooldown: float) -> void:
	if not multiplayer.is_server():
		return
		
	var is_secondary: bool = false
	if caller == get("second_ability_component"):
		is_secondary = true
		
	trigger_ability_ui.rpc(ability_name, cooldown, is_secondary)

# Displays the ability usage message and animates the corresponding cooldown bar on all clients.
@rpc("authority", "call_local", "reliable")
func trigger_ability_ui(ability_name: String, max_cooldown: float, is_secondary: bool) -> void:
	display_message("Used: " + ability_name.replace("_", " "))
	
	if not entity.is_in_group("player") or entity.name != str(multiplayer.get_unique_id()):
		return
		
	var bar: EntityBar = get("second_ability_bar") if is_secondary else get("first_ability_bar")
	if is_instance_valid(bar):
		bar.show()
		bar.max_value = max_cooldown
		bar.value = max_cooldown
		bar.animate_value(0.0, max_cooldown, max_cooldown)
		
		if bar.bar_tween:
			bar.bar_tween.finished.connect(func() -> void: if is_instance_valid(bar): bar.hide())

# Sets the UI on the left side of the screen for the melee and ranged weapons
func update_weapon_ui(m_or_r: String, weapon_type: String) -> void:
	var ui_text: String = weapon_type.replace("_", " ")
	var weapon_img: Texture2D = ImageUtils.get_image_by_component_name(weapon_type)

	if m_or_r == "melee":
		melee_info_label.text = ui_text
		melee_info_label_image.texture = weapon_img
	elif m_or_r == "ranged":
		ranged_info_label.text = ui_text
		ranged_info_label_image.texture = weapon_img

# Switches between showing the ranged and melee components on the side
func toggle_weapon_ui(type) -> void:
	match type:
		entity.WeaponType.Melee:
			ranged_info_label.hide()
			melee_info_label.show()
		entity.WeaponType.Ranged:
			melee_info_label.hide()
			ranged_info_label.show()
	
# Processes server-side debug compilation and transmits formatted strings to the owner client.
func _process(_delta: float) -> void:
	if multiplayer.is_server():
		_server_compile_debug_info()

# Gathers all internal entity and component variables on the server to format the HUD strings.
func _server_compile_debug_info() -> void:
	if not is_instance_valid(entity) or not entity.is_in_group("player"):
		return
		
	var target_peer: int = entity.name.to_int()
	
	var stats_1: String = "Position: " + str(Vector2(int(entity.position.x), int(entity.position.y))) + "\n"
	stats_1 += "Speed: " + str(movement_component.get("move_speed")) + "\n\n"

	stats_1 += "Max Health: " + str(health_component.max_health) + "\n"
	stats_1 += "Health: " + str(int(health_component.health)) + "\n"
	stats_1 += "Regen Amount: " + str(health_component.regen_amount) + "\n"
	stats_1 += "Regen Speed: " + str(health_component.regen_speed) + "\n"
	stats_1 += "Regen Cooldown: " + str(snapped(health_component.regen_cooldown, 0.1)) + "\n\n"
	
	stats_1 += "Knockback: " + str(Vector2(int(entity.knockback.x), int(entity.knockback.y))) + "\n"
	stats_1 += "Body Damage: " + str(entity.body_damage) + "\n\n"
	
	if is_instance_valid(ranged_w_component):
		stats_1 += "Proj Dmg: " + str(ranged_w_component.projectile_damage) + "\n"
		stats_1 += "Proj Spd: " + str(ranged_w_component.projectile_speed) + "\n"
		stats_1 += "Charge Time: " + str(ranged_w_component.max_charge_time) + "\n"
		stats_1 += "Charge: " + str(snapped(ranged_w_component.charge_timer, 0.01)) + "\n"
		stats_1 += "Acc: " + str(snapped(ranged_w_component.accuracy, 0.01)) + "\n\n"
	else:
		stats_1 += "No Ranged Weapon\n\n"
	
	if is_instance_valid(melee_w_component):
		stats_1 += "Melee Dmg: " + str(melee_w_component.melee_damage) + "\n"
		stats_1 += "Melee KB: " + str(melee_w_component.knockback_force) + "\n"
		stats_1 += "Melee CD: " + str(melee_w_component.attack_cooldown) + "\n"
		stats_1 += "Melee Dur: " + str(melee_w_component.attack_duration) + "\n"
		stats_1 += "Has Hit: " + str(melee_w_component.has_hit) + "\n\n"
	else:
		stats_1 += "No Melee Weapon\n\n"

	var stats_2: String = _get_ability_debug_text(first_ability_component, current_first_ability, "Ability 1")
	stats_2 += _get_ability_debug_text(second_ability_component, current_second_ability, "Ability 2")
		
	if is_instance_valid(shield_component):
		stats_2 += "Max Shield HP: " + str(shield_component.get("max_shield_health")) + "\n"
		stats_2 += "Shield HP: " + str(shield_component.get("shield_health")) + "\n"
		stats_2 += "Shield Duration: " + str(shield_component.get("active_duration")) + "\n\n"
	else:
		stats_2 += "No Shield\n\n"
	
	stats_2 += "Pending Upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	stats_2 += "Pending Promos: " + str(promotion_component.pending_promotions) + "\n"

	var level_text: String = "Lvl: " + str(leveling_component.entity_level)
	level_text += "  Next: " + str(leveling_component.next_level_points)
	level_text += "  Pts: " + str(leveling_component.points) 
	level_text += "  Score: " + str(leveling_component.total_score)

	update_debug_labels.rpc_id(target_peer, stats_1, stats_2, level_text)

# Returns a formatted string containing all specific stat variables for a given ability component.
func _get_ability_debug_text(comp: Node2D, type_name: String, slot_label: String) -> String:
	if not is_instance_valid(comp) or type_name == "None":
		return slot_label + ": None\n\n"
		
	var text: String = slot_label + ": " + type_name + "\n"
	text += "Til Next: " + str(snapped(comp.get("current_cooldown"), 0.1)) + "\n"
	
	match type_name:
		"Magic":
			text += "Area Dmg: " + str(comp.get("area_damage")) + "\n"
			text += "Area KB: " + str(comp.get("knockback_force")) + "\n"
			text += "Area Radius: " + str(comp.get("max_radius")) + "\n"
			text += "Area CD: " + str(comp.get("area_cooldown")) + "\n"
		"Teleport":
			text += "Tele CD: " + str(comp.get("teleport_cooldown")) + "\n"
			text += "Tele Range: " + str(comp.get("max_range")) + "\n"
		"Illusion":
			text += "Illu CD: " + str(comp.get("illusion_cooldown")) + "\n"
			text += "Illu Dur: " + str(comp.get("illusion_duration")) + "\n"
			text += "Illu Count: " + str(comp.get("illusions_count")) + "\n"
		"Stealth":
			text += "Stealth CD: " + str(comp.get("stealth_cooldown")) + "\n"
			text += "Stealth Dur: " + str(comp.get("stealth_duration")) + "\n"
		"Spawner":
			text += "Spawn CD: " + str(comp.get("spawner_cooldown")) + "\n"
			text += "Max Spawns: " + str(comp.get("max_spawns")) + "\n"
		"Teleport_Crush":
			text += "TPC Dmg: " + str(comp.get("area_damage")) + "\n"
			text += "TPC KB: " + str(comp.get("knockback_force")) + "\n"
			text += "TPC Radius: " + str(comp.get("max_radius")) + "\n"
			text += "TPC CD: " + str(comp.get("tp_crush_cooldown")) + "\n"
			text += "TPC Range: " + str(comp.get("max_range")) + "\n"
		"WOF":
			text += "WOF CD: " + str(comp.get("wof_cooldown")) + "\n"
			text += "WOF Max Length: " + str(comp.get("max_length")) + "\n"
			text += "WOF Dmg: " + str(comp.get("max_damage")) + "\n"
		"Mass_Heal":
			text += "Heal CD: " + str(comp.get("mass_heal_cooldown")) + "\n"
			text += "Heal Amt: " + str(comp.get("mass_heal_amount")) + "\n"
			
	return text + "\n"

# Updates the text content of the local HUD labels based on server-received data.
@rpc("authority", "call_local", "unreliable")
func update_debug_labels(s1: String, s2: String, l_text: String) -> void:
	stats_label_one.text = s1
	stats_label_two.text = s2
	level_label.text = l_text
