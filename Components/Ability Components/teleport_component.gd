extends Node2D

var max_cooldown: float = 5.0
var current_cooldown: float = 0.0
var max_range: float = 100.0

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Reduces the active teleport cooldown timer exclusively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Receives the requested teleport destination from the client and executes it if the cooldown is ready.
@rpc("any_peer", "call_local", "reliable")
func request_teleport(target_pos: Vector2) -> void:
	if multiplayer.is_server():
		if current_cooldown <= 0.0:
			_perform_teleport(target_pos)

# Calculates the clamped destination, updates the physical location, and broadcasts the visual trigger.
func _perform_teleport(target_pos: Vector2) -> void:
	var start_pos: Vector2 = player.global_position
	var direction: Vector2 = start_pos.direction_to(target_pos)
	var distance: float = minf(start_pos.distance_to(target_pos), max_range)
	var final_position: Vector2 = start_pos + (direction * distance)
	
	player.global_position = final_position
	current_cooldown = max_cooldown
	
	trigger_teleport_visuals.rpc()

# Executes a localized scaling tween animation on all clients to visually emphasize the teleportation.
@rpc("authority", "call_local", "reliable")
func trigger_teleport_visuals() -> void:
	var sprite: Sprite2D = player.get_node("PlayerSprite") as Sprite2D
	if not sprite:
		return
		
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
