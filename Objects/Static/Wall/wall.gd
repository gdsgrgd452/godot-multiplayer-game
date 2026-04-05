extends StaticBody2D

# Synchronizes the dimensions of the wall to ensure Polygon2D visuals match across the network.
@export var wall_size: Vector2 = Vector2.ZERO:
	set(value):
		wall_size = value
		if is_node_ready():
			_update_visuals()

# Initializes the visual polygon and collision shape based on the synchronized size.
func _ready() -> void:
	# Resides on Layer 2 (Boundaries) and detects nothing (Mask 0).
	collision_layer = 2
	collision_mask = 0
	
	add_to_group("boundary")
	
	var hitbox: CollisionShape2D = get_node_or_null("Hitbox")
	if is_instance_valid(hitbox) and hitbox.shape:
		# Duplicates the shape resource so changes to one wall do not affect others.
		hitbox.shape = hitbox.shape.duplicate()
	
	_update_visuals()

# Updates the Polygon2D points and RectangleShape2D dimensions to reflect the current wall size.
func _update_visuals() -> void:
	var hitbox: CollisionShape2D = get_node_or_null("Hitbox")
	var visual: Polygon2D = get_node_or_null("Colour")
	
	if is_instance_valid(hitbox) and hitbox.shape is RectangleShape2D:
		hitbox.shape.size = wall_size
		
	if is_instance_valid(visual):
		var half: Vector2 = wall_size / 2.0
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y)
		])
