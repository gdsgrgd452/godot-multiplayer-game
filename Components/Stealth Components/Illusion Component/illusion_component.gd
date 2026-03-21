extends StealthComponent
class_name IllusionComponent

@export var illusion_duration: float = 4.0
@export var illusions_count: int = 4
var illusion_min_range: float = 150.0
var illusion_max_range: float = 400.0

var active_illusions: Array[Node2D] = []

# Receives the requested single illusion execution from the client and triggers it after a stealth delay.
@rpc("any_peer", "call_local", "reliable")
func request_illusion(spawn_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		# Store original physical states, disable hitboxes, and hide the player across the network.
		var original_layer: int = player.collision_layer
		var original_mask: int = player.collision_mask
		player.collision_layer = 0
		player.collision_mask = 0
		trigger_stealth_visuals.rpc(true)
		
		await get_tree().create_timer(1.0).timeout
		
		if not is_instance_valid(player):
			return
			
		# Restore physical presence and simultaneously spawn the illusion while revealing the player.
		player.collision_layer = original_layer
		player.collision_mask = original_mask
		trigger_stealth_visuals.rpc(false)
		trigger_illusion_visuals.rpc(spawn_pos)

# Temporarily hides the player, waits, and then spawns multiple illusions around their new position.
@rpc("any_peer", "call_local", "reliable")
func request_scattered_illusions() -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		var info_label: Node = player.get_node_or_null("HUD/InfoLabel")
		if info_label:
			info_label.display_message.rpc_id(player.name.to_int(), "Ability Used: Illusion")
		
		# Store original physical states, disable hitboxes, and hide the player across the network.
		var original_layer: int = player.collision_layer
		var original_mask: int = player.collision_mask
		player.collision_layer = 0
		player.collision_mask = 0
		trigger_stealth_visuals.rpc(true)
		
		await get_tree().create_timer(1.0).timeout # Remove in the future
		
		if not is_instance_valid(player):
			return
			
		# Restore physical presence and prepare the ring of illusion coordinates.
		player.collision_layer = original_layer
		player.collision_mask = original_mask
		
		var positions: Array[Vector2] = []
		
		for i: int in range(illusions_count):
			var random_angle: float = randf() * TAU
			var random_radius: float = randf_range(illusion_min_range, illusion_max_range)
			var offset: Vector2 = Vector2(cos(random_angle), sin(random_angle)) * random_radius
			positions.append(player.global_position + offset)
			
		trigger_stealth_visuals.rpc(false) # Need to move to happen halfway through (After the illusions appear and the player has had the chance to move). 
		trigger_scattered_illusions.rpc(positions)

# Requests the server to prematurely stop all active illusions.
@rpc("any_peer", "call_local", "reliable")
func request_stop_illusion() -> void:
	if multiplayer.is_server():
		stop_illusion_visuals.rpc()

# Spawns a complete temporary visual duplicate of the player and their active equipment across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_illusion_visuals(spawn_pos: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	_cleanup_illusions()
	
	var illusion: Node2D = _build_illusion_node(spawn_pos, main_scene)
	active_illusions.append(illusion)
	
	var tween: Tween = create_tween()
	tween.tween_property(illusion, "modulate:a", 0.0, illusion_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(illusion.queue_free)

# Iterates through the provided positions to spawn multiple synchronous player duplicates.
@rpc("authority", "call_local", "reliable")
func trigger_scattered_illusions(positions: Array[Vector2]) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	_cleanup_illusions()
	
	# Instantiate an independent visual prop for every coordinate calculated by the server.
	for pos: Vector2 in positions:
		var illusion: Node2D = _build_illusion_node(pos, main_scene)
		active_illusions.append(illusion)
		
		# Starts invisible to sync with the stealth component's fade-in time (0.75s)
		illusion.modulate.a = 0.0
		
		var tween: Tween = create_tween()
		tween.tween_property(illusion, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(illusion, "modulate:a", 0.0, illusion_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(illusion.queue_free)

# Commands all clients to rapidly fade out and destroy all tracked active illusions.
@rpc("authority", "call_local", "reliable")
func stop_illusion_visuals() -> void:
	for illusion: Node2D in active_illusions:
		if is_instance_valid(illusion):
			var tween: Tween = create_tween()
			tween.tween_property(illusion, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(illusion.queue_free)
	active_illusions.clear()

# Instantly removes all currently active illusions to prevent orphaned visual nodes.
func _cleanup_illusions() -> void:
	for illusion: Node2D in active_illusions:
		if is_instance_valid(illusion):
			illusion.queue_free()
	active_illusions.clear()

# Constructs the illusion node with duplicated sprites and equipment stripped of their physics.
func _build_illusion_node(spawn_pos: Vector2, parent_scene: Node) -> Node2D:
	var illusion_node: Node2D = Node2D.new()
	illusion_node.global_position = spawn_pos
	parent_scene.add_child(illusion_node)
	
	# Duplicate the primary visual representation of the player entity. (They are invisible at the time)
	var player_sprite: Sprite2D = player.get_node_or_null("PlayerSprite") as Sprite2D
	if player_sprite:
		var sprite_dup: Sprite2D = player_sprite.duplicate(0) as Sprite2D
		_strip_physics_and_scripts(sprite_dup)
		sprite_dup.modulate.a = 1.0 
		illusion_node.add_child(sprite_dup)
		illusion_node.scale *= 0.25
		
	# Create a proxy container to hold all duplicated active equipment.
	var comp_container: Node2D = Node2D.new()
	comp_container.name = "Components"
	illusion_node.add_child(comp_container)
	
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
			
	return illusion_node

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
