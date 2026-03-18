extends MeleeWeaponComponent
class_name SpearComponent

@export var lunge_distance: float = 2500

# Commands all local clients to execute the physical spear lunge and reset animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack(target_pos: Vector2) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	position = default_position
	look_at(target_pos)
	
	var forward_pos: Vector2 = position + (transform.x * lunge_distance)
	active_tween = create_tween()
	
	active_tween.tween_property(self, "position", forward_pos, attack_duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "position", default_position, attack_duration * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# Commands all local clients to cleanly interrupt the spear lunge and instantly retract.
@rpc("authority", "call_local", "reliable")
func trigger_visual_retract() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	active_tween.tween_property(self, "position", default_position, attack_duration * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
