extends Node2D
class_name StealthComponent

@export var max_cooldown: float = 12.0
@export var stealth_duration: float = 3.0
var current_cooldown: float = 0.0

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Reduces the active ability cooldown timer exclusively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Receives the requested stealth execution and manages the timed visibility and collision changes.
@rpc("any_peer", "call_local", "reliable")
func request_stealth() -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		print("Stealth activating")
		
		var ui_comp: Node = entity.get_node_or_null("UIComponent")
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Used Stealth!")
		
		var original_layer: int = entity.collision_layer
		var original_mask: int = entity.collision_mask

		entity.collision_layer = 0
		entity.collision_mask = entity.LAYER_WORLD_BOUNDARIES
		
		trigger_ui_visibility.rpc(true)
		trigger_stealth_visuals.rpc(true)
		
		await get_tree().create_timer(stealth_duration).timeout
		
		if not is_instance_valid(entity):
			return
			
		entity.collision_layer = original_layer
		entity.collision_mask = original_mask
		trigger_ui_visibility.rpc(false)
		trigger_stealth_visuals.rpc(false)

# Commands all clients to toggle identifying UI elements for remote observers.
@rpc("authority", "call_local", "reliable")
func trigger_ui_visibility(is_hidden: bool) -> void:
	var ui_comp: Node = entity.get_node_or_null("UIComponent")
	if ui_comp and ui_comp.has_method("toggle_external_ui"):
		ui_comp.toggle_external_ui(is_hidden)

# Commands all clients to fade the player's primary sprite and equipment visibility.
@rpc("authority", "call_local", "reliable")
func trigger_stealth_visuals(is_stealth: bool) -> void:
	var sprite: Sprite2D = entity.get_node_or_null("SpriteComponent") as Sprite2D
	var components: Node2D = entity.get_node_or_null("Components") as Node2D
	
	var target_alpha: float = 1.0
	var duration: float = 0.75
	
	if is_stealth:
		duration = 0.2 
		target_alpha = 0.5 if entity.name == str(multiplayer.get_unique_id()) else 0.0
			
	if sprite:
		var tween_sprite: Tween = create_tween()
		tween_sprite.tween_property(sprite, "modulate:a", target_alpha, duration)
		
	if components:
		var tween_comps: Tween = create_tween()
		tween_comps.tween_property(components, "modulate:a", target_alpha, duration)
