extends AreaWeaponComponent
class_name MagicAreaWeaponComponent

# Commands all local clients to execute the expanding magic circle animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack() -> void:
	super() # Executes the show() command from the base AreaWeaponComponent class
	
	print("Triggering visual attack")
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	radius = 0.0

	active_tween.tween_property(self, "radius", max_radius, attack_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
