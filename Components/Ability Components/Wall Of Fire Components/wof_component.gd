extends Node2D

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var ui_comp: Node = entity.get_node_or_null("UIComponent")

@export var wof_cooldown: float = 5.0
var current_cooldown: float = 0.0

var start_pos: Vector2
var end_pos: Vector2
var max_length: float = 400
var max_damage: int = 10

var waiting_for_end: bool = false

var active_walls: Array[Node2D] = []

func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta
	if waiting_for_end:
		queue_redraw()

# Starts the ability and shows the range in which to pick a 2nd point
@rpc("any_peer", "call_local", "reliable")
func request_wof(input_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	if current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, input_pos):
		var peer_id: int = entity.peer_id
		start_pos = input_pos
		# Notifies the specific client to begin drawing the placement radius and lock movement.
		trigger_placement_visuals.rpc_id(peer_id, true, input_pos)

		
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(peer_id, "Pick the second point!")

# Rec
@rpc("any_peer", "call_local", "reliable")
func request_second_pos(input_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	if current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, start_pos):
		if start_pos.distance_to(input_pos) > max_length:
			if ui_comp and entity.is_in_group("player"):
				ui_comp.display_message.rpc_id(entity.peer_id, "The wall is too long!")
			return
		
		var peer_id: int = entity.peer_id
		end_pos = input_pos
		current_cooldown = wof_cooldown
		# Notifies the client to stop drawing and release the movement lock.
		trigger_placement_visuals.rpc_id(peer_id, false, Vector2.ZERO)
		
		if is_instance_valid(ui_comp):
			ui_comp.handle_ability_activated(self, "WOF", wof_cooldown)
			
		var trap_manager: Node = get_tree().current_scene.get_node_or_null("SpawnedTraps")
		if is_instance_valid(trap_manager) and trap_manager.has_method("spawn_wof"):
			var new_wall: Node2D = trap_manager.spawn_wof(start_pos, end_pos, entity.name, entity.team_id)
			if new_wall:
				active_walls.append(new_wall)
				new_wall.set("base_contact_damage", max_damage)

# Synchronizes the placement state and boundary visuals to the owner client.
@rpc("authority", "call_local", "reliable")
func trigger_placement_visuals(is_active: bool, p_start_pos: Vector2) -> void:
	waiting_for_end = is_active
	entity.input_needed = is_active
	start_pos = p_start_pos
	queue_redraw()

# Removes all active walls of fire currently tracked by this component.
func cleanup() -> void:
	for wall: Node2D in active_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	active_walls.clear()

# Renders the placement boundary circle with scale-adjusted dimensions.
func _draw() -> void:
	if waiting_for_end:
		var inv_scale: Vector2 = Vector2.ONE / entity.scale
		var local_start: Vector2 = to_local(start_pos)
		# Corrects the visual radius to match world-space length regardless of entity scale.
		var draw_radius: float = max_length * inv_scale.x
		draw_circle(local_start, draw_radius, Color(0.0, 0.0, 0.0, 0.173), false, 10.0 * inv_scale.x)
