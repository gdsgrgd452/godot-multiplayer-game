extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var sprite_component: Sprite2D = $PlayerSprite
var ranged_w_component: Node
var melee_w_component: Node

@export var current_class: String = "Pawn":
	set(value):
		current_class = value
		if is_node_ready():
			sprite_component._on_promotion_applied(value)

@export var current_melee_weapon: String = "Sword":
	set(value):
		current_melee_weapon = value
		if is_node_ready():
			_change_m_weapon(value)

@export var current_ranged_weapon: String = "None":
	set(value):
		current_ranged_weapon = value
		if is_node_ready():
			_change_r_weapon(value)

var knockback: Vector2 = Vector2.ZERO
var body_damage: int = 5
var ranks: Array[String] = ["Knight", "Rook", "Bishop"]

# Initializes UI, colors, and connects component signals.
func _ready() -> void:
	_change_m_weapon(current_melee_weapon)
	_change_r_weapon(current_ranged_weapon)
	if name == str(multiplayer.get_unique_id()):
		$PlayerSprite.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
		
		$HUD/UpgradeUI.hide()
		for button: Node in $HUD/UpgradeUI.get_children():
			button.stat_chosen.connect(_on_stat_chosen)
			
		$HUD/PromotionUI.hide()
		for button: Node in $HUD/PromotionUI.get_children():
			button.type_chosen.connect(_on_type_chosen)
		
		leveling_component.update_ui_points.connect(_update_ui_points)
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		leveling_component.show_promotion_menu.connect(_show_promotion_menu)
		leveling_component.change_m_weapon.connect(_change_m_weapon)
		leveling_component.change_r_weapon.connect(_change_r_weapon)
	else:
		$PlayerSprite.modulate = Color(1, 0, 0)
		$HUD.hide()
	if ranged_w_component:
		ranged_w_component.apply_recoil.connect(_on_apply_recoil)

# Updates the debug info display.
func _process(_delta: float) -> void:
	if name == str(multiplayer.get_unique_id()): 
		show_debug_info()

# Processes server-side physics and calls local client input gathering.
func _physics_process(delta: float) -> void:
	if name == str(multiplayer.get_unique_id()):
		hold_to_shoot()
		check_melee_input()

	if multiplayer.is_server():
		decrease_knockback(delta)
		velocity = movement_component.get_movement_velocity() + knockback
		move_and_slide()
		handle_collisions()

# Evaluates and triggers continuous shooting input.
func hold_to_shoot() -> void:
	if ranged_w_component and Input.is_action_pressed("shoot"):
		ranged_w_component.shoot(get_global_mouse_position())

# Evaluates discrete input to request a localized melee strike from the server.
func check_melee_input() -> void:
	if melee_w_component and Input.is_action_pressed("meele"): # Map "melee" to Spacebar or Right Click in Project Settings
		var target_pos: Vector2 = get_global_mouse_position()
		melee_w_component.request_melee_attack.rpc_id(1, target_pos)

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
		
		if collider and collider.has_method("apply_bounce"):
			collider.apply_bounce(-normal * 500)
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

# Awards points to the attacker and removes the player entity.
func _on_player_died(attacker_id: String) -> void:
	give_points_on_death(attacker_id)
	queue_free()

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
	#print("Queueing points: " + str(new_points))
	$HUD/LevelBar.queue_points(new_points)

# Populates the upgrade UI with random stat choices.
func _show_upgrade_menu() -> void:
	#print("Trying to show upgrade menu " + str(leveling_component.pending_upgrades))
	for button: Node in $HUD/UpgradeUI.get_children():
		var stat: String = leveling_component.upgradeable_stats.keys().pick_random()
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

# Populates the promotion UI with the available class types.
func _show_promotion_menu() -> void:
	#print("Trying to show promotion menu")
	var buttons: Array[Node] = $HUD/PromotionUI.get_children()
	for i: int in buttons.size():
		var type: String = ranks[i]
		var button: Node = buttons[i]
		
		button.type_id = type
		button.refresh_text()
		
	$HUD/PromotionUI.show()

# Transmits the selected class promotion to the server via the leveling component.
func _on_type_chosen(chosen_type: String) -> void:
	$HUD/PromotionUI.hide()
	leveling_component.request_promotion.rpc_id(1, chosen_type)

# Defines an RPC for the server to command the local client to update its sprite.
@rpc("any_peer", "call_local", "reliable")
func update_sprite_rpc(choice: String) -> void:
	sprite_component._on_promotion_applied(choice)

# Updates the active melee weapon references, hides visuals, and disables processing for unused components.
func _change_m_weapon(weapon_type: String) -> void:
	print("Trying to change melee weapon: " + weapon_type)
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
		"None":
			if melee_w_component:
				print("Hiding melee")
				melee_w_component.hide()
				melee_w_component.process_mode = Node.PROCESS_MODE_DISABLED
				melee_w_component = null

# Updates the active ranged weapon references, hides visuals, and disables processing for unused components.
func _change_r_weapon(weapon_type: String) -> void:
	match weapon_type:
		"Ranged_Spell":
			var ranged_spell: Node = $Components/RangedWeaponComponent
			# Remove hide() and show() here if your ranged weapon does not inherit from Node2D/CanvasItem
			ranged_spell.hide() 
			ranged_spell.process_mode = Node.PROCESS_MODE_DISABLED
			
			match weapon_type:
				"Ranged_Spell":
					ranged_w_component = ranged_spell
					
			ranged_w_component.show()
			ranged_w_component.process_mode = Node.PROCESS_MODE_INHERIT
		"None":
			if ranged_w_component:
				ranged_w_component.hide()
				ranged_w_component.process_mode = Node.PROCESS_MODE_DISABLED
				ranged_w_component = null

# Compiles and displays internal entity variables to the local HUD.
func show_debug_info() -> void:
	
	#POSITION
	var pos_text: String = "Position: " + str(Vector2(int(position.x), int(position.y))) + "\n\n"
	
	#HEALTH
	var max_health_text: String = "Max Health: " + str(health_component.max_health) + "\n"
	var health_text: String = "Health: " + str(health_component.health) + "\n\n"
	
	#KNOCKBACK AND BODY DAMAGE
	var kb_text: String = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y))) + "\n"
	var body_dmg_text: String = "Body Damage: " + str(body_damage) + "\n\n"
	
	$HUD/StatsLabel.text = max_health_text + health_text + pos_text + kb_text + body_dmg_text

	if ranged_w_component:
		#RANGED COMBAT
		var bullet_dmg_text: String = "Bullet Damage: " + str(ranged_w_component.bullet_damage) + "\n"
		var bullet_speed_text: String = "Bullet Speed: " + str(ranged_w_component.bullet_speed) + "\n\n"
		var shoot_text: String = "Shooting: " + str(ranged_w_component.shooting) + "\n"
		var reload_time_text: String = "Reload Time: " + str(ranged_w_component.reload_speed)+ "\n"
		var cooldown_text: String = "Cooldown: " + str(snapped(ranged_w_component.shot_cooldown, 0.01)) + "\n\n"
		$HUD/StatsLabel.text += bullet_dmg_text + bullet_speed_text + shoot_text + reload_time_text + cooldown_text
	else:
		var no_ranged_text: String = "No Ranged Weapon"  + "\n" + "\n"
		$HUD/StatsLabel.text += no_ranged_text
	
	if melee_w_component:
		#MELEE COMBAT
		var melee_dmg_text: String = "Melee Damage: " + str(melee_w_component.melee_damage) + "\n"
		var melee_kb_text: String = "Melee Knockback: " + str(melee_w_component.knockback_force) + "\n"
		var melee_cooldown_text: String = "Melee Cooldown: " + str(melee_w_component.attack_cooldown) + "\n"
		var melee_duration_text: String = "Melee Duration: " + str(melee_w_component.attack_duration) + "\n"
		var melee_has_hit_text: String = "Melee Has Hit: " + str(melee_w_component.has_hit) + "\n\n"
		$HUD/StatsLabel.text += melee_dmg_text + melee_kb_text + melee_cooldown_text + melee_duration_text + melee_has_hit_text
	else:
		var no_melee_text: String = "No Melee Weapon"  + "\n" + "\n"
		$HUD/StatsLabel.text += no_melee_text

	#PROMOTIONS AND UPGRADES
	var pending_upgrades_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	var pending_promotions_text: String = "Pending Promotions: " + str(leveling_component.pending_promotions) + "\n"
	# Down the right side
	$HUD/StatsLabel.text += pending_upgrades_text + pending_promotions_text

	#POINTS AND LEVELLING
	var player_level_text: String = "Level: " + str(leveling_component.player_level)
	var next_level_points_text: String = "    Points for next: " + str(leveling_component.next_level_points)
	var points_text: String = "    Points: " + str(leveling_component.points) 
	var score_text: String = "    Score: " + str(leveling_component.total_score)



	# Below the level bar
	$HUD/LevelLabel.text = player_level_text + next_level_points_text + points_text + score_text
