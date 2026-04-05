extends Projectile
class_name Pin

@export var red_texture: Texture2D
@export var green_texture: Texture2D
@export var blue_texture: Texture2D

# Connects the collision signal on the server
func _ready() -> void:
	
	super._ready()
	
	#Sets it to red blue or green
	var sprite_comp = get_node_or_null("Sprite2D")
	if sprite_comp: 
		sprite_comp.texture = [red_texture, green_texture, blue_texture].pick_random()
	else:
		printerr("No sprite node for pin")


# Pins pierce through targets but lose 90% of their remaining lifespan/momentum
func _on_hit(_body: Node2D) -> void:
	time_to_live = time_to_live * 0.1

# Moves the projectile forward on the server side
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		position += direction * speed * delta
		time_to_live -= delta
		if (time_to_live <= 0):
			queue_free()
		rotation += delta * 15 # Spins the pin as it moves
