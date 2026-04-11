extends RangedWeaponComponent
class_name BowComponent

func _ready() -> void:
	projectile_type = "Arrow"

@export var orbit_distance: float = 30.0

# Updates the shield orbit position locally and syncs it across the network.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if entity.name == str(multiplayer.get_unique_id()):
		var mouse_pos: Vector2 = get_global_mouse_position()
		update_orbit(mouse_pos)
		sync_orbit.rpc(mouse_pos)

# Calculates the positional offset and rotation to orbit the player.
func update_orbit(target_pos: Vector2) -> void:
	var dir: Vector2 = entity.global_position.direction_to(target_pos)
	position = dir * orbit_distance
	rotation = dir.angle()

# Synchronizes the shield orbit position to remote clients.
@rpc("any_peer", "call_remote", "unreliable")
func sync_orbit(target_pos: Vector2) -> void:
	if str(multiplayer.get_remote_sender_id()) == entity.name:
		update_orbit(target_pos)
