extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var ranged_w_component: Node = $Components/RangedWeaponComponent
@onready var melee_w_component: Node2D = $Components/MeleeWeaponComponent
@onready var sprite_component: Sprite2D = $PlayerSprite

@export var current_class: String = "Pawn":
	set(value):
		current_class = value
		if is_node_ready():
			sprite_component._on_promotion_applied(value)

var knockback: Vector2 = Vector2.ZERO
var body_damage: int = 5
var ranks: Array[String] = ["Knight", "Rook", "Bishop"]

# Initializes UI, colors, and connects component signals.
func _ready() -> void:
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
	else:
		$PlayerSprite.modulate = Color(1, 0, 0)
		$HUD.hide()
		
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

# Captures discrete key presses.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			print("F")

# Evaluates and triggers continuous shooting input.
func hold_to_shoot() -> void:
	if Input.is_action_pressed("shoot"):
		ranged_w_component.shoot(get_global_mouse_position())

# Evaluates discrete input to request a localized melee strike from the server.
func check_melee_input() -> void:
	if Input.is_action_just_released("melee"): # Map "melee" to Spacebar or Right Click in Project Settings
		var target_pos: Vector2 = get_global_mouse_position()
		print("Meele input detected")
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
	print("Queueing points: " + str(new_points))
	$HUD/LevelBar.queue_points(new_points)

# Populates the upgrade UI with random stat choices.
func _show_upgrade_menu() -> void:
	print("Trying to show upgrade menu " + str(leveling_component.pending_upgrades))
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

# Compiles and displays internal entity variables to the local HUD.
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
	var pending_upgrades_text: String = "Pending upgrades: " + str(leveling_component.pending_upgrades) + "\n"
	var pending_promotions_text: String = "Pending Promotions: " + str(leveling_component.pending_promotions) + "\n"
	
	$HUD/StatsLabel.text = max_health_text + health_text + pos_text + kb_text + body_dmg_text + bullet_dmg_text
	$HUD/StatsLabel.text += bullet_speed_text + shoot_text + reload_time_text + cooldown_text + pending_upgrades_text
	$HUD/StatsLabel.text += pending_promotions_text

	$HUD/LevelLabel.text = player_level_text + next_level_points_text + points_text + score_text
