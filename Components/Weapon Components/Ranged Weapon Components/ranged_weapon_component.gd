extends Node2D
class_name RangedWeaponComponent

# Tells the parent to apply knockback
signal apply_recoil(recoil_force: Vector2)

@onready var entity: Node = get_parent().get_parent()
@onready var ui_comp: UIComponent = entity.get_node("UIComponent")
@onready var audio_comp: AudioStreamPlayer2D = entity.get_node("AudioComponent")

@export var projectile_type: String = "Default" # An identifier passed to the projectile so it knows what sprite to load

# Weapon Stats
var reload_speed: float = 0.4
var shot_cooldown: float = reload_speed
var projectile_speed: int = 200
var projectile_damage: int = 10
var projectile_force: float = 2.0
var recoil_strength: int = 30
var accuracy: float = 100.0

var charging: bool = false
var charged: bool = false
var charging_weapon: bool = false
var max_charge_time: bool = 1.0
var charge_time: float = 1.0
var charge_force: float = 0.0

# Both the server and the local client need to run the reload timer
func _physics_process(delta: float) -> void:
	if multiplayer.is_server() or entity.name == str(multiplayer.get_unique_id()):
		if charging_weapon and charging:
			handle_charging(delta)
		else:
			if shot_cooldown > 0:
				shot_cooldown -= delta

func handle_charging(delta: float) -> void:
	charge_force += 3.0 * delta
	charge_time -= delta
	if charge_time <= 0.0:
		charging = false
		charged = true
		print("Loaded")
		charge_time = max_charge_time
		charge_force = 0.0

# Processes the shooting logic and resets the cooldown timer exclusively on the server for NPC or locally for players.
func shoot(click_pos: Vector2) -> void:
	if not charging_weapon and shot_cooldown > 0.0:
		return
	
	if charging_weapon and charging:
		return
	
	var shoot_dir: Vector2 = (click_pos - entity.global_position).normalized()
	
	# Handle edge case where target is exactly at entity position to prevent zero-vector normalization.
	if shoot_dir == Vector2.ZERO:
		shoot_dir = Vector2.RIGHT.rotated(entity.global_rotation)
	
	var accuracy_r: float = 100.0 - accuracy
	var bloom_amount: float = randf_range(-accuracy_r / 500.0, accuracy_r / 500.0)
	shoot_dir = (shoot_dir + Vector2(bloom_amount, bloom_amount)).normalized()
	
	shot_cooldown = reload_speed
	
	if multiplayer.is_server():
		if charging_weapon and not charged:
			charging = true
		else:
			_spawn_projectile_and_recoil(shoot_dir)
	else:
		if charging_weapon and not charged:
			request_start_charge.rpc_id(1)
		else:
			request_shoot.rpc_id(1, shoot_dir)

# Spawns the projectile and triggers the recoil signal
func _spawn_projectile_and_recoil(dir: Vector2) -> void:
	var shooter_identity: String = entity.name
	
	# If the component is attached to a tower, use the tower's stored owner ID for kill credit.
	if "owner_peer_id" in entity and entity.get("owner_peer_id") != "":
		shooter_identity = entity.get("owner_peer_id")
		
	get_tree().current_scene.get_node("SpawnedProjectiles").spawn_projectile(entity.global_position, dir, shooter_identity, projectile_speed, projectile_damage, projectile_type)
	apply_recoil.emit(-dir * recoil_strength)
	print("Shoot" + str(dir))
	
	play_audio()
	
	if charging_weapon:
		charged = false
	
	if is_instance_valid(ui_comp) and entity.is_in_group("player"):
		ui_comp.handle_attack_activated("Ranged", reload_speed)

# Used by clients to ask the server to spawn a projectile
@rpc("any_peer", "call_remote", "reliable")
func request_shoot(dir: Vector2) -> void:
	if multiplayer.is_server():
		# Security check
		if str(multiplayer.get_remote_sender_id()) == entity.name:
			if shot_cooldown <= 0:
				shot_cooldown = reload_speed
				_spawn_projectile_and_recoil(dir)

# To request to start charging up a melee weapon
@rpc("any_peer", "call_remote", "reliable")
func request_start_charge(dir: Vector2) -> void:
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == entity.name:
				charging = true

func play_audio() -> void:
	pass
