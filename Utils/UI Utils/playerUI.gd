extends Node2D

@onready var player: CharacterBody2D = get_parent()

@onready var movement_component: Node = $"../Components/MovementComponent"
@onready var health_component: Node = $"../Components/HealthComponent"
@onready var leveling_component: Node = $"../Components/LevelingComponent"
@onready var promotion_component: Node = $"../Components/PromotionComponent"
@onready var sprite_component: Sprite2D = $"../PlayerSprite"

@onready var melee_info_label: Label = $"../HUD/PromotionInfoLabel/MeleeWeapon"
@onready var ranged_info_label: Label = $"../HUD/PromotionInfoLabel/RangedWeapon"
@onready var ability_info_label: Label = $"../HUD/PromotionInfoLabel/Ability"

var melee_w_component: Node
var ranged_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var shield_component: Node

var current_first_ability: String

@onready var name_label: Label = $"../Name"
@onready var stats_label_one: Label = $"../HUD/StatsLabel"
@onready var stats_label_two: Label = $"../HUD/StatsLabel2"
@onready var level_label: Label = $"../HUD/LevelBar/LevelLabel"

@onready var upgrade_UI: HBoxContainer = $"../HUD/UpgradeUI"
@onready var promotion_UI: HBoxContainer = $"../HUD/PromotionUI"

@onready var leaderboard_label: Label = $"../HUD/LeaderboardLabel"

func _ready() -> void:
	name_label.text = "Player " + player.name.substr(0, 4)
	if player.name == str(multiplayer.get_unique_id()):
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		promotion_component.show_promotion_menu.connect(_show_promotion_menu)
		if not health_component:
			printerr("No health component")

# Populates the upgrade UI with valid random stat choices based on equipped capabilities.
func _show_upgrade_menu() -> void:
	var valid_stats: Array[String] = ["max_health", "regen_amount", "regen_speed", "body_damage", "player_speed"]
	
	if ranged_w_component:
		valid_stats.append_array(["projectile_damage", "projectile_speed", "reload_speed", "accuracy"])
	if melee_w_component:
		valid_stats.append_array(["melee_damage", "melee_knockback", "melee_cooldown"])
	
	if first_ability_component:
		match current_first_ability:
			"Magic":
				valid_stats.append_array(["area_damage", "area_knockback", "area_radius", "area_cooldown"])
			"Teleport":
				valid_stats.append_array(["teleport_cooldown", "teleport_range"])
			"Illusion":
				valid_stats.append_array(["illusion_cooldown", "illusion_duration"])
			"Stealth":
				valid_stats.append_array(["stealth_cooldown", "stealth_duration"])
			"Spawner":
				valid_stats.append_array(["spawner_cooldown", "max_spawns"])
			"Teleport_Crush":
				valid_stats.append_array(["teleport_cooldown", "teleport_range", "area_damage", "area_knockback", "area_radius"])
		
	for button: Node in upgrade_UI.get_children():
		var stat: String = valid_stats.pick_random()
		button.stat_id = stat
		button.refresh_text()
		
	upgrade_UI.show()

# Populates the promotion UI with the available class types
func _show_promotion_menu(available_classes: Array[String]) -> void:
	var buttons: Array[Node] = promotion_UI.get_children()
	for i: int in buttons.size():
		var button: Node = buttons[i]
		
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
		

# Updates the debug info display.
func _process(_delta: float) -> void:
	if player.name == str(multiplayer.get_unique_id()): 
		show_debug_info()

# Compiles and displays internal entity variables to the local HUD.
func show_debug_info() -> void:
	
	#POSITION AND SPEED
	var pos_text: String = "Position: " + str(Vector2(int(player.position.x), int(player.position.y))) + "\n"
	var speed_text: String = "Speed: " + str(movement_component.player_speed) + "\n\n"

	#HEALTH
	var max_health_text: String = "Max Health: " + str(health_component.max_health) + "\n"
	var health_text: String = "Health: " + str(health_component.health) + "\n"
	var regen_amount_text: String = "Regen Amount: " + str(health_component.regen_amount) + "\n"
	var regen_speed_text: String = "Regen Speed: " + str(health_component.regen_speed) + "\n"
	var regen_cooldown_text: String = "Regen Cooldown: " + str(snapped(health_component.regen_cooldown, 0.1)) + "\n\n"
	
	#KNOCKBACK AND BODY DAMAGE
	var kb_text: String = "Knockback: " + str(Vector2(int(player.knockback.x), int(player.knockback.y))) + "\n"
	var body_dmg_text: String = "Body Damage: " + str(player.body_damage) + "\n\n"
	
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
				stats_label_one.text += area_damage_text + area_kb_text + area_radius_text + area_cooldown_text + area_duration_text
			"Teleport":
				var tele_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tele_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tele_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_one.text += tele_cooldown_text + tele_duration_text + tele_range_text
			"Illusion":
				var illu_cooldown_text: String = "Illusion Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var illu_duration_text: String = "Illusion Duration: " + str(first_ability_component.illusion_duration) + "\n"
				var illu_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var illu_amount_text: String = "Illusion Amount: " + str(first_ability_component.illusions_count) + "\n\n"
				stats_label_one.text += illu_cooldown_text + illu_time_text + illu_duration_text + illu_amount_text
			"Stealth":
				var stealth_cd_text: String = "Stealth Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var stealth_dur_text: String = "Stealth Duration: " + str(first_ability_component.stealth_duration) + "\n"
				var stealth_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n\n"
				stats_label_one.text += stealth_cd_text + stealth_dur_text + stealth_time_text
			"Spawner":
				var spawner_cd_text: String = "Spawner Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var spawner_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var spawner_spawns_text: String = "Current spawns: " + str(first_ability_component.current_spawns) + "\n"
				var spawner_max_spawns_text: String = "Max spawns: " + str(first_ability_component.max_spawns) + "\n\n"
				stats_label_one.text += spawner_cd_text + spawner_time_text + spawner_spawns_text + spawner_max_spawns_text
			"Teleport_Crush":
				var tpc_damage_text: String = "Teleport Damage: " + str(first_ability_component.area_damage) + "\n"
				var tpc_kb_text: String = "Teleport Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var tpc_radius_text: String = "Teleport AoE Radius: " + str(first_ability_component.max_radius) + "\n"
				var tpc_area_duration_text: String = "Area Attack Duration: " + str(first_ability_component.attack_duration) + "\n\n"
				var tpc_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tpc_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tpc_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				stats_label_one.text += tpc_damage_text + tpc_kb_text + tpc_radius_text + tpc_area_duration_text + tpc_cooldown_text + tpc_duration_text + tpc_range_text
	else:
		var no_ability_text: String = "No First Ability" + "\n" + "\n"
		stats_label_one.text += no_ability_text
		
	# SHIELD
	if shield_component:
		var max_shield_health_text = "Max Shield Health: " + str(shield_component.max_shield_health) + "\n"
		var shield_health_text = "Shield Health: " + str(shield_component.shield_health) + "\n"
		var duration_text = "Total Shield Duration: " + str(shield_component.active_duration) + "\n\n"
		stats_label_two.text = max_shield_health_text + shield_health_text + duration_text
	else:
		var no_shield_text: String = "No Shield" + "\n" + "\n"
		stats_label_two.text = no_shield_text
	
	#PROMOTIONS AND UPGRADES
	var pending_upgrades_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	var pending_promotions_text: String = "Pending Promotions: " + str(promotion_component.pending_promotions) + "\n"
	# Down the right side
	stats_label_two.text += pending_upgrades_text + pending_promotions_text

	#POINTS AND LEVELLING
	var player_level_text: String = "Level: " + str(leveling_component.player_level)
	var next_level_points_text: String = "    Points for next: " + str(leveling_component.next_level_points)
	var points_text: String = "    Points: " + str(leveling_component.points) 
	var score_text: String = "    Score: " + str(leveling_component.total_score)

	# Below the level bar
	level_label.text = player_level_text + next_level_points_text + points_text + score_text
