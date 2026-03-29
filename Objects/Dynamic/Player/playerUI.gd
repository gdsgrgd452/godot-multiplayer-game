extends Node2D

@onready var entity: CharacterBody2D = get_parent()

@onready var movement_component: Node = $"../Components/MovementComponent"
@onready var health_component: Node = $"../Components/HealthComponent"
@onready var leveling_component: Node = $"../Components/LevelingComponent"
@onready var promotion_component: Node = $"../Components/PromotionComponent"
@onready var sprite_component: Sprite2D = $"../SpriteComponent"

@onready var melee_info_label: Label = $"../HUD/PromotionInfoLabel/MeleeWeapon"
@onready var ranged_info_label: Label = $"../HUD/PromotionInfoLabel/RangedWeapon"
@onready var ability_info_label: Label = $"../HUD/PromotionInfoLabel/Ability"

var melee_w_component: Node
var ranged_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var shield_component: Node

var current_first_ability: String

@onready var health_bar: ProgressBar = $"../HealthBar"

@onready var name_label: Label = $"../Name"
@onready var stats_label_one: Label = $"../HUD/StatsLabel"
@onready var stats_label_two: Label = $"../HUD/StatsLabel2"
@onready var level_label: Label = $"../HUD/LevelBar/LevelLabel"

@onready var upgrade_UI: VBoxContainer = $"../HUD/UpgradeUI"
@onready var promotion_UI: HBoxContainer = $"../HUD/PromotionUI"

@onready var leaderboard_label: Label = $"../HUD/LeaderboardLabel"

func _ready() -> void:
	name_label.text = "Player " + entity.name.substr(0, 4)
	if entity.name == str(multiplayer.get_unique_id()):
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		promotion_component.show_promotion_menu.connect(_show_promotion_menu)
		if not health_component:
			printerr("No health component")

# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden
	print("This needs checking: " + str(health_bar.visible))

# Populates the upgrade UI with valid random stat choices based on equipped capabilities.
func _show_upgrade_menu() -> void:
	if leveling_component.pending_upgrades < 1:
		printerr("Called to show upgrade menu without an upgrade")
		return
	
	# Hides all (Incl "Upgrade")
	var ui_children: Array[Node] = upgrade_UI.get_children()
	for child: Node in ui_children: 
		child.hide()
	
	var curr_class: String = entity.current_class
	var valid_stats_dict: Dictionary = promotion_component.class_base_stats[curr_class] # The base stats
	var valid_stats: Array = valid_stats_dict.keys() # The stats the class has
	#print("Valid stats for your class: " + str(valid_stats) + "\n")
	valid_stats = valid_stats.filter(func(stat): return not promotion_component.is_stat_maxed(stat)) # Remove any stats that are already maxed
	#print("Valid stats (Not max) for your class: " + str(valid_stats)) 

	if valid_stats.size() <= 0:
		upgrade_UI.hide()
		return
	
	var buttons: Array[Node] = ui_children.filter(func(b): return b is Button)  # Removes the label

	valid_stats.shuffle()

	var button_w_valid_count: int = min(buttons.size(), valid_stats.size())

	for i: int in button_w_valid_count:
		var stat: String = valid_stats[i]
		buttons[i].stat_id = stat + " X" + str(snapped(leveling_component.stat_multipliers.get(stat), 0.01))
		buttons[i].refresh_text()
		
		if not valid_stats_dict.keys().has(stat):
			printerr("Not found " + stat + " In " + curr_class )
		
		var curr_class_stat_base = valid_stats_dict[stat]
		if not promotion_component.max_stats.has(stat):
			printerr("Stat not in max stats: " + str(promotion_component.max_stats))

		var stat_max = promotion_component.max_stats[stat]
		
		buttons[i].update_progress_bar((curr_class_stat_base/stat_max)*100)
		buttons[i].show()
	
	ui_children[0].show() # Shows "Upgrades"
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
func update_leaderboard_ui(board_text: String) -> void:
	if leaderboard_label:
		leaderboard_label.text = board_text
	else:
		printerr("No leaderboard label")
		
@rpc("any_peer", "call_local", "reliable")
func display_message(message: String) -> void:
	var label = Label.new()
	add_child(label)
	
	if message.contains("Upgraded"):
		var stat_button: Node = get_parent().get_node_or_null("HUD/UpgradeUI/StatButton")
		if stat_button:
			label.text = stat_button.format_stat_name(message)
			label.modulate = ColourUtils.get_colour_based_on_type(message.split(" ")[1])
		else:
			label.text = message
	else:
		label.text = message
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	
	label.add_theme_font_size_override("font_size", 70)
	
	var vertical_offset: float = -200.0 * entity.scale.y
	
	label.global_position = entity.global_position + Vector2(-100, vertical_offset)
	
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "global_position:y", label.global_position.y - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	label.scale = Vector2(0.5, 0.5)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(1.0)
	fade_tween.tween_property(label, "modulate:a", 0.0, 2.0)

	tween.chain().tween_callback(label.queue_free)

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
		var shoot_text: String = "Shooting: " + str(ranged_w_component.shooting) + "\n"
		var reload_time_text: String = "Reload Time: " + str(ranged_w_component.reload_speed)+ "\n"
		var cooldown_text: String = "Cooldown: " + str(snapped(ranged_w_component.shot_cooldown, 0.01)) + "\n"
		var accuracy_text: String = "Accuracy: " + str(snapped(ranged_w_component.accuracy, 0.01)) + "\n\n"
		stats_label_one.text += projectile_dmg_text + projectile_speed_text + shoot_text + reload_time_text + cooldown_text + accuracy_text
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
				var area_cooldown_text: String = "Area Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var area_duration_text: String = "Area Attack Duration: " + str(first_ability_component.attack_duration) + "\n\n"
				stats_label_two.text = area_damage_text + area_kb_text + area_radius_text + area_cooldown_text + area_duration_text
			"Teleport":
				var tele_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tele_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tele_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_two.text = tele_cooldown_text + tele_duration_text + tele_range_text
			"Illusion":
				var illu_cooldown_text: String = "Illusion Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var illu_duration_text: String = "Illusion Duration: " + str(first_ability_component.illusion_duration) + "\n"
				var illu_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var illu_amount_text: String = "Illusion Amount: " + str(first_ability_component.illusions_count) + "\n\n"
				stats_label_two.text = illu_cooldown_text + illu_time_text + illu_duration_text + illu_amount_text
			"Stealth":
				var stealth_cd_text: String = "Stealth Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var stealth_dur_text: String = "Stealth Duration: " + str(first_ability_component.stealth_duration) + "\n"
				var stealth_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n\n"
				stats_label_two.text = stealth_cd_text + stealth_dur_text + stealth_time_text
			"Spawner":
				var spawner_cd_text: String = "Spawner Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var spawner_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var spawner_spawns_text: String = "Current spawns: " + str(first_ability_component.current_spawns) + "\n"
				var spawner_max_spawns_text: String = "Max spawns: " + str(first_ability_component.max_spawns) + "\n\n"
				stats_label_two.text = spawner_cd_text + spawner_time_text + spawner_spawns_text + spawner_max_spawns_text
			"Teleport_Crush":
				var tpc_damage_text: String = "Teleport Damage: " + str(first_ability_component.area_damage) + "\n"
				var tpc_kb_text: String = "Teleport Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var tpc_radius_text: String = "Teleport AoE Radius: " + str(first_ability_component.max_radius) + "\n"
				var tpc_area_duration_text: String = "Area Attack Duration: " + str(first_ability_component.attack_duration) + "\n\n"
				var tpc_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tpc_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tpc_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_two.text = tpc_damage_text + tpc_kb_text + tpc_radius_text + tpc_area_duration_text + tpc_cooldown_text + tpc_duration_text + tpc_range_text
	else:
		var no_ability_text: String = "No First Ability" + "\n" + "\n"
		stats_label_two.text = no_ability_text
		
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
