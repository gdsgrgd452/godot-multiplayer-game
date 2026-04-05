extends TeleportComponent
class_name TeleportCrushComponent

@export var area_damage: int = 25
@export var knockback_force: float = 1200.0
@export var max_radius: float = 300.0
@export var tp_crush_cooldown: float = 8.0
@export var attack_duration: float = 2.0

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision


var active_area_tween: Tween
var current_radius: float = 0.0:
	set(value):
		current_radius = value
		queue_redraw()
		if is_node_ready() and hitbox_shape.shape is CircleShape2D:
			(hitbox_shape.shape as CircleShape2D).radius = value

# Duplicates the collision shape and prepares the crush hitbox signal connections.
func _ready() -> void:
	super._ready()
	if hitbox_shape.shape:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)

# Redirects the crush request through the base teleportation logic.
@rpc("any_peer", "call_local", "reliable")
func request_teleport_area(target_pos: Vector2) -> void:
	request_teleport(target_pos)

# Returns the specific cooldown variable utilized by the leveling system for this component.
func get_cooldown_duration() -> float:
	return tp_crush_cooldown

# Initiates the area attack sequence upon completing the teleport movement.
func _on_teleport_finished() -> void:
	_execute_crush_attack()

# Activates the server-side crush hitbox and triggers expansion visuals.
func _execute_crush_attack() -> void:
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	trigger_visual_crush.rpc()

	await get_tree().create_timer(attack_duration).timeout

	hitbox.monitoring = false
	hitbox_shape.disabled = true
	trigger_visual_finished.rpc()

# Evaluates targets hit by the shockwave to apply damage and displacement.
func _on_body_entered(body: Node2D) -> void:
	if body == entity:
		return
	var dir: Vector2 = global_position.direction_to(body.global_position)
	CandDUtils.knockback_and_damage(body, area_damage, entity.name, dir, knockback_force)

# Animates the expanding crush circle on the local client's screen.
@rpc("authority", "call_local", "reliable")
func trigger_visual_crush() -> void:
	if entity.name == str(multiplayer.get_unique_id()):
		show()
		if active_area_tween and active_area_tween.is_valid():
			active_area_tween.kill()
		active_area_tween = create_tween()
		current_radius = 0.0
		active_area_tween.tween_property(self, "current_radius", max_radius, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Resets the visual state of the area attack once the duration concludes.
@rpc("authority", "call_local", "reliable")
func trigger_visual_finished() -> void:
	current_radius = 0.0

# Shows the shockwave range
func _draw() -> void:
	super._draw()
	if entity.name == str(multiplayer.get_unique_id()):
		if current_radius > 0.0:
			draw_circle(Vector2.ZERO, current_radius, Color(1, 0, 0, 0.74), false, 2.0)
			draw_circle(Vector2.ZERO, max_radius, Color(1, 1, 0, 0.74), false, 2.0)
