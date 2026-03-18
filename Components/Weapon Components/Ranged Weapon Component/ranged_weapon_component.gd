extends Node

# Tells the parent to apply knockback
signal apply_recoil(recoil_force: Vector2)

@onready var player: Node = get_parent().get_parent()

# Weapon Stats
var shooting: bool = false
var reload_speed: float = 0.5
var shot_cooldown: float = reload_speed
var bullet_speed: int = 500
var bullet_damage: int = 150
var recoil_strength: int = 30

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
	
	shot_cooldown = reload_speed
	shooting = true
	
	if multiplayer.is_server():
		_spawn_bullet_and_recoil(shoot_dir)
	else:
		rpc_id(1, "request_shoot", shoot_dir)

# Spawns the bullet and triggers the recoil signal
func _spawn_bullet_and_recoil(dir: Vector2) -> void:
	get_tree().current_scene.get_node("SpawnedBullets").spawn_bullet(player.global_position, dir, player.name, bullet_speed, bullet_damage)
	apply_recoil.emit(-dir * recoil_strength)

# Used by clients to ask the server to spawn a bullet
@rpc("any_peer", "call_remote", "reliable")
func request_shoot(dir: Vector2) -> void:
	if multiplayer.is_server():
		# Security check
		if str(multiplayer.get_remote_sender_id()) == player.name:
			if shot_cooldown <= 0:
				shot_cooldown = reload_speed
				_spawn_bullet_and_recoil(dir)
