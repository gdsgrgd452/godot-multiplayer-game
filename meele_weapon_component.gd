extends Node2D
class_name MeleeWeaponComponent

@export var melee_damage: int = 25
@export var knockback_force: float = 800.0
@export var attack_cooldown: float = 0.6
@export var attack_duration: float = 0.15

var can_attack: bool = true

@onready var player: CharacterBody2D = get_parent().get_parent()
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

# Initializes the component by disabling the hitbox and connecting the overlap signal.
func _ready() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)

# Validates the attack request, points the weapon, and activates the server-side hitbox.
@rpc("any_peer", "call_local", "reliable")
func request_melee_attack(target_pos: Vector2) -> void:
	if not multiplayer.is_server() or not can_attack:
		return
		
	can_attack = false
	look_at(target_pos)
	
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	
	get_tree().create_timer(attack_duration).timeout.connect(_on_attack_finished)
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_cooldown_finished)
	
	trigger_visual_thrust.rpc(target_pos)

# Evaluates colliding bodies to apply immediate damage and directional knockback.
func _on_body_entered(body: Node2D) -> void:
	if body == player:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(melee_damage, player.name)
		
	if body.has_method("apply_bounce"):
		var direction: Vector2 = global_position.direction_to(body.global_position)
		body.apply_bounce(direction * knockback_force)

# Disables the physical hitbox when the active attack window expires.
func _on_attack_finished() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true

# Resets the attack state to allow subsequent strikes.
func _on_cooldown_finished() -> void:
	can_attack = true

# Commands all local clients to execute the visual weapon animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_thrust(target_pos: Vector2) -> void:
	look_at(target_pos)
	print("correct")
	# TODO: Insert local Tween or AnimationPlayer logic here to lunge the spear sprite forward and back.
