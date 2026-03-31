extends Area2D
class_name Projectile

var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 1
var shooter_id: String = "" 
var time_to_live: float = 3.0
var bullet_knockback: float = 250.0

#Physics layers TODO use these
const LAYER_NPC_PLAYER_AND_FOOD: int = 1
const LAYER_WORLD_BOUNDARIES: int = 2

# Connects the collision signal on the server
func _ready() -> void:
	add_to_group("shield_blockable")
	
	collision_layer = LAYER_NPC_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_NPC_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

# Moves the projectile forward on the server side
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		position += direction * speed * delta
		time_to_live -= delta
		if (time_to_live <= 0):
			queue_free()

# Accepts a bounce force to reflect the projectile away from the shield.
func apply_bounce(bounce_force: Vector2) -> void:
	if multiplayer.is_server():
		direction = bounce_force.normalized()
		shooter_id = ""

# Handles core logic when the projectile hits a physics body
func _on_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		# Ignores collision with the shooter
		if body.name == shooter_id:
			return 
		
		if body.is_in_group("boundary"):
			queue_free()
		
		# Checks if the target shares the same team ID as the projectile
		if body.has_method("get") and body.get("team_id") == get_meta("team_id", -1):
			return
		
		if "team_id" in body:
			var target_team = body.get("team_id")
			var my_team = get_meta("team_id", -1)
			if target_team == my_team and target_team != -1: # Don't hit teammates
				return
		
		CandDUtils.knockback_and_damage(body, damage, shooter_id, direction, bullet_knockback)
				
		# Trigger the custom subclass hit behavior
		_on_hit(body)

# VIRTUAL FUNCTION: To be overwritten by subclasses
func _on_hit(_body: Node2D) -> void:
	pass
