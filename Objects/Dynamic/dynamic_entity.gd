extends CharacterBody2D
class_name DynamicEntity

@onready var movement_component: Node = $Components/MovementComponent
@onready var health_component: Node = $Components/HealthComponent
@onready var leveling_component: LevelingComponent = $Components/LevelingComponent
@onready var promotion_component: PromotionComponent = $Components/PromotionComponent
@onready var manager_component: ComponentManager = $Components/ComponentManager
@onready var sprite_component: Sprite2D = $SpriteComponent

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


enum WeaponType {
	Melee,
	Ranged
}

@export var weapon_in_hand: WeaponType = WeaponType.Melee:
	set(value):
		weapon_in_hand = value
		if is_node_ready():
			manager_component.switch_weapon_in_hand(value)
			

var ranged_w_component: RangedWeaponComponent
var melee_w_component: MeleeWeaponComponent
var first_ability_component: Node2D
var second_ability_component: Node2D
var shield_component: ShieldComponent

var shielding: bool = false
var knockback: Vector2 = Vector2.ZERO
var knockback_force: int = 200
var body_damage: int

var kill_value: int = 200

#Physics layers TODO use these
const LAYER_NPC_PLAYER_AND_FOOD: int = 1
const LAYER_WORLD_BOUNDARIES: int = 2

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
					health_component.take_damage(damage_to_self, "", true) #This needs to be fixed to use the body damage of the other thing

# Applies an external physics impulse force to the player.
func apply_bounce(force: Vector2) -> void:
	if multiplayer.is_server():
		knockback = force
		
# Adds recoil momentum from weapon firing.
@rpc("authority", "call_local", "reliable")
func apply_recoil(force: Vector2) -> void:
	knockback += force

# Auto kills anything outside the bounds
func kill_if_outside_bounds() -> bool:
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, global_position):
		health_component.take_damage(99999999999, "", true)
		return true
	return false
