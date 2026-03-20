extends Projectile
class_name Arrow

# Arrows pierce through targets but lose 70% of their remaining lifespan/momentum
func _on_hit(_body: Node2D) -> void:
	time_to_live = time_to_live * 0.3
