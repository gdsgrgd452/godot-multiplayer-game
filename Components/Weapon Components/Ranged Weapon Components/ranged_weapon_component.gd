extends Node2D
class_name RangedWeaponComponent

# Tells the parent to apply knockback
signal apply_recoil(recoil_force: Vector2)

@onready var entity: Node = get_parent().get_parent()
@onready var ui_comp: UIComponent = entity.get_node("UIComponent")

@export var projectile_type: String = "Default" # An identifier passed to the projectile so it knows what sprite to load

# Weapon Stats
var shooting: bool = false
var reload_speed: float = 0.4
var shot_cooldown: float = reload_speed
var projectile_speed: int = 200
var projectile_damage: int = 10
var projectile_force: float = 2.0
var recoil_strength: int = 30
var accuracy: float = 100.0

# Both the server and the local client need to run the reload timer
func _physics_process(delta: float) -> void:
	if multiplayer.is_server() or entity.name == str(multiplayer.get_unique_id()):
		if shot_cooldown > 0:
			shot_cooldown -= delta
			#print(entity.name + " " + str(shot_cooldown))
		shooting = shot_cooldown > (reload_speed - 0.1)

# Processes the shooting logic and resets the cooldown timer exclusively on the server for NPC or locally for players.
func shoot(click_pos: Vector2) -> void:
	if shot_cooldown > 0.0:
		return
		
	var shoot_dir: Vector2 = (click_pos - entity.global_position).normalized()
	
	# Handle edge case where target is exactly at entity position to prevent zero-vector normalization.
	if shoot_dir == Vector2.ZERO:
		shoot_dir = Vector2.RIGHT.rotated(entity.global_rotation)
	
	var accuracy_r: float = 100.0 - accuracy
	var bloom_amount: float = randf_range(-accuracy_r / 500.0, accuracy_r / 500.0)
	shoot_dir = (shoot_dir + Vector2(bloom_amount, bloom_amount)).normalized()
	
	shot_cooldown = reload_speed
	shooting = true
	
	if multiplayer.is_server():
		_spawn_projectile_and_recoil(shoot_dir)
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
