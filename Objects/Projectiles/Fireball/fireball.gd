extends Projectile
class_name Fireball

# Fireballs are immediately destroyed on impact
func _on_hit(_body: Node2D) -> void:
	# TODO: Add splash?
	queue_free()
