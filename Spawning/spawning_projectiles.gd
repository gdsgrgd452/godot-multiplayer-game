extends Node2D

# A dictionary holding all your different projectile scenes
@export var projectile_scenes: Dictionary = {
	"Arrow": preload("res://Objects/Projectiles/Arrow/arrow.tscn"),
	"Fireball": preload("res://Objects/Projectiles/Fireball/fireball.tscn"),
}

var projectile_counter: int = 0

# Instantiates and configures a new projectile on the server side
func spawn_projectile(spawn_pos: Vector2, dir: Vector2, shooter_id: String, projectile_speed: int, projectile_damage: int, projectile_type: String) -> void:
	if multiplayer.is_server():
		# Safety check to ensure the requested projectile exists
		if not projectile_scenes.has(projectile_type):
			printerr("Projectile type not found: " + projectile_type + ". Defaulting.")
			projectile_type = "Default"
			
		var projectile: Node = projectile_scenes[projectile_type].instantiate()
		
		projectile_counter += 1
		projectile.name = "Projectile_" + str(projectile_counter)
		
		projectile.position = spawn_pos + (dir * 30) 
		projectile.direction = dir
		projectile.rotation = dir.angle() + deg_to_rad(90)
		projectile.shooter_id = shooter_id
		
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage

		projectile.time_to_live = projectile.time_to_live * 2.0
		
		# Adds the projectile to the SpawnedProjectiles node tree
		add_child(projectile, true)
