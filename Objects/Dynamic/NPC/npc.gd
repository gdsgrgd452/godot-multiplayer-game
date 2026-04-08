extends CharacterBody2D

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var sprite_component: Sprite2D = $SpriteComponent
@onready var manager_component: ComponentManager = $Components/ComponentManager
@onready var leveling_component: Node = $Components/LevelingComponent
@onready var promotion_component: Node = $Components/PromotionComponent

@export var team_id: int = -1:
	set(value):
		team_id = value
		print(str(team_id))
		if is_node_ready():
			apply_team_color()
		else:
			get_tree().create_timer(0.5).timeout.connect(apply_team_color)

var knockback: Vector2 = Vector2.ZERO
var body_damage: int = 10
var kill_value: int = 200

var ranged_w_component: Node
var melee_w_component: Node
var area_w_component: Node
var first_ability_component: Node
var shield_component: Node

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

@export var current_second_ability: String = "None":
	set(value):
		current_second_ability = value
		if is_node_ready():
			manager_component.change_second_ability(value)

@export var current_shield: String = "None":
	set(value):
		current_shield = value
		if is_node_ready():
			manager_component.change_shield(value)

# Initializes the NPC, sets the starting class configuration, and connects death signals.
func _ready() -> void:
	add_to_group("npc")
	
	if not has_node("MultiplayerSynchronizer"):
		printerr("NPC ", multiplayer.get_unique_id(), " missing Synchronizer on ", name)
		
	if is_node_ready():
		apply_team_color()
		
	health_component.died.connect(_on_npc_died)
	
	collision_layer = LAYER_AI_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_AI_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	
# Force initialization of weapons, sprite and abilities based on the default class.
func force_promotion_refresh() -> void:
	if is_instance_valid(promotion_component):
		promotion_component.change_weapon(current_class)
		promotion_component.apply_promotion_stats(current_class)
	if is_instance_valid(sprite_component):
		sprite_component._on_promotion_applied(current_class)

# Evaluates the team_id against the local player to apply a green or red modulate
func apply_team_color() -> void:
	var sprite: Sprite2D = get_node_or_null("SpriteComponent") as Sprite2D
	if not sprite:
		printerr("No sprite")
		return
		
	var local_id: String = str(multiplayer.get_unique_id())
	var players_container: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers")
	
	if not is_instance_valid(players_container):
		printerr("No players")
		return
		
	var local_player: Node2D = players_container.get_node_or_null(local_id) as Node2D
	
	# If the local player hasn't spawned yet, wait and try again shortly
	if not is_instance_valid(local_player):
		get_tree().create_timer(0.5).timeout.connect(apply_team_color)
		printerr("No local player")
		return
	
	if "team_id" in local_player:
		if self.team_id == local_player.get("team_id"):
			sprite.modulate = Color(0.0, 1.0, 0.0) # Green for teammate
		else:
			sprite.modulate = Color(1.0, 0.0, 0.0) # Red for enemy

# Manages server-side physics and movement for the NPC entity.
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_decrease_knockback(delta)
		var move_velocity: Vector2 = movement_component.get_movement_velocity(delta)
		velocity = (move_velocity * 0.8) + knockback
		move_and_slide()
		_handle_collisions()

# Decays the physical impulse force applied to the NPC over time.
func _decrease_knockback(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)

# Processes kinematic collisions to apply contact damage and bouncing.
func _handle_collisions() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		var normal: Vector2 = collision.get_normal()
		
		knockback = normal * 500
		if collider and collider.has_method("apply_bounce"):
			collider.apply_bounce(-normal * 200)

# Grants points to the attacker and removes the NPC from the scene tree.
func _on_npc_died(attacker_id: String) -> void:
	KillingUtils.route_kill_credits_and_points(get_tree().current_scene, attacker_id, leveling_component.total_score + kill_value, name)
	manager_component.cleanup_all_abilities() # Triggers the component manager to remove lingering ability visuals
	process_mode = Node.PROCESS_MODE_DISABLED# Disable collisions and processing so the dead body doesn't interact with the world
	hide()
	queue_free()

# Accepts an external physics force applied to the NPC.
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force
