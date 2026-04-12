extends Node2D
class_name RangedWeaponComponent

@onready var entity: Node = get_parent().get_parent()
@onready var ui_comp: UIComponent = entity.get_node("UIComponent")
@onready var audio_comp: AudioStreamPlayer2D = entity.get_node("AudioComponent")

@export var projectile_type: String = "Default" # An identifier passed to the projectile so it knows what sprite to load

# Weapon Stats
var projectile_speed: int = 200
var projectile_damage: int = 10
var projectile_force: float = 2.0
var recoil_strength: int = 300
var accuracy: float = 100.0

var is_charging: bool = false
var charge_timer: float = 0.0
var max_charge_time: float = 2.0
var ghost_node: Sprite2D = null
var last_aim_pos: Vector2 = Vector2.ZERO

# Tracks the charging state and manages the instantiation of visual indicators.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() and entity.name != str(multiplayer.get_unique_id()):
		return
	if is_charging:
		
		charge_timer = minf(charge_timer + delta, max_charge_time)
		_update_ghost_visuals()
		
		# Auto-fire if the player holds past the maximum charge time
		if multiplayer.is_server() and charge_timer >= max_charge_time:
			last_aim_pos = get_shoot_at_position()
			_execute_fire()

func get_shoot_at_position() -> Vector2:
	if entity.is_in_group("player"):
		return get_global_mouse_position()
	elif entity.is_in_group("npc"):
		if is_instance_valid(entity.main_brain.combat_brain.current_target):
			return entity.main_brain.combat_brain.current_target.global_position
		else:
			printerr("NPC tried to shoot with no target")
	elif entity.is_in_group("tower"):
		if is_instance_valid(entity.current_target):
			return entity.current_target.global_position
	printerr("No position to shoot at")
	return Vector2.ZERO

# Initiates the charging sequence and spawns a local visual ghost of the projectile.
@rpc("any_peer", "call_local", "reliable")
func request_start_charge() -> void:
	if is_charging:
		return
		
	is_charging = true
	charge_timer = 0.0
	
	if not multiplayer.is_server():
		return
		
	# Command all clients to show the charging visual
	trigger_visual_ghost.rpc(true)

# Terminates the charge and triggers the authoritative projectile spawn on the server.
@rpc("any_peer", "call_local", "reliable")
func request_release_charge(click_pos: Vector2) -> void:
	if not is_charging:
		return
	last_aim_pos = click_pos
	_execute_fire()

# Handles the server-side calculations for projectile strength and resets component state.
func _execute_fire() -> void:
	if not is_charging:
		return
		
	var charge_pct: float = charge_timer / max_charge_time
	is_charging = false
	
	if multiplayer.is_server():
		var dir: Vector2 = (last_aim_pos - entity.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT.rotated(rotation)
			
		# Apply accuracy bloom
		var accuracy_r: float = 100.0 - accuracy
		var bloom: float = randf_range(-accuracy_r / 500.0, accuracy_r / 500.0)
		dir = (dir + Vector2(bloom, bloom)).normalized()
		
		# Scale speed and damage based on charge (minimum 25% effectiveness)
		var final_speed: int = int(float(projectile_speed) * maxf(0.25, charge_pct))
		var final_damage: int = int(float(projectile_damage) * maxf(0.25, charge_pct))
		
		_spawn_projectile_and_recoil(dir, final_speed, final_damage)
		trigger_visual_ghost.rpc(false)

func _spawn_projectile_and_recoil(dir: Vector2, final_speed: int, final_damage: int) -> void:
	var shooter_identity: String = entity.name

	# If the component is attached to a tower, use the tower's stored owner ID for kill credit.
	if "owner_peer_id" in entity and entity.get("owner_peer_id") != "":
		shooter_identity = entity.get("owner_peer_id")
		
	get_tree().current_scene.get_node("SpawnedProjectiles").spawn_projectile(entity.global_position, dir, shooter_identity, final_speed, final_damage, projectile_type)
	
	# TODO Make this an rpc
	if entity.has_method("apply_recoil"):
		entity.apply_recoil.rpc_id(1, -dir * (recoil_strength * (final_speed / projectile_speed)))

	play_audio()

	# TODO UI
	#if is_instance_valid(ui_comp) and entity.is_in_group("player"):
		#ui_comp.handle_attack_activated("Ranged", max_charge_time)

func play_audio() -> void:
	pass

# Creates or removes a semi-transparent visual representation of the projectile.
@rpc("authority", "call_local", "reliable")
func trigger_visual_ghost(visible_state: bool) -> void:
	if visible_state:
		if is_instance_valid(ghost_node):
			ghost_node.queue_free()
			
		ghost_node = Sprite2D.new()
		# Logic to determine texture based on projectile_type
		ghost_node.texture = ImageUtils.get_image_by_projectile_name(projectile_type)
		ghost_node.modulate = Color(1.0, 1.0, 1.0, 0.2)
		ghost_node.scale = Vector2.ZERO
		ghost_node.z_index = 2
		add_child(ghost_node)
	else:
		if is_instance_valid(ghost_node):
			ghost_node.queue_free()
			ghost_node = null

# Updates the ghost node scale and opacity based on the current charge percentage.
func _update_ghost_visuals() -> void:
	if not is_instance_valid(ghost_node):
		return
	
	var max_scale: float = 0.1
	match projectile_type:
		"Arrow":
			max_scale = 0.013
		"Pin":
			max_scale = 0.05
		"Fireball":
			max_scale = 0.01
		
	var pct: float = charge_timer / max_charge_time
	ghost_node.scale = Vector2(max_scale, max_scale) * pct
	ghost_node.modulate.a = lerpf(0.2, 0.7, pct)
	if projectile_type == "Fireball":
		if entity.is_in_group("player"):
			var dir: Vector2 = (entity.global_position - get_global_mouse_position()).normalized()
			
			ghost_node.rotation = dir.angle() - 55.0
