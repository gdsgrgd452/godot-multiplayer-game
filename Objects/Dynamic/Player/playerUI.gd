extends UIComponent

@onready var hud: CanvasLayer = $"../HUD"
@onready var ui_container = $"../UI"

@onready var movement_component: Node = $"../Components/MovementComponent"
@onready var health_component: Node = $"../Components/HealthComponent"
@onready var leveling_component: Node = $"../Components/LevelingComponent"
@onready var promotion_component: Node = $"../Components/PromotionComponent"
@onready var sprite_component: Sprite2D = $"../SpriteComponent"

@onready var melee_info_label: Label = $"../HUD/PromotionInfoLabel/MeleeWeapon"
@onready var ranged_info_label: Label = $"../HUD/PromotionInfoLabel/RangedWeapon"
@onready var ability_info_label: Label = $"../HUD/PromotionInfoLabel/Ability"
@onready var second_ability_info_label: Label = $"../HUD/PromotionInfoLabel/Ability2"

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
@onready var promotion_UI: HBoxContainer = $"../HUD/PromotionUI"

@onready var leaderboard_container: VBoxContainer = $"../HUD/LBContainer/Leaderboard"
@export var lb_entry_scene: PackedScene

@onready var first_ability_bar: EntityBar = $"../HUD/FirstAbilityBar"
@onready var second_ability_bar: EntityBar = $"../HUD/SecondAbilityBar"

@onready var reload_bar: EntityBar = $"../UI/ReloadBar"
@onready var melee_bar: EntityBar = $"../UI/MeleeBar"

func _ready() -> void:
	name_label.text = entity.name
	if entity.name == str(multiplayer.get_unique_id()):
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		promotion_component.show_promotion_menu.connect(_show_promotion_menu)
		hud.show() 
		first_ability_bar.hide()
		second_ability_bar.hide()
		reload_bar.hide()
		melee_bar.hide()
		ui_container.show()
		upgrade_UI.hide()
		promotion_UI.hide()

	else: # Hides all UI for other players
		hud.hide()
		ui_container.hide()
		upgrade_UI.hide()
		promotion_UI.hide()

	toggle_external_ui(false) # Shows external UIs (Health, name) for other players

# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden
	print("This needs checking: " + str(health_bar.visible))

# Populates the upgrade UI with valid random stat choices based on equipped capabilities.
func _show_upgrade_menu(upgrade_count: int) -> void:
	if upgrade_count < 1:
		printerr("Called to show upgrade menu without an upgrade")
		return
	
	var ui_children: Array[Node] = upgrade_UI.get_children()
	for child: Node in ui_children: 
		child.hide()
	
	var curr_class: String = entity.current_class
	var valid_stats_dict: Dictionary = promotion_component.class_base_stats[curr_class]
	var valid_stats: Array = valid_stats_dict.keys()
	valid_stats = valid_stats.filter(func(stat: String) -> bool: return not leveling_component.is_stat_maxed(stat))

	if valid_stats.size() <= 0:
		upgrade_UI.hide()
		return
	
	var buttons: Array[Node] = ui_children.filter(func(b: Node) -> bool: return b is Button)
	valid_stats.shuffle()

	var button_w_valid_count: int = min(buttons.size(), valid_stats.size())

	for i: int in button_w_valid_count:
		var stat: String = valid_stats[i]
		var current_lvl: int = leveling_component.stat_levels.get(stat, 1)
		
		buttons[i].stat_id = stat + " Lvl " + str(current_lvl)
		buttons[i].refresh_text()
		
		# Update progress bar: (current_level / 10.0) * 100
		var progress_percent: float = (float(current_lvl) / 10.0) * 100.0
		buttons[i].update_progress_bar(progress_percent)
		buttons[i].show()
	
	ui_children[0].show()
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
			button.show()
		else:
			button.hide()
			
	promotion_UI.show()

# Updates the local leaderboard UI with data broadcasted from the server.
func update_leaderboard_ui(entries: Array) -> void:
	if not leaderboard_container:
		printerr("No leaderboard container found")
		return
		
	for child in leaderboard_container.get_children():
		child.queue_free()
		
	var my_id: String = str(multiplayer.get_unique_id())
	
	for i: int in range(entries.size()):
		var p_data: Dictionary = entries[i]
		var entry_text = str(i + 1) + ". " + p_data["id"] + " - Score: " + str(p_data["score"]) + " - T: " + str(p_data["team_id"])
		
		if lb_entry_scene:
			var entry = lb_entry_scene.instantiate()
			var label_to_color: Label = null
			
			if entry is Label:
				entry.text = entry_text
				label_to_color = entry
			elif entry.has_node("Label"):
				var lbl = entry.get_node("Label")
				lbl.text = entry_text
				label_to_color = lbl
			else:
				var lbl = Label.new()
				lbl.text = entry_text
				entry.add_child(lbl)
				label_to_color = lbl
				
			if label_to_color:
				if p_data["id"] == my_id:
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

# Updates the debug info display.
func _process(_delta: float) -> void:
	if entity.name == str(multiplayer.get_unique_id()): 
		show_debug_info()

# Compiles and displays internal entity variables to the local HUD.
func show_debug_info() -> void:
	
	#POSITION AND SPEED
	var pos_text: String = "Position: " + str(Vector2(int(entity.position.x), int(entity.position.y))) + "\n"
	var speed_text: String = "Speed: " + str(movement_component.move_speed) + "\n\n"

	#HEALTH
	var max_health_text: String = "Max Health: " + str(health_component.max_health) + "\n"
	var health_text: String = "Health: " + str(health_component.health) + "\n"
	var regen_amount_text: String = "Regen Amount: " + str(health_component.regen_amount) + "\n"
	var regen_speed_text: String = "Regen Speed: " + str(health_component.regen_speed) + "\n"
	var regen_cooldown_text: String = "Regen Cooldown: " + str(snapped(health_component.regen_cooldown, 0.1)) + "\n\n"
	
	#KNOCKBACK AND BODY DAMAGE
	var kb_text: String = "Knockback: " + str(Vector2(int(entity.knockback.x), int(entity.knockback.y))) + "\n"
	var body_dmg_text: String = "Body Damage: " + str(entity.body_damage) + "\n\n"
	
	stats_label_one.text = max_health_text + health_text + regen_amount_text + regen_speed_text + regen_cooldown_text + pos_text + speed_text + kb_text + body_dmg_text
	
	#RANGED COMBAT
	if ranged_w_component:
		var projectile_dmg_text: String = "Projectile Damage: " + str(ranged_w_component.projectile_damage) + "\n"
		var projectile_speed_text: String = "Projectile Speed: " + str(ranged_w_component.projectile_speed) + "\n\n"
		var reload_time_text: String = "Reload Time: " + str(ranged_w_component.reload_speed)+ "\n"
		var cooldown_text: String = "Cooldown: " + str(snapped(ranged_w_component.shot_cooldown, 0.01)) + "\n"
		var accuracy_text: String = "Accuracy: " + str(snapped(ranged_w_component.accuracy, 0.01)) + "\n\n"
		stats_label_one.text += projectile_dmg_text + projectile_speed_text + reload_time_text + cooldown_text + accuracy_text
	else:
		var no_ranged_text: String = "No Ranged Weapon" + "\n" + "\n"
		stats_label_one.text += no_ranged_text
	
	#MELEE COMBAT
	if melee_w_component:
		var melee_dmg_text: String = "Melee Damage: " + str(melee_w_component.melee_damage) + "\n"
		var melee_kb_text: String = "Melee Knockback: " + str(melee_w_component.knockback_force) + "\n"
		var melee_cooldown_text: String = "Melee Cooldown: " + str(melee_w_component.attack_cooldown) + "\n"
		var melee_duration_text: String = "Melee Attack Duration: " + str(melee_w_component.attack_duration) + "\n"
		var melee_has_hit_text: String = "Melee Has Hit: " + str(melee_w_component.has_hit) + "\n\n"
		stats_label_one.text += melee_dmg_text + melee_kb_text + melee_cooldown_text + melee_duration_text + melee_has_hit_text
	else:
		var no_melee_text: String = "No Melee Weapon"  + "\n" + "\n"
		stats_label_one.text += no_melee_text

	# FIRST ABILITY
	if first_ability_component:
		match current_first_ability:
			"Magic":
				var area_damage_text: String = "Area Damage: " + str(first_ability_component.area_damage) + "\n"
				var area_kb_text: String = "Area Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var area_radius_text: String = "Area Radius: " + str(first_ability_component.max_radius) + "\n"
				var area_cooldown_text: String = "Area Cooldown: " + str(first_ability_component.area_cooldown) + "\n\n"
				stats_label_two.text = area_damage_text + area_kb_text + area_radius_text + area_cooldown_text
			"Teleport":
				var tele_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.teleport_cooldown) + "\n"
				var tele_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tele_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_two.text = tele_cooldown_text + tele_duration_text + tele_range_text
			"Illusion":
				var illu_cooldown_text: String = "Illusion Cooldown: " + str(first_ability_component.illusion_cooldown) + "\n"
				var illu_duration_text: String = "Illusion Duration: " + str(first_ability_component.illusion_duration) + "\n"
				var illu_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var illu_amount_text: String = "Illusion Amount: " + str(first_ability_component.illusions_count) + "\n\n"
				stats_label_two.text = illu_cooldown_text + illu_time_text + illu_duration_text + illu_amount_text
			"Stealth":
				var stealth_cd_text: String = "Stealth Cooldown: " + str(first_ability_component.stealth_cooldown) + "\n"
				var stealth_dur_text: String = "Stealth Duration: " + str(first_ability_component.stealth_duration) + "\n"
				var stealth_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n\n"
				stats_label_two.text = stealth_cd_text + stealth_dur_text + stealth_time_text
			"Spawner":
				var spawner_cd_text: String = "Spawner Cooldown: " + str(first_ability_component.spawner_cooldown) + "\n"
				var spawner_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var spawner_spawns_text: String = "Current spawns: " + str(first_ability_component.current_spawns) + "\n"
				var spawner_max_spawns_text: String = "Max spawns: " + str(first_ability_component.max_spawns) + "\n\n"
				stats_label_two.text = spawner_cd_text + spawner_time_text + spawner_spawns_text + spawner_max_spawns_text
			"Teleport_Crush":
				var tpc_damage_text: String = "Teleport Damage: " + str(first_ability_component.area_damage) + "\n"
				var tpc_kb_text: String = "Teleport Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var tpc_radius_text: String = "Teleport AoE Radius: " + str(first_ability_component.max_radius) + "\n"
				var tpc_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.tp_crush_cooldown) + "\n"
				var tpc_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tpc_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_two.text = tpc_damage_text + tpc_kb_text + tpc_radius_text + tpc_cooldown_text + tpc_time_text + tpc_range_text
			"WOF":
				var wof_cd_text = "WOF Cooldown: " + str(first_ability_component.wof_cooldown) + "\n"
				var wof_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var wof_length_text: String = "Max Length: " + str(snapped(first_ability_component.max_length, 0.1)) + "\n"
				var wof_damage_text = "WOF Max Damage: " + str(first_ability_component.max_damage) + "\n\n"
				stats_label_two.text = wof_cd_text + wof_time_text + wof_length_text + wof_damage_text
			"Mass_Heal":
				var heal_cd_text = "Heal Cooldown: " + str(first_ability_component.mass_heal_cooldown) + "\n"
				var heal_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var heal_amount_text = "Heal Amount: " + str(first_ability_component.mass_heal_amount) + "\n\n"
				stats_label_two.text = heal_cd_text + heal_time_text + heal_amount_text
	else:
		var no_ability_text: String = "No First Ability" + "\n" + "\n"
		stats_label_two.text = no_ability_text
	
	if second_ability_component:
		match current_second_ability:
			"Spawner":
				var spawner_cd_text: String = "Spawner Cooldown: " + str(second_ability_component.spawner_cooldown) + "\n"
				var spawner_time_text: String = "Til next: " + str(snapped(second_ability_component.current_cooldown, 0.1)) + "\n"
				var spawner_spawns_text: String = "Current spawns: " + str(second_ability_component.current_spawns) + "\n"
				var spawner_max_spawns_text: String = "Max spawns: " + str(second_ability_component.max_spawns) + "\n\n"
				stats_label_two.text += spawner_cd_text + spawner_time_text + spawner_spawns_text + spawner_max_spawns_text
			"Mass_Heal":
				var heal_cd_text = "Heal Cooldown: " + str(second_ability_component.mass_heal_cooldown) + "\n"
				var heal_time_text: String = "Til next: " + str(snapped(second_ability_component.current_cooldown, 0.1)) + "\n"
				var heal_amount_text = "Heal Amount: " + str(second_ability_component.mass_heal_amount) + "\n\n"
				stats_label_two.text += heal_cd_text + heal_time_text + heal_amount_text
			"WOF":
				var wof_cd_text = "WOF Cooldown: " + str(second_ability_component.wof_cooldown) + "\n"
				var wof_time_text: String = "Til next: " + str(snapped(second_ability_component.current_cooldown, 0.1)) + "\n"
				var wof_length_text: String = "Max Length: " + str(snapped(second_ability_component.max_length, 0.1)) + "\n"
				var wof_damage_text = "WOF Max Damage: " + str(second_ability_component.max_damage) + "\n\n"
				stats_label_two.text += wof_cd_text + wof_time_text + wof_length_text + wof_damage_text
	else:
		var no_ability_text: String = "No Second Ability" + "\n" + "\n"
		stats_label_two.text += no_ability_text
		
	# SHIELD
	if shield_component:
		var max_shield_health_text = "Max Shield Health: " + str(shield_component.max_shield_health) + "\n"
		var shield_health_text = "Shield Health: " + str(shield_component.shield_health) + "\n"
		var duration_text = "Total Shield Duration: " + str(shield_component.active_duration) + "\n\n"
		stats_label_two.text += max_shield_health_text + shield_health_text + duration_text
	else:
		var no_shield_text: String = "No Shield" + "\n" + "\n"
		stats_label_two.text += no_shield_text
	
	#PROMOTIONS AND UPGRADES
	var pending_upgrades_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	var pending_promotions_text: String = "Pending Promotions: " + str(promotion_component.pending_promotions) + "\n"
	# Down the right side
	stats_label_two.text += pending_upgrades_text + pending_promotions_text

	#POINTS AND LEVELLING
	var entity_level_text: String = "Level: " + str(leveling_component.entity_level)
	var next_level_points_text: String = "    Points for next: " + str(leveling_component.next_level_points)
	var points_text: String = "    Points: " + str(leveling_component.points) 
	var score_text: String = "    Score: " + str(leveling_component.total_score)

	# Below the level bar
	level_label.text = entity_level_text + next_level_points_text + points_text + score_text
