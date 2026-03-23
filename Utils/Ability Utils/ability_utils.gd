extends Node
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
