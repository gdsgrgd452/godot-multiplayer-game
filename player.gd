extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var ranged_w_component: Node = $Components/RangedWeaponComponent
@onready var sprite_component: Sprite2D = $PlayerSprite

var knockback: Vector2 = Vector2.ZERO
var body_damage: int = 5
var ranks = ["Knight", "Rook", "Bishop"]

# Initializes UI, colors, and connects component signals
func _ready() -> void:
	if name == str(multiplayer.get_unique_id()):
		$PlayerSprite.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
		
		$HUD/UpgradeUI.hide()
		for button in $HUD/UpgradeUI.get_children():
			button.stat_chosen.connect(_on_stat_chosen)
			
		$HUD/PromotionUI.hide()
		for button in $HUD/PromotionUI.get_children():
			button.type_chosen.connect(_on_type_chosen)
		
		leveling_component.update_ui_points.connect(func(val: int): $HUD/LevelBar.queue_points(val))
		leveling_component.show_upgrade_menu.connect(_show_upgrade_menu)
		leveling_component.show_promotion_menu.connect(_show_promotion_menu)
	else:
		$PlayerSprite.modulate = Color(1, 0, 0)
		$HUD.hide()
		
	ranged_w_component.apply_recoil.connect(_on_apply_recoil)

# Updates the debug info display
func _process(_delta: float) -> void:
	if name == str(multiplayer.get_unique_id()): 
		show_debug_info()

# Server-side physics calculation and client input gathering
func _physics_process(delta: float) -> void:
	if name == str(multiplayer.get_unique_id()):
		hold_to_shoot()

	if multiplayer.is_server():
		decrease_knockback(delta)
		velocity = movement_component.get_movement_velocity() + knockback
		move_and_slide()
		handle_collisions()

# Checks if the player is holding the shoot button
func hold_to_shoot() -> void:
	if Input.is_action_pressed("shoot"):
		ranged_w_component.shoot(get_global_mouse_position())

# Smoothly slows the player down from impacts
func decrease_knockback(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)

# Handles bouncing off objects and dealing ramming damage
func handle_collisions() -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		var normal: Vector2 = collision.get_normal()
		
		velocity = Vector2.ZERO
		knockback = normal * 500
		
		if collider and collider.has_method("apply_bounce"):
			collider.apply_bounce(-normal * 500)
			if collider.is_in_group("food"):
				do_contact_damage(collider)

# Triggers damage against food and causes recoil damage to self
func do_contact_damage(collider: Node) -> void:
	collider.take_damage(body_damage, name)
	health_component.take_damage(2)

# Used by external objects to shove the player
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force
		
# Applies recoil from the weapon
func _on_apply_recoil(force: Vector2) -> void:
	knockback += force

# Routes damage to the health component
func take_damage(amount: int, attacker_id: String = "") -> void:
	health_component.take_damage(amount, attacker_id)

# Drops points and destroys the player
func _on_player_died(attacker_id: String) -> void:
	give_points_on_death(attacker_id)
	queue_free()

# Gives the person who killed you your score
func give_points_on_death(attacker_id: String) -> void:
	if attacker_id != "":
		var attacker: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + attacker_id)
		if attacker and attacker.has_method("get_points_from_kill"):
			attacker.get_points_from_kill(leveling_component.total_score)

# Passes the kill value down to the component
func get_points_from_kill(kill_value: int) -> void:
	leveling_component.get_points_from_kill(kill_value)

# Used by the LevelBar UI
func level_up() -> void:
	if name == str(multiplayer.get_unique_id()):
		leveling_component.rpc_id(1, "request_level_up_math")

# Populates the upgrade UI with random stat choices
func _show_upgrade_menu() -> void:
	for button in $HUD/UpgradeUI.get_children():
		var stat: String = leveling_component.upgradeable_stats.keys().pick_random()
		button.stat_id = stat
		button.refresh_text()
	$HUD/UpgradeUI.show()

# Triggered when an upgrade is selected
func _on_stat_chosen(chosen_stat: String) -> void:
	$HUD/UpgradeUI.hide() 
	if multiplayer.is_server():
		leveling_component.apply_upgrade(chosen_stat)
	else:
		leveling_component.rpc_id(1, "request_upgrade", chosen_stat)

# Populates the promotion UI with set type choices
func _show_promotion_menu() -> void:
	var buttons: Array[Node] = $HUD/PromotionUI.get_children()
	for i in buttons.size():
		var type: String = ranks[i]
		var button: Node = buttons[i]
		
		button.type_id = type
		button.refresh_text()
		
	$HUD/PromotionUI.show()

#Triggered when a type is chosen
func _on_type_chosen(chosen_type: String) -> void:
	$HUD/PromotionUI.hide()
	if multiplayer.is_server():
		sprite_component.apply_promotion(chosen_type)
	else:
		sprite_component.rpc_id(1, "request_promotion", chosen_type)

func promotion_aquired(chosen_type: String) -> void:
	match chosen_type:
		"Knight":
			ranged_w_component.bullet_damage += 50
			movement_component.player_speed += 50
		"Rook":
			health_component.max_health += 50
			health_component.heal(50)

# Shows debug info on the player's screen
func show_debug_info() -> void:
	var max_health_text: String = "Max Health: " + str(health_component.max_health) + "\n"
	var health_text: String = "Health: " + str(health_component.health) + "\n\n"
	var pos_text: String = "Position: " + str(Vector2(int(position.x), int(position.y))) + "\n\n"
	var kb_text: String = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y))) + "\n"
	var body_dmg_text: String = "Body Damage: " + str(body_damage) + "\n\n"
	var bullet_dmg_text: String = "Bullet Damage: " + str(ranged_w_component.bullet_damage) + "\n"
	var bullet_speed_text: String = "Bullet Speed: " + str(ranged_w_component.bullet_speed) + "\n\n"
	var shoot_text: String = "Shooting: " + str(ranged_w_component.shooting) + "\n"
	var reload_time_text: String = "Reload Time: " + str(ranged_w_component.reload_speed)+ "\n"
	var cooldown_text: String = "Cooldown: " + str(snapped(ranged_w_component.shot_cooldown, 0.01)) + "\n\n"
	
	var player_level_text: String = "Level: " + str(leveling_component.player_level)
	var next_level_points_text: String = "    Points for next: " + str(leveling_component.next_level_points)
	var points_text: String = "    Points: " + str(leveling_component.points) 
	var score_text: String = "    Score: " + str(leveling_component.total_score)
	var pending_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	
	$HUD/StatsLabel.text = max_health_text + health_text + pos_text + kb_text + body_dmg_text + bullet_dmg_text
	$HUD/StatsLabel.text += bullet_speed_text + shoot_text + reload_time_text + cooldown_text + pending_text
	$HUD/LevelLabel.text = player_level_text + next_level_points_text + points_text + score_text
