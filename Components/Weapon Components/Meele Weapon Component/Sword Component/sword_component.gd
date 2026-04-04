extends MeleeWeaponComponent
class_name SwordComponent

@export var swing_angle: float = 120.0
@export var lunge_distance: float = 20.0

var swing_direction: int = 1
var base_aim_rotation: float

func _init() -> void:
	attack_cooldown = 0.4
	attack_duration = 0.2
	retractable = false

# Commands all local clients to execute a directional lunging sweep animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack(target_pos: Vector2) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	# Reset position first to ensure look_at calculates the perfect angle from the player's center
	position = default_position
	look_at(target_pos)
	base_aim_rotation = rotation
	
	# "Teleport" the sword forward for extended directional reach
	var forward_pos: Vector2 = position + (transform.x * lunge_distance)
	position = forward_pos
	
	var half_arc: float = deg_to_rad(swing_angle / 2.0)
	var start_rot: float = base_aim_rotation - (half_arc * swing_direction)
	var target_rot: float = base_aim_rotation + (half_arc * swing_direction)
	
	rotation = start_rot
	active_tween = create_tween()
	#active_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) # Stops tunelling
	active_tween.tween_property(self, "rotation", target_rot, attack_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	swing_direction *= -1

# Commands all local clients to interrupt the sweep, bounce off the target, and retract position.
@rpc("authority", "call_local", "reliable")
func trigger_visual_retract() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	active_tween.tween_property(self, "rotation", base_aim_rotation, attack_duration * 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(self, "position", default_position, attack_duration * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
