extends Node2D

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var ui_comp: Node = entity.get_node_or_null("UIComponent")

@export var max_cooldown: float = 5.0
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

# Starts the ability and requests the wall of fire
@rpc("any_peer", "call_local", "reliable")
func request_wof(input_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, input_pos):
		start_pos = input_pos
		waiting_for_end = true
		entity.input_needed = true
		
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Used Wall of Fire!")

@rpc("any_peer", "call_local", "reliable")
func request_second_pos(input_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, start_pos):
		
		if start_pos.distance_to(input_pos) > max_length:
			if ui_comp and entity.is_in_group("player"):
				ui_comp.display_message.rpc_id(entity.name.to_int(), "The wall is too long!")
			return
		
		end_pos = input_pos
		current_cooldown = max_cooldown
		waiting_for_end = false
		queue_redraw()
		entity.input_needed = false
		
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Starting the wall of fire!")
			
		var trap_manager: Node = get_tree().current_scene.get_node_or_null("SpawnedTraps")
		
		if trap_manager and trap_manager.has_method("spawn_wof"):
			current_cooldown = max_cooldown
			
			var new_wall: Node2D = trap_manager.spawn_wof(start_pos, end_pos, entity.name, entity.team_id)
			if new_wall:
				active_walls.append(new_wall)
				new_wall.base_contact_damage = max_damage # Sets the max damage here

func _draw() -> void:
	if waiting_for_end:
		var local_start = to_local(start_pos)
		var world_radius_point = start_pos + Vector2(max_length, 0)
		var local_radius = to_local(world_radius_point).x - local_start.x
		draw_circle(local_start, local_radius, Color(0.0, 0.0, 0.0, 0.173), false, 10.0)
