extends Node2D
class_name AbilityUtils

# Recursively removes logic and collisions from a node to ensure it only acts as a visual prop.
static func strip_physics_and_scripts(node: Node) -> void:
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
		strip_physics_and_scripts(child)

#Returns whether a position is within the map
static func is_position_within_map(main: Node, pos: Vector2) -> bool:
	var buffer: float = 20.0
	return (
		pos.x >= (main.top_left_x + buffer) and
		pos.x <= (main.top_left_x + main.arena_size - buffer) and
		pos.y >= (main.top_left_y + buffer) and
		pos.y <= (main.top_left_y + main.arena_size - buffer)
	)
