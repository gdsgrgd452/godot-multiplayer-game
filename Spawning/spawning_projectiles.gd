extends Node2D

# A dictionary holding all your different projectile scenes
@export var projectile_scenes: Dictionary = {
	"Arrow": preload("res://Objects/Projectiles/Arrow/arrow.tscn"),
	"Fireball": preload("res://Objects/Projectiles/Fireball/fireball.tscn"),
	"Pin": preload("res://Objects/Projectiles/Pin/pin.tscn")
}

var projectile_counter: int = 0

# Instantiates and configures a new projectile on the server side
func spawn_projectile(spawn_pos: Vector2, dir: Vector2, shooter_id: String, projectile_speed: int, projectile_damage: int, projectile_type: String) -> void:
	if not multiplayer.is_server():
		return
	
	
	if not projectile_scenes.has(projectile_type):
		projectile_type = "Arrow"
	
	var projectile: Projectile = projectile_scenes[projectile_type].instantiate() as Projectile
	var shooter_node: Node2D = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + shooter_id) as Node2D
	
	projectile_counter += 1
	projectile.name = "Proj_" + str(shooter_id) + "_" + str(Time.get_ticks_usec()) + "_" + str(projectile_counter)
	projectile.position = spawn_pos + (dir * 30.0) 
	projectile.direction = dir
	projectile.rotation = dir.angle() + deg_to_rad(90.0)
	projectile.shooter_id = shooter_id
	
	if shooter_node and "team_id" in shooter_node:
		projectile.set_meta("team_id", shooter_node.get("team_id"))
	
	projectile.speed = float(projectile_speed)
	projectile.damage = projectile_damage
	
	
	add_child(projectile, true)
