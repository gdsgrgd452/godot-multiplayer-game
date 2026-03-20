extends Node
class_name RangedWeaponComponent

# Tells the parent to apply knockback
signal apply_recoil(recoil_force: Vector2)

@onready var player: Node = get_parent().get_parent()

# An identifier passed to the projectile so it knows what sprite to load
@export var projectile_type: String = "Default"

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
	if multiplayer.is_server() or player.name == str(multiplayer.get_unique_id()):
		if shot_cooldown > 0:
			shot_cooldown -= delta
		shooting = shot_cooldown > (reload_speed - 0.1)

# The player script calls this and passes the mouse position
func shoot(click_pos: Vector2) -> void:
	if shot_cooldown > 0:
		return
		
	var shoot_dir: Vector2 = (click_pos - player.global_position).normalized()
	
	#Adds bloom to create inaccuracy
	var accuracy_r = 100 - accuracy # So increasing accuracy decreases bloom
	var bloom_amount: float = randf_range(-accuracy_r/500, accuracy_r/500)
	var dir_with_bloom: Vector2 = Vector2(shoot_dir.x + bloom_amount, shoot_dir.y + bloom_amount)
	shoot_dir = dir_with_bloom
	
	shot_cooldown = reload_speed
	shooting = true
	
	if multiplayer.is_server():
		_spawn_projectile_and_recoil(shoot_dir)
	else:
		rpc_id(1, "request_shoot", shoot_dir)

# Spawns the projectile and triggers the recoil signal
func _spawn_projectile_and_recoil(dir: Vector2) -> void:
	# Make sure to rename your spawner node and function in your main scene!
	get_tree().current_scene.get_node("SpawnedProjectiles").spawn_projectile(player.global_position, dir, player.name, projectile_speed, projectile_damage, projectile_type)
	apply_recoil.emit(-dir * recoil_strength)

# Used by clients to ask the server to spawn a projectile
@rpc("any_peer", "call_remote", "reliable")
func request_shoot(dir: Vector2) -> void:
	if multiplayer.is_server():
		# Security check
		if str(multiplayer.get_remote_sender_id()) == player.name:
			if shot_cooldown <= 0:
				shot_cooldown = reload_speed
				_spawn_projectile_and_recoil(dir)
