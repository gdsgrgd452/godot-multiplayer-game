extends StealthComponent
class_name IllusionComponent

@export var illusion_duration: float = 4.0
@export var illusions_count: int = 4
var illusion_min_range: float = 150.0
var illusion_max_range: float = 400.0

var active_illusions: Array[Dictionary] = []
var last_player_position: Vector2 = Vector2.ZERO

# Tracks player movement and updates all active illusion positions based on their assigned directions.
func _physics_process(_delta: float) -> void:
	if last_player_position == Vector2.ZERO:
		last_player_position = entity.global_position
		return

	var movement_delta: float = entity.global_position.distance_to(last_player_position)
	
	if movement_delta > 0.0:
		for i: int in range(active_illusions.size() - 1, -1, -1):
			var data: Dictionary = active_illusions[i]
			var illusion_node: Variant = data.get("node")
			if is_instance_valid(illusion_node):
				var move_vec: Vector2 = data["dir"] * movement_delta
				illusion_node.global_position += move_vec
			else:
				active_illusions.remove_at(i)

	last_player_position = entity.global_position

# Receives the requested single illusion execution and hides identifying UI until the end of the duration.
@rpc("any_peer", "call_local", "reliable")
func request_illusion(spawn_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		var original_layer: int = entity.collision_layer
		var original_mask: int = entity.collision_mask
		entity.collision_layer = 0
		entity.collision_mask = entity.LAYER_WORLD_BOUNDARIES
		
		trigger_ui_visibility.rpc(true)
		trigger_stealth_visuals.rpc(true) # invisible 
		
		await get_tree().create_timer(1.0).timeout
		
		if not is_instance_valid(entity):
			return
			
		entity.collision_layer = original_layer
		entity.collision_mask = original_mask
		trigger_stealth_visuals.rpc(false)
		
		var random_dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
		trigger_illusion_visuals.rpc(spawn_pos, random_dir)
		
		await get_tree().create_timer(illusion_duration - 1.0).timeout
		if is_instance_valid(entity):
			trigger_ui_visibility.rpc(false)

# Manages the scattered illusion sequence by keeping identifying UI hidden for the entire movement duration.
@rpc("any_peer", "call_local", "reliable")
func request_scattered_illusions() -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		current_cooldown = max_cooldown
		
		var ui_comp: Node = entity.get_node_or_null("UIComponent")
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Used your illusion!")
		
		var original_layer: int = entity.collision_layer
		var original_mask: int = entity.collision_mask

		entity.collision_layer = 0
		entity.collision_mask = entity.LAYER_WORLD_BOUNDARIES
		
		# Hide both alpha and identifying UI.
		trigger_ui_visibility.rpc(true)
		trigger_stealth_visuals.rpc(true)
		
		await get_tree().create_timer(1.0).timeout
		
		if not is_instance_valid(entity):
			return
			
		var positions: Array[Vector2] = []
		var directions: Array[Vector2] = []
		
		for i: int in range(int(illusions_count)):
			positions.append(get_position_for_illusion())
			directions.append(Vector2.RIGHT.rotated(randf() * TAU))
			
		# Restore alpha so player is visible, but identifying UI stays hidden.
		entity.collision_layer = original_layer
		entity.collision_mask = original_mask
		trigger_stealth_visuals.rpc(false)
		trigger_scattered_illusions.rpc(positions, directions)
		
		# Wait for the moving stage to conclude before showing the username and health bar.
		await get_tree().create_timer(illusion_duration).timeout
		
		if is_instance_valid(entity):
			trigger_ui_visibility.rpc(false)

# Calculates a valid random position for an illusion while ensuring it remains within map boundaries and avoiding infinite recursion.
func get_position_for_illusion() -> Vector2:
	var max_attempts: int = 15
	for i: int in range(max_attempts):
		var random_angle: float = randf() * TAU
		var random_radius: float = randf_range(illusion_min_range, illusion_max_range)
		var offset: Vector2 = Vector2(cos(random_angle), sin(random_angle)) * random_radius
		var potential_pos: Vector2 = entity.global_position + offset
		if AbilityUtils.is_position_within_map(get_tree().current_scene, potential_pos):
			return potential_pos
	
	return entity.global_position

# Spawns a complete temporary visual duplicate of the player and their active equipment across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_illusion_visuals(spawn_pos: Vector2, move_dir: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	_cleanup_illusions()
	
	var illusion: Node2D = _build_illusion_node(spawn_pos, main_scene)
	active_illusions.append({"node": illusion, "dir": move_dir})
	
	var tween: Tween = create_tween()
	tween.tween_property(illusion, "modulate:a", 0.0, illusion_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(illusion.queue_free)

# Iterates through the provided positions to spawn multiple synchronous player duplicates.
@rpc("authority", "call_local", "reliable")
func trigger_scattered_illusions(positions: Array[Vector2], directions: Array[Vector2]) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	_cleanup_illusions()
	
	for i: int in range(positions.size()):
		var pos: Vector2 = positions[i]
		var dir: Vector2 = directions[i]
		var illusion: Node2D = _build_illusion_node(pos, main_scene)
		
		active_illusions.append({"node": illusion, "dir": dir})
		
		illusion.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(illusion, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(illusion, "modulate:a", 0.0, illusion_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(illusion.queue_free)

# Commands all clients to rapidly fade out and destroy all tracked active illusions.
@rpc("authority", "call_local", "reliable")
func stop_illusion_visuals() -> void:
	for data: Dictionary in active_illusions:
		var illusion_node: Variant = data.get("node")
		if is_instance_valid(illusion_node):
			var tween: Tween = create_tween()
			tween.tween_property(illusion_node, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(illusion_node.queue_free)
	active_illusions.clear()

# Instantly removes all currently active illusions to prevent orphaned visual nodes.
func _cleanup_illusions() -> void:
	for data: Dictionary in active_illusions:
		var illusion_node: Variant = data.get("node")
		if is_instance_valid(illusion_node):
			illusion_node.queue_free()
	active_illusions.clear()

# Constructs the illusion node with duplicated sprites and equipment stripped of their physics.
func _build_illusion_node(spawn_pos: Vector2, parent_scene: Node) -> Node2D:
	var illusion_node: Node2D = Node2D.new()
	illusion_node.global_position = spawn_pos
	parent_scene.add_child(illusion_node)
	
	var player_sprite: Sprite2D = entity.get_node_or_null("PlayerSprite") as Sprite2D
	if player_sprite:
		var sprite_dup: Sprite2D = player_sprite.duplicate(0) as Sprite2D
		AbilityUtils.strip_physics_and_scripts(sprite_dup)
		sprite_dup.modulate.a = 1.0 
		illusion_node.add_child(sprite_dup)
		illusion_node.scale *= 0.25
		
	var comp_container: Node2D = Node2D.new()
	comp_container.name = "Components"
	illusion_node.add_child(comp_container)
	
	var active_comps: Array[Node] = [
		entity.melee_w_component,
		entity.ranged_w_component,
		entity.first_ability_component,
		entity.shield_component
	]
	
	for comp: Node in active_comps:
		if comp and comp.visible:
			var comp_dup: Node = comp.duplicate(0)
			AbilityUtils.strip_physics_and_scripts(comp_dup)
			comp_container.add_child(comp_dup)
			
	return illusion_node
