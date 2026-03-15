extends Area2D

const SPEED = 800.0
var direction = Vector2.ZERO
var shooter_id = "" # So we don't shoot ourselves!

func _ready():
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Only the server moves the bullet. The Synchronizer updates the clients.
	if multiplayer.is_server():
		position += direction * SPEED * delta

func _on_body_entered(body):
	if multiplayer.is_server():
		# Prevent the bullet from immediately hitting the person who fired it
		if body.name == shooter_id:
			return 
			
		# If we hit another player or food, blast them backwards!
		if body.has_method("apply_bounce"):
			body.apply_bounce(direction * 250)
			
			# Optional: Make the bullet do damage if they have a take_damage method
			if body.is_in_group("food"):
				body.take_damage(50)
		
		# Destroy the bullet after it hits anything (including walls)
		queue_free()
