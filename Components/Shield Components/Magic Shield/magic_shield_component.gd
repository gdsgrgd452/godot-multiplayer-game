extends ShieldComponent
class_name MagicShieldComponent

# Initializes the component and centers the shield directly on the player entity.
func _ready() -> void:
	super._ready()
	position = Vector2.ZERO
