extends Area2D

var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 1
var shooter_id: String = "" 
var time_to_live: float = 1.0

# Connects the collision signal on the server
func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

# Moves the bullet forward on the server side
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		position += direction * speed * delta
		time_to_live -= delta
		if (time_to_live <= 0):
			queue_free()

# Handles logic when the bullet hits a physics body
func _on_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		# Ignores collision with the shooter
		if body.name == shooter_id:
			return 
			
		# Applies knockback to the hit entity
		if body.has_method("apply_bounce"):
			body.apply_bounce(direction * 250)
			
			# Applies damage to the hit entity
			if body.has_method("take_damage"):
				body.take_damage(damage, shooter_id)
		
		# Destroys the bullet upon impact
		queue_free()