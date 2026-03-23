extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var promotion_component: Node = $Components/PromotionComponent
@onready var sprite_component: Sprite2D = $PlayerSprite
var ranged_w_component: Node
var melee_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var shield_component: Node

@export var team_id: int = 0

var shielding: bool = false

@export var current_class: String = "Ottoman_Knight":
	set(value):
		current_class = value
		if is_node_ready():
			print(current_class)
			sprite_component._on_promotion_applied(value)

@export var current_melee_weapon: String = "Sword":
	set(value):
		current_melee_weapon = value
		if is_node_ready():
			_change_m_weapon(value)

@export var current_ranged_weapon: String = "Fireball_Shooter":
	set(value):
		current_ranged_weapon = value
		if is_node_ready():
			_change_r_weapon(value)
			
@export var current_first_ability: String = "Magic":
	set(value):
		current_first_ability = value
		if is_node_ready():
			print(value)
			_change_first_ability(value)

@export var current_shield: String = "Wooden":
	set(value):
		current_shield = value
		if is_node_ready():
			_change_shield(value)

var knockback: Vector2 = Vector2.ZERO
var knockback_force: int = 200
var body_damage: int

# Initializes UI, colors, and connects component signals.
func _ready() -> void:
	#Initialises the class on spawn
	if is_node_ready():
		sprite_component._on_promotion_applied(current_class)
	
	promotion_component.change_weapon(current_class)
	promotion_component.apply_promotion_stats(current_class)
	
	health_component.died.connect(_on_player_died)

	if ranged_w_component:
		ranged_w_component.apply_recoil.connect(_on_apply_recoil)

	if name == str(multiplayer.get_unique_id()):
		$PlayerSprite.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
		$AbilityBar.show()
		$HUD/UpgradeUI.hide()
		for button: Node in $HUD/UpgradeUI.get_children():
			button.stat_chosen.connect(_on_stat_chosen)
			
		$HUD/PromotionUI.hide()
		for button: Node in $HUD/PromotionUI.get_children():
			button.type_chosen.connect(_on_type_chosen)
		
		leveling_component.update_ui_points.connect(_update_ui_points)
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		promotion_component.show_promotion_menu.connect(_show_promotion_menu)
	else:
		$PlayerSprite.modulate = Color(1, 0, 0)
		$HUD.hide()
		$AbilityBar.hide()
	print(team_id)

func apply_team_color() -> void:
	var sprite: Sprite2D = get_node_or_null("PlayerSprite") as Sprite2D
	if not sprite:
		return
		
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node2D = get_tree().current_scene.find_child(local_id, true, false) as Node2D
	
	if local_player and "team_id" in local_player:
		if self.team_id == local_player.get("team_id"):
			sprite.modulate = Color(0.0, 1.0, 0.0)
		else:
			sprite.modulate = Color(1.0, 0.0, 0.0)

# Updates the debug info display.
func _process(_delta: float) -> void:
	if name == str(multiplayer.get_unique_id()): 
		show_debug_info()

# Processes server-side physics and calls local client input gathering.
func _physics_process(delta: float) -> void:
	if name == str(multiplayer.get_unique_id()):
		#if not shielding: # TODO Add this back in
		check_ranged_input()
		check_melee_input()
		check_first_ability_input()
		check_shield_input()

	if multiplayer.is_server():
		decrease_knockback(delta)
		velocity = movement_component.get_movement_velocity() + knockback
		move_and_slide()
		handle_collisions()

# Evaluates and triggers continuous shooting input.
func check_ranged_input() -> void:
	if ranged_w_component and Input.is_action_pressed("shoot"):
		ranged_w_component.shoot(get_global_mouse_position())

# Evaluates discrete input to request a localized melee strike from the server.
func check_melee_input() -> void:
	if melee_w_component and Input.is_action_pressed("meele"): # Map "melee" to Spacebar or Right Click in Project Settings
		var target_pos: Vector2 = get_global_mouse_position()
		melee_w_component.request_melee_attack.rpc_id(1, target_pos)

# Evaluates input and triggers the appropriate logic based on the current ability type.
func check_first_ability_input() -> void:
	if first_ability_component and Input.is_action_just_pressed("first_ability"):
		match current_first_ability:
			"Magic":
				first_ability_component.request_area_attack.rpc_id(1)
			"Teleport":
				first_ability_component.request_teleport.rpc_id(1, get_global_mouse_position())
			"Illusion":
				first_ability_component.request_scattered_illusions.rpc_id(1)
			"Stealth":
				first_ability_component.request_stealth.rpc_id(1)
			"Spawner":
				first_ability_component.request_spawn.rpc_id(1, position)
			"Teleport_Crush":
				first_ability_component.request_teleport_crush.rpc_id(1, get_global_mouse_position())

# Evaluates continuous input to request shield activation and deactivation from the server.
func check_shield_input() -> void:
	if shield_component:
		var shield_testing = true
		if not shield_testing:
			if Input.is_action_just_pressed("shield"):
				print("Trying to activate shield")
				shield_component.request_shield_activation.rpc_id(1)
			elif Input.is_action_just_released("shield"):
				shield_component.request_shield_deactivation.rpc_id(1)
		else:
			if Input.is_action_just_pressed("shield"):
				print("Trying to activate shield")
				shield_component.request_shield_activation.rpc_id(1)

# Smoothly decays physical knockback momentum over time.
func decrease_knockback(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)

# Evaluates kinematic collisions for bouncing and contact damage.
func handle_collisions() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		var normal: Vector2 = collision.get_normal()
		
		velocity = Vector2.ZERO
		knockback = normal * 500
		
		if collider: 
			if collider.has_method("apply_bounce"):
				collider.apply_bounce(-normal * knockback_force)
				if collider.is_in_group("food"):
					do_contact_damage(collider)

# Triggers contact damage against target and self.
func do_contact_damage(collider: Node) -> void:
	collider.take_damage(body_damage, name)
	health_component.take_damage(2)

# Applies an external physics impulse force to the player.
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force
		
# Adds recoil momentum from weapon firing.
func _on_apply_recoil(force: Vector2) -> void:
	knockback += force

# Routes incoming damage to the health component.
func take_damage(amount: int, attacker_id: String = "") -> void:
	health_component.take_damage(amount, attacker_id)

# Awards points to the attacker, disables the player, and triggers the death UI.
func _on_player_died(attacker_id: String) -> void:
	give_points_on_death(attacker_id)
	print("Called")
	# Disable collisions and processing so the dead body doesn't interact with the world
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	
	# Tell the specific client who owns this player that they died, and pass the killer's ID
	trigger_death_screen.rpc_id(name.to_int(), attacker_id)

# Tells the local client to initiate the spectate sequence on the main scene.
@rpc("authority", "call_local", "reliable")
func trigger_death_screen(attacker_id: String) -> void:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("start_spectating"):
		main_scene.start_spectating(attacker_id)

# Locates the attacking entity and transfers the accumulated score.
func give_points_on_death(attacker_id: String) -> void:
	if attacker_id != "":
		var attacker: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + attacker_id)
		if attacker and attacker.has_method("get_points_from_kill"):
			attacker.get_points_from_kill(leveling_component.total_score)

# Routes incoming kill points to the leveling component.
func get_points_from_kill(kill_value: int) -> void:
	leveling_component.get_points_from_kill(kill_value)

func _update_ui_points(new_points: int):
	$HUD/LevelBar.queue_points(new_points)

# Updates the local leaderboard UI with data broadcasted from the server.
func update_leaderboard_ui(board_text: String) -> void:
	if has_node("HUD/LeaderboardLabel"):
		$HUD/LeaderboardLabel.text = board_text

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
				valid_stats.append_array(["spawner_cooldown", "spawner_limit"])
			"Teleport_Crush":
				valid_stats.append_array(["teleport_cooldown", "teleport_range", "area_damage", "area_knockback", "area_radius"])
		
	for button: Node in $HUD/UpgradeUI.get_children():
		var stat: String = valid_stats.pick_random()
		button.stat_id = stat
		button.refresh_text()
		
	$HUD/UpgradeUI.show()

# Transmits the selected stat upgrade to the server.
func _on_stat_chosen(chosen_stat: String) -> void:
	$HUD/UpgradeUI.hide() 
	if multiplayer.is_server():
		leveling_component.apply_upgrade(chosen_stat)
	else:
		leveling_component.rpc_id(1, "request_upgrade", chosen_stat)

# Populates the promotion UI with the available class types
func _show_promotion_menu(available_classes: Array[String]) -> void:
	var buttons: Array[Node] = $HUD/PromotionUI.get_children()
	for i: int in buttons.size():
		var button: Node = buttons[i]
		
		if i < available_classes.size():
			var type: String = available_classes[i]
			button.type_id = type
			button.show()
		else:
			button.hide()
			
	$HUD/PromotionUI.show()

# Transmits the selected class promotion to the server via the promotion component.
func _on_type_chosen(chosen_type: String) -> void:
	$HUD/PromotionUI.hide()
	promotion_component.request_promotion.rpc_id(1, chosen_type)

# Defines an RPC for the server to command the local client to update its sprite.
@rpc("any_peer", "call_local", "reliable")
func update_sprite_rpc(choice: String) -> void:
	sprite_component._on_promotion_applied(choice)

# Updates the active melee weapon references, hides visuals, and disables processing for unused components.
func _change_m_weapon(weapon_type: String) -> void:
	#print("Trying to change melee weapon: " + weapon_type)
	match weapon_type:
		"Spear", "Sword":
			var spear: Node2D = $Components/SpearComponent
			spear.hide()
			spear.process_mode = Node.PROCESS_MODE_DISABLED
			
			var sword: Node2D = $Components/SwordComponent
			sword.hide()
			sword.process_mode = Node.PROCESS_MODE_DISABLED
			
			match weapon_type:
				"Spear":
					melee_w_component = spear
				"Sword":
					melee_w_component = sword
					
			melee_w_component.show()
			melee_w_component.process_mode = Node.PROCESS_MODE_INHERIT
			#print("Set melee weapon: " + weapon_type)
		"None":
			if melee_w_component:
				melee_w_component.hide()
				melee_w_component.process_mode = Node.PROCESS_MODE_DISABLED
				melee_w_component = null

# Updates the active ranged weapon references, hides visuals, and disables processing for unused components.
func _change_r_weapon(weapon_type: String) -> void:
	match weapon_type:
		"Fireball_Shooter", "Bow", "Pin_Shooter":
			var fireball_shooter: Node = $Components/FireballShooterComponent
			fireball_shooter.hide() 
			fireball_shooter.process_mode = Node.PROCESS_MODE_DISABLED
			
			var bow: Node = $Components/BowComponent
			bow.hide() 
			bow.process_mode = Node.PROCESS_MODE_DISABLED
			
			var pin_shooter: Node = $Components/PinShooterComponent
			pin_shooter.hide() 
			pin_shooter.process_mode = Node.PROCESS_MODE_DISABLED
			
			match weapon_type:
				"Fireball_Shooter":
					ranged_w_component = fireball_shooter
				"Bow":
					ranged_w_component = bow
				"Pin_Shooter":
					ranged_w_component = pin_shooter
			ranged_w_component.show()
			ranged_w_component.process_mode = Node.PROCESS_MODE_INHERIT
		"None":
			if ranged_w_component:
				ranged_w_component.hide()
				ranged_w_component.process_mode = Node.PROCESS_MODE_DISABLED
				ranged_w_component = null

# Updates the active first ability references, hides visuals, and disables processing for unused components.
func _change_first_ability(ability_type: String) -> void:
	match ability_type:
		"Magic", "Teleport", "Illusion", "Stealth", "Spawner", "Teleport_Crush":
			var magic: Node = get_node_or_null("Components/MagicAreaWeaponComponent")
			if magic:
				magic.hide() 
				magic.process_mode = Node.PROCESS_MODE_DISABLED
			
			var teleport: Node = get_node_or_null("Components/TeleportComponent")
			if teleport:
				teleport.hide() 
				teleport.process_mode = Node.PROCESS_MODE_DISABLED
				
			var illusion: Node = get_node_or_null("Components/IllusionComponent")
			if illusion:
				illusion.hide()
				illusion.process_mode = Node.PROCESS_MODE_DISABLED
				
			var stealth: Node = get_node_or_null("Components/StealthComponent")
			if stealth:
				stealth.hide()
				stealth.process_mode = Node.PROCESS_MODE_DISABLED
				
			var spawner: Node = get_node_or_null("Components/SpawnerComponent")
			if spawner:
				spawner.hide()
				spawner.process_mode = Node.PROCESS_MODE_DISABLED
				
			var teleport_crush: Node = get_node_or_null("Components/TeleportCrushComponent")
			if teleport_crush:
				teleport_crush.hide()
				teleport_crush.process_mode = Node.PROCESS_MODE_DISABLED
				
			match ability_type:
				"Magic":
					first_ability_component = magic
				"Teleport":
					first_ability_component = teleport
				"Illusion":
					first_ability_component = illusion
				"Stealth":
					first_ability_component = stealth
				"Spawner":
					first_ability_component = spawner
				"Teleport_Crush":
					first_ability_component = teleport_crush
			print(str(first_ability_component.name))
			if first_ability_component:
				first_ability_component.show()
				first_ability_component.process_mode = Node.PROCESS_MODE_INHERIT
		"None":
			if first_ability_component:
				first_ability_component.hide()
				first_ability_component.process_mode = Node.PROCESS_MODE_DISABLED
				first_ability_component = null

# Updates the active shield references, hides visuals, and disables processing for unused components.
func _change_shield(shield_type: String) -> void:
	match shield_type:
		"Wooden", "Magic":
			var wooden_shield: Node = $Components/WoodenShieldComponent
			wooden_shield.process_mode = Node.PROCESS_MODE_DISABLED
			wooden_shield.hide()
			
			var magic_shield: Node = $Components/MagicShieldComponent
			magic_shield.process_mode = Node.PROCESS_MODE_DISABLED
			magic_shield.hide()
			
			match shield_type:
				"Wooden":
					shield_component = wooden_shield
				"Magic":
					shield_component = magic_shield
					
			shield_component.process_mode = Node.PROCESS_MODE_INHERIT
		"None":
			if shield_component:
				shield_component.hide()
				shield_component.process_mode = Node.PROCESS_MODE_DISABLED
				shield_component = null
			
# Compiles and displays internal entity variables to the local HUD.
func show_debug_info() -> void:
	
	#POSITION AND SPEED
	var pos_text: String = "Position: " + str(Vector2(int(position.x), int(position.y))) + "\n"
	var speed_text: String = "Speed: " + str(movement_component.player_speed) + "\n\n"

	#HEALTH
	var max_health_text: String = "Max Health: " + str(health_component.max_health) + "\n"
	var health_text: String = "Health: " + str(health_component.health) + "\n"
	var regen_amount_text: String = "Regen Amount: " + str(health_component.regen_amount) + "\n"
	var regen_speed_text: String = "Regen Speed: " + str(health_component.regen_speed) + "\n"
	var regen_cooldown_text: String = "Regen Cooldown: " + str(snapped(health_component.regen_cooldown, 0.1)) + "\n\n"
	
	#KNOCKBACK AND BODY DAMAGE
	var kb_text: String = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y))) + "\n"
	var body_dmg_text: String = "Body Damage: " + str(body_damage) + "\n\n"
	
	$HUD/StatsLabel.text = max_health_text + health_text + regen_amount_text + regen_speed_text + regen_cooldown_text + pos_text + speed_text + kb_text + body_dmg_text

	#RANGED COMBAT
	if ranged_w_component:
		var projectile_dmg_text: String = "Projectile Damage: " + str(ranged_w_component.projectile_damage) + "\n"
		var projectile_speed_text: String = "Projectile Speed: " + str(ranged_w_component.projectile_speed) + "\n\n"
		var shoot_text: String = "Shooting: " + str(ranged_w_component.shooting) + "\n"
		var reload_time_text: String = "Reload Time: " + str(ranged_w_component.reload_speed)+ "\n"
		var cooldown_text: String = "Cooldown: " + str(snapped(ranged_w_component.shot_cooldown, 0.01)) + "\n"
		var accuracy_text: String = "Accuracy: " + str(snapped(ranged_w_component.accuracy, 0.01)) + "\n\n"
		$HUD/StatsLabel.text += projectile_dmg_text + projectile_speed_text + shoot_text + reload_time_text + cooldown_text + accuracy_text
	else:
		var no_ranged_text: String = "No Ranged Weapon" + "\n" + "\n"
		$HUD/StatsLabel.text += no_ranged_text
	
	#MELEE COMBAT
	if melee_w_component:
		var melee_dmg_text: String = "Melee Damage: " + str(melee_w_component.melee_damage) + "\n"
		var melee_kb_text: String = "Melee Knockback: " + str(melee_w_component.knockback_force) + "\n"
		var melee_cooldown_text: String = "Melee Cooldown: " + str(melee_w_component.attack_cooldown) + "\n"
		var melee_duration_text: String = "Melee Attack Duration: " + str(melee_w_component.attack_duration) + "\n"
		var melee_has_hit_text: String = "Melee Has Hit: " + str(melee_w_component.has_hit) + "\n\n"
		$HUD/StatsLabel.text += melee_dmg_text + melee_kb_text + melee_cooldown_text + melee_duration_text + melee_has_hit_text
	else:
		var no_melee_text: String = "No Melee Weapon"  + "\n" + "\n"
		$HUD/StatsLabel.text += no_melee_text

	# FIRST ABILITY
	if first_ability_component:
		match current_first_ability:
			"Magic":
				var area_damage_text: String = "Area Damage: " + str(first_ability_component.area_damage) + "\n"
				var area_kb_text: String = "Area Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var area_radius_text: String = "Area Radius: " + str(first_ability_component.max_radius) + "\n"
				var area_cooldown_text: String = "Area Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var area_duration_text: String = "Area Attack Duration: " + str(first_ability_component.attack_duration) + "\n\n"
				$HUD/StatsLabel.text += area_damage_text + area_kb_text + area_radius_text + area_cooldown_text + area_duration_text
			"Teleport":
				var tele_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tele_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tele_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				$HUD/StatsLabel.text += tele_cooldown_text + tele_duration_text + tele_range_text
			"Illusion":
				var illu_cooldown_text: String = "Illusion Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var illu_duration_text: String = "Illusion Duration: " + str(first_ability_component.illusion_duration) + "\n"
				var illu_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var illu_amount_text: String = "Illusion Amount: " + str(first_ability_component.illusions_count) + "\n\n"
				$HUD/StatsLabel.text += illu_cooldown_text + illu_time_text + illu_duration_text + illu_amount_text
			"Stealth":
				var stealth_cd_text: String = "Stealth Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var stealth_dur_text: String = "Stealth Duration: " + str(first_ability_component.stealth_duration) + "\n"
				var stealth_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n\n"
				$HUD/StatsLabel.text += stealth_cd_text + stealth_dur_text + stealth_time_text
			"Spawner":
				var spawner_cd_text: String = "Spawner Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var stealth_time_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var stealth_dur_text: String = "Max spawns: " + str(first_ability_component.max_spawns) + "\n\n"
				$HUD/StatsLabel.text += spawner_cd_text + stealth_time_text + stealth_dur_text
			"Teleport_Crush":
				var tpc_damage_text: String = "Teleport Damage: " + str(first_ability_component.area_damage) + "\n"
				var tpc_kb_text: String = "Teleport Knockback: " + str(first_ability_component.knockback_force) + "\n"
				var tpc_radius_text: String = "Teleport AoE Radius: " + str(first_ability_component.max_radius) + "\n"
				var tpc_area_duration_text: String = "Area Attack Duration: " + str(first_ability_component.attack_duration) + "\n\n"
				var tpc_cooldown_text: String = "Teleport Cooldown: " + str(first_ability_component.max_cooldown) + "\n"
				var tpc_duration_text: String = "Til next: " + str(snapped(first_ability_component.current_cooldown, 0.1)) + "\n"
				var tpc_range_text: String = "Teleport Range: " + str(first_ability_component.max_range) + "\n\n"
				$HUD/StatsLabel.text += tpc_damage_text + tpc_kb_text + tpc_radius_text + tpc_area_duration_text + tpc_cooldown_text + tpc_duration_text + tpc_range_text
	else:
		var no_ability_text: String = "No First Ability" + "\n" + "\n"
		$HUD/StatsLabel.text += no_ability_text
	
	# SHIELD
	if shield_component:
		var max_shield_health_text = "Max Shield Health: " + str(shield_component.max_shield_health) + "\n"
		var shield_health_text = "Shield Health: " + str(shield_component.shield_health) + "\n"
		var duration_text = "Total Shield Duration: " + str(shield_component.active_duration) + "\n\n"
		$HUD/StatsLabel2.text = max_shield_health_text + shield_health_text + duration_text
	else:
		var no_shield_text: String = "No Shield" + "\n" + "\n"
		$HUD/StatsLabel2.text = no_shield_text
	
	#PROMOTIONS AND UPGRADES
	var pending_upgrades_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	var pending_promotions_text: String = "Pending Promotions: " + str(promotion_component.pending_promotions) + "\n"
	# Down the right side
	$HUD/StatsLabel2.text += pending_upgrades_text + pending_promotions_text

	#POINTS AND LEVELLING
	var player_level_text: String = "Level: " + str(leveling_component.player_level)
	var next_level_points_text: String = "    Points for next: " + str(leveling_component.next_level_points)
	var points_text: String = "    Points: " + str(leveling_component.points) 
	var score_text: String = "    Score: " + str(leveling_component.total_score)

	# Below the level bar
	$HUD/LevelLabel.text = player_level_text + next_level_points_text + points_text + score_text
