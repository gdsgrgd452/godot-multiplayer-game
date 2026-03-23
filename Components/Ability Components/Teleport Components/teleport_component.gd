extends Node2D

var max_cooldown: float = 5.0
var current_cooldown: float = 0.0
var teleport_time: float = 1.0

@export var max_range: float = 50.0:
	set(value):
		max_range = value
		queue_redraw()

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node2D = player.get_node("Components/MovementComponent")
var active_illusion: Node2D = null

# Tracks the active tweens so they can be explicitly killed before setting manual scale values.
var active_tween_sprite: Tween
var active_tween_components: Tween

# Ensures the debug radius is drawn immediately upon entering the scene tree.
func _ready() -> void:
	queue_redraw()

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
	# Calculate the final position bounded by the maximum teleport range.
	var start_pos: Vector2 = player.global_position
	var direction: Vector2 = start_pos.direction_to(target_pos)
	var distance: float = minf(start_pos.distance_to(target_pos), max_range)
	var final_position: Vector2 = start_pos + (direction * distance)
	

	# Block movement, trigger the shrink animation and wait for it to complete.
	move_comp.movement_blocked = true
	current_cooldown = max_cooldown
	trigger_teleport_visuals.rpc(true, final_position) 
	await get_tree().create_timer(teleport_time + 0.1).timeout # + 0.1 so it doesnt teleport before the visuals are done
	
	# Allow movement, snap the player to the destination and restore their normal scale.
	player.global_position = final_position
	trigger_teleport_visuals.rpc(false, final_position) 
	move_comp.movement_blocked = false

# Executes a localized scaling tween animation on all clients to visually emphasize the teleportation.
@rpc("authority", "call_local", "reliable")
func trigger_teleport_visuals(going_out: bool, target_pos: Vector2 = Vector2.ZERO) -> void:
	var sprite: Sprite2D = player.get_node("PlayerSprite") as Sprite2D
	var components: Node2D = player.get_node("Components") as Node2D
	if not sprite or not components:
		return
	
	var info_label: Node = player.get_node_or_null("HUD/InfoLabel")
	if info_label:
		info_label.display_message.rpc_id(player.name.to_int(), "Ability Used: Teleport")
	
	# Kill any ongoing scaling tweens to prevent them from overriding the new manual scale.
	if active_tween_sprite and active_tween_sprite.is_valid():
		active_tween_sprite.kill()
	if active_tween_components and active_tween_components.is_valid():
		active_tween_components.kill()
		
	if going_out:
		# Shrink both the main sprite and the component container simultaneously.
		active_tween_sprite = create_tween()
		active_tween_components = create_tween() 
		
		active_tween_sprite.tween_property(sprite, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.5, 1.5))
		active_tween_components.tween_property(components, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.0, 1.0))
		_spawn_teleport_illusion(target_pos)
	else:
		# Instantly restore the player's scale and destroy the temporary destination illusion.
		sprite.scale = Vector2(1.5, 1.5)
		components.scale = Vector2(1.0, 1.0)
		
		if is_instance_valid(active_illusion):
			active_illusion.queue_free()

# Spawns a visual duplicate at the destination that grows as the player shrinks.
func _spawn_teleport_illusion(spawn_pos: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	if is_instance_valid(active_illusion):
		active_illusion.queue_free()

	# Create the base node for the illusion at the target destination.
	active_illusion = Node2D.new()
	active_illusion.global_position = spawn_pos
	main_scene.add_child(active_illusion)
	
	# Duplicate the player's sprite, strip its logic, and set it to grow from 10% to 25% scale.
	var player_sprite: Sprite2D = player.get_node_or_null("PlayerSprite") as Sprite2D
	if player_sprite:
		var sprite_dup: Sprite2D = player_sprite.duplicate(0) as Sprite2D
		sprite_dup.scale = Vector2(0.1, 0.1)
		#If you want to make the illusion a diff colour uncomment this #sprite_dup.modulate = player_sprite.modulate (DO NOT REMOVE)
		_strip_physics_and_scripts(sprite_dup)
		active_illusion.add_child(sprite_dup)
		
		var tween_sprite: Tween = create_tween()
		tween_sprite.bind_node(active_illusion)
		tween_sprite.tween_property(sprite_dup, "scale", Vector2(0.3, 0.3), teleport_time).from(Vector2(0.1, 0.1))
		
	# Create a proxy container to hold all duplicated active equipment.
	var comp_container: Node2D = Node2D.new()
	comp_container.name = "Components"
	comp_container.scale = Vector2(0.1, 0.1)
	active_illusion.add_child(comp_container)
	
	var active_comps: Array[Node] = [
		player.melee_w_component,
		player.ranged_w_component,
		player.first_ability_component,
		player.shield_component
	]
	
	# Iterate through equipped items, duplicate them, strip their logic, and attach them to the illusion.
	for comp: Node in active_comps:
		if comp and comp.visible:
			var comp_dup: Node = comp.duplicate(0)
			_strip_physics_and_scripts(comp_dup)
			comp_container.add_child(comp_dup)
			
	# Grow the equipment container in tandem with the illusion sprite.
	var tween_components: Tween = create_tween()
	tween_components.bind_node(active_illusion)
	tween_components.tween_property(comp_container, "scale", Vector2(0.3, 0.3), teleport_time).from(Vector2(0.1, 0.1))

# Recursively removes logic and collisions from a node to ensure it only acts as a visual prop.
func _strip_physics_and_scripts(node: Node) -> void:
	# Disable all processing and script execution for the current node.
	node.set_script(null)
	node.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Remove or disable any collision detection capabilities to prevent invisible interactions.
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.queue_free()
	elif node is Area2D:
		node.monitoring = false
		node.monitorable = false
	elif node is PhysicsBody2D:
		node.collision_layer = 0
		node.collision_mask = 0
		
	# Recursively apply the stripping process to all nested children.
	for child: Node in node.get_children():
		_strip_physics_and_scripts(child)

# Draws a solid boundary representing the maximum valid teleport distance exclusively for the local player.
func _draw() -> void:
	if player.name == str(multiplayer.get_unique_id()):
		draw_arc(Vector2.ZERO, max_range*4, 0.0, TAU, 300, Color(1.0, 0.0, 1.0, 1.0), 2.0)
