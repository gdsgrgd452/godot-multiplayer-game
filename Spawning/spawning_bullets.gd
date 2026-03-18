extends Node2D

@export var bullet_scene: PackedScene = preload("res://Objects/Projectiles/Bullet/bullet.tscn")
var bullet_counter: int = 0

# Instantiates and configures a new bullet on the server side
func spawn_bullet(spawn_pos: Vector2, dir: Vector2, shooter_id: String, bullet_speed: int, bullet_damage: int) -> void:
	if multiplayer.is_server():
		var bullet: Node = bullet_scene.instantiate()
		
		bullet_counter += 1
		bullet.name = "Bullet_" + str(bullet_counter)
		
		bullet.position = spawn_pos + (dir * 30) 
		bullet.direction = dir
		bullet.shooter_id = shooter_id
		
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage
		
		# Adds the bullet to the SpawnedBullets node tree
		add_child(bullet, true)
