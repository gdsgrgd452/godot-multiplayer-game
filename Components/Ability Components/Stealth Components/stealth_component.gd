extends Node2D
class_name StealthComponent

@export var max_cooldown: float = 12.0
@export var stealth_duration: float = 3.0
var current_cooldown: float = 0.0

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Reduces the active ability cooldown timer exclusively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Receives the requested stealth execution from the client and triggers it if the cooldown is ready.
@rpc("any_peer", "call_local", "reliable")
func request_stealth() -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		var info_label: Node = player.get_node_or_null("HUD/InfoLabel")
		if info_label:
			info_label.display_message.rpc_id(player.name.to_int(), "Ability Used: Stealth")
		
		# Store original physical states and remove the player from the collision world.
		var original_layer: int = player.collision_layer
		var original_mask: int = player.collision_mask

		# Disable player interaction but maintain world collision.
		player.collision_layer = 0
		player.collision_mask = player.LAYER_WORLD_BOUNDARIES
		
		trigger_stealth_visuals.rpc(true)
		
		await get_tree().create_timer(stealth_duration).timeout
		
		if not is_instance_valid(player):
			return
			
		# Restore physical presence and command clients to fade the player back in.
		player.collision_layer = original_layer
		player.collision_mask = original_mask
		trigger_stealth_visuals.rpc(false)

# Commands all clients to fade the player's primary sprite and equipment visibility.
@rpc("authority", "call_local", "reliable")
func trigger_stealth_visuals(is_stealth: bool) -> void:
	var sprite: Sprite2D = player.get_node_or_null("PlayerSprite") as Sprite2D
	var components: Node2D = player.get_node_or_null("Components") as Node2D
	
	# Determine target transparency. The local player gets 50% opacity, others get 0%.
	var target_alpha: float = 1.0
	var duration: float = 0.75
	
	if is_stealth:
		duration = 0.2 
		if player.name == str(multiplayer.get_unique_id()):
			target_alpha = 0.5 
		else:
			target_alpha = 0.0 
			
	# Apply the opacity tweens to both the player sprite and their equipped visual items.
	if sprite:
		var tween_sprite: Tween = create_tween()
		tween_sprite.tween_property(sprite, "modulate:a", target_alpha, duration)
		
	if components:
		var tween_comps: Tween = create_tween()
		tween_comps.tween_property(components, "modulate:a", target_alpha, duration)
