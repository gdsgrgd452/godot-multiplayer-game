extends Node2D
class_name MeleeWeaponComponent

@export var melee_damage: int = 100
@export var knockback_force: float = 800.0
@export var attack_cooldown: float = 0.6
@export var attack_duration: float = 0.8

var can_attack: bool = true
var has_hit: bool = false
var is_attacking: bool = false # Add this state tracker

var retractable: bool = true

var default_position: Vector2
var active_tween: Tween

@onready var entity: CharacterBody2D = get_parent().get_parent()
@onready var ui_comp: UIComponent = entity.get_node("UIComponent")
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

func _ready() -> void:
	default_position = position
	hitbox.add_to_group("shield_blockable")
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	hitbox.body_entered.connect(_on_target_entered)

@rpc("any_peer", "call_local", "reliable")
func request_melee_attack(target_pos: Vector2) -> void:
	if not multiplayer.is_server() or not can_attack:
		return
		
	can_attack = false
	has_hit = false
	is_attacking = true # Open the damage window
	look_at(target_pos)
	
	if is_instance_valid(ui_comp) and entity.is_in_group("player"):
		ui_comp.handle_attack_activated("Melee", attack_cooldown + attack_duration)
	
	get_tree().create_timer(attack_duration).timeout.connect(_on_attack_finished)
	
	trigger_visual_attack.rpc(target_pos)

func _on_attack_finished() -> void:
	is_attacking = false 
	has_hit = false
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_cooldown_finished) # Starts the cooldown when attack is completely done

# Handles collisions
func _on_target_entered(target: Node2D) -> void:
	# Instantly ignore overlaps if we aren't swinging, or if we hit ourselves
	if not is_attacking or target == entity or has_hit:
		return
	
	if "team_id" in target and target.get("team_id") == entity.team_id: # Same team
		return
	
	var dir: Vector2 = global_position.direction_to(target.global_position)
	CandDUtils.knockback_and_damage(target, melee_damage, entity.name, dir, knockback_force)

	has_hit = true
	is_attacking = false # Prevent double-hitting
	
	if retractable:
		trigger_visual_retract.rpc()

func _on_cooldown_finished() -> void:
	can_attack = true

@rpc("authority", "call_local", "reliable")
func trigger_visual_attack(_target_pos: Vector2) -> void:
	pass

@rpc("authority", "call_local", "reliable")
func trigger_visual_retract() -> void:
	pass
