extends Node2D
class_name MeleeWeaponComponent

@export var melee_damage: int = 100
@export var knockback_force: float = 800.0
@export var attack_cooldown: float = 0.6
@export var attack_duration: float = 0.8

var can_attack: bool = true
var has_hit: bool = false

var default_position: Vector2
var active_tween: Tween

@onready var player: CharacterBody2D = get_parent().get_parent()
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

# Initializes the component by disabling the hitbox and connecting the overlap signal.
func _ready() -> void:
	default_position = position
	
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)

# Validates the attack request, resets the hit flag, and activates the server-side hitbox.
@rpc("any_peer", "call_local", "reliable")
func request_melee_attack(target_pos: Vector2) -> void:
	if not multiplayer.is_server() or not can_attack:
		return
		
	can_attack = false
	has_hit = false
	look_at(target_pos)
	
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	
	get_tree().create_timer(attack_duration).timeout.connect(_on_attack_finished)
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_cooldown_finished)
	
	trigger_visual_attack.rpc(target_pos)

# Evaluates colliding bodies to apply immediate damage and directional knockback.
func _on_body_entered(body: Node2D) -> void:
	if body == player:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(melee_damage, player.name)
		
	if body.has_method("apply_bounce"):
		var direction: Vector2 = global_position.direction_to(body.global_position)
		body.apply_bounce(direction * knockback_force)

	# Safely disables physics checks upon impact and commands clients to retract the weapon.
	if not has_hit:
		has_hit = true
		hitbox.set_deferred("monitoring", false)
		hitbox_shape.set_deferred("disabled", true)
		trigger_visual_retract.rpc()

# Disables the physical hitbox when the active attack window expires.
func _on_attack_finished() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true

# Resets the attack state to allow subsequent strikes.
func _on_cooldown_finished() -> void:
	can_attack = true

# Virtual function to be overridden by specific weapon child classes.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack(_target_pos: Vector2) -> void:
	pass

# Virtual function to be overridden by specific weapon child classes.
@rpc("authority", "call_local", "reliable")
func trigger_visual_retract() -> void:
	pass
