extends ShieldComponent
class_name MagicShieldComponent

# Initializes the component and centers the shield directly on the player entity.
func _ready() -> void:
	super._ready()
	position = Vector2.ZERO

# Renders a semi-transparent blue circle to represent the magic bubble.
func _draw() -> void:
	if is_active:
		# Radius matches the CircleShape2D radius
		draw_circle(Vector2.ZERO, 10.0, Color(0.0, 0.5, 1.0, 0.3))
		draw_arc(Vector2.ZERO, 10.0, 0, TAU, 32, Color(0.0, 0.8, 1.0, 0.8), 1.0)
