extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var promotion_component: Node = $Components/PromotionComponent
@onready var manager_component: ComponentManager = $Components/ComponentManager
@onready var sprite_component: Sprite2D = $SpriteComponent
@onready var UIComponent: Node = $UIComponent

var ranged_w_component: Node
var melee_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var shield_component: Node

@export var team_id: int = 0
var shielding: bool = false
var knockback: Vector2 = Vector2.ZERO
var knockback_force: int = 200
var body_damage: int

#Physics layers TODO use these
const LAYER_AI_PLAYER_AND_FOOD: int = 1
const LAYER_WORLD_BOUNDARIES: int = 2

@export var current_class: String = "Pawn":
	set(value):
		current_class = value
		if is_node_ready():
			sprite_component._on_promotion_applied(value)

@export var current_melee_weapon: String = "None":
	set(value):
		current_melee_weapon = value
		if is_node_ready():
			manager_component.change_melee_weapon(value)

@export var current_ranged_weapon: String = "None":
	set(value):
		current_ranged_weapon = value
		if is_node_ready():
			manager_component.change_ranged_weapon(value)
			
@export var current_first_ability: String = "None":
	set(value):
		current_first_ability = value
		if is_node_ready():
			manager_component.change_first_ability(value)

@export var current_shield: String = "None":
	set(value):
		current_shield = value
		if is_node_ready():
			manager_component.change_shield(value)

# Initializes UI, colors, and connects component signals.
func _ready() -> void:
	
	if is_node_ready():
		sprite_component._on_promotion_applied(current_class)
		
	collision_layer = LAYER_AI_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_AI_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	# Initialises the weapons and class, uses call_deferred to give the MultiplayerSpawner time to sync sub-nodes
	if multiplayer.is_server() or name == str(multiplayer.get_unique_id()):
		promotion_component.request_promotion.rpc_id.call_deferred(1, current_class)
	
	health_component.died.connect(_on_player_died)

	if name == str(multiplayer.get_unique_id()):
		$SpriteComponent.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
		$AbilityBar.show()
		$HUD/UpgradeUI.hide()
		for button: Node in $HUD/UpgradeUI.get_children():
			button.stat_chosen.connect(_on_stat_chosen)
		$HUD/PromotionUI.hide()
		for button: Node in $HUD/PromotionUI.get_children():
			button.type_chosen.connect(_on_type_chosen)
	else:
		$SpriteComponent.modulate = Color(1, 0, 0)
		$HUD.hide()
		$AbilityBar.hide()

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


# Processes server-side physics and calls local client input gathering.
func _physics_process(delta: float) -> void:
	if name == str(multiplayer.get_unique_id()):
		#if not shielding: # TODO Add this back in
		check_player_input()
		check_ranged_input()
		check_melee_input()
		check_first_ability_input()
		check_shield_input()

	if multiplayer.is_server():
		decrease_knockback(delta)
		velocity = movement_component.get_movement_velocity() + knockback
		move_and_slide()
		handle_collisions()

# Reads WASD input and transmits the movement direction to the server.
func check_player_input() -> void:
	if movement_component.movement_blocked:
		movement_component.set_movement_direction(Vector2.ZERO)
		return
		
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("move_up", "move_down")
	var new_dir: Vector2 = Vector2(x, y).normalized() if x != 0 or y != 0 else Vector2.ZERO
	
	if new_dir != movement_component.input_dir:
		movement_component.set_movement_direction(new_dir)
		if not multiplayer.is_server():
			movement_component.receive_input.rpc_id(1, new_dir)

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
				first_ability_component.request_teleport_area.rpc_id(1, get_global_mouse_position())

# Evaluates continuous input to request shield activation and deactivation from the server.
func check_shield_input() -> void:
	if shield_component:
		var shield_testing = false
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

# Evaluates collisions for bouncing and contact damage.
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
					CandDUtils.knockback_and_damage(collider, body_damage, name, -normal, knockback_force)
					var damage_to_self: int = maxi(1, int(float(body_damage) / 8.0))
					health_component.take_damage(damage_to_self) #This needs to be fixed to use the body damage of the other thing

# Applies an external physics impulse force to the player.
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force
		
# Adds recoil momentum from weapon firing.
func _on_apply_recoil(force: Vector2) -> void:
	print("Recoil applied")
	knockback += force

# Awards points to the attacker, disables the player, and triggers the death UI.
func _on_player_died(attacker_id: String) -> void:
	PointsUtil.give_points_on_death(get_tree().current_scene, attacker_id, leveling_component.total_score)
	
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

func _update_points(new_points: int):
	$HUD/LevelBar.queue_points(new_points)

# Transmits the selected stat upgrade to the server.
func _on_stat_chosen(chosen_stat: String) -> void:
	$HUD/UpgradeUI.hide() 
	if multiplayer.is_server():
		leveling_component.apply_upgrade(chosen_stat)
	else:
		leveling_component.rpc_id(1, "request_upgrade", chosen_stat)

# Transmits the selected class promotion to the server via the promotion component.
func _on_type_chosen(chosen_type: String) -> void:
	$HUD/PromotionUI.hide()
	promotion_component.request_promotion.rpc_id(1, chosen_type)

# Defines an RPC for the server to command the local client to update its sprite.
@rpc("any_peer", "call_local", "reliable")
func update_sprite_rpc(choice: String) -> void:
	sprite_component._on_promotion_applied(choice)
