extends MeleeWeaponComponent
class_name SpearComponent

@export var lunge_distance: float = 50 # In reality - 
var pullback_distance: float = 25.0

func _ready() -> void:
	super._ready()
	retractable = false

# Commands all local clients to execute the physical spear lunge and reset animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack(target_pos: Vector2) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	position = default_position
	look_at(target_pos)
	
	var back_pos: Vector2 = position - (transform.x * pullback_distance)
	var forward_pos: Vector2 = position + (transform.x * lunge_distance) # 0.05 transform

	active_tween = create_tween()
	active_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) # Stops tunelling
	active_tween.tween_property(self, "position", back_pos, attack_duration * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(self, "position", forward_pos, attack_duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "position", default_position, attack_duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
# Commands all local clients to cleanly interrupt the spear lunge and instantly retract.
@rpc("authority", "call_local", "reliable")
func trigger_visual_retract() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	active_tween.tween_property(self, "position", default_position, attack_duration * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
