extends Node2D
class_name AreaWeaponComponent

@export var area_damage: int = 25
@export var max_radius: float = 500.0
@export var knockback_force: float = 3000.0
@export var attack_cooldown: float = 5.0
@export var attack_duration: float = 0.5

var active_tween: Tween
var can_attack: bool = true

@onready var player: CharacterBody2D = get_parent().get_parent()
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

var radius: float = 100.0:
	set(value):
		radius = value
		queue_redraw()
		# Sync the physics shape radius with the visual radius
		if is_node_ready() and hitbox_shape.shape is CircleShape2D:
			hitbox_shape.shape.radius = value

# Initializes the component, hides visuals, ensures unique shapes, and connects the overlap signal.
func _ready() -> void:
	hide()
	
	# Crucial: Prevents multiple players from sharing and overwriting the same shape resource
	if hitbox_shape.shape:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
		
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)
# Validates the attack request, activates the server-side hitbox, and starts timers.
@rpc("any_peer", "call_local", "reliable")
func request_area_attack() -> void:
	if not multiplayer.is_server() or not can_attack:
		return
		
	can_attack = false
	
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	
	get_tree().create_timer(attack_duration).timeout.connect(_on_attack_finished)
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_cooldown_finished)
	
	trigger_visual_attack.rpc()

# Evaluates colliding bodies to apply immediate damage and directional knockback.
func _on_body_entered(body: Node2D) -> void:
	if body == player:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(area_damage, player.name)
		
	if body.has_method("apply_bounce"):
		var direction: Vector2 = global_position.direction_to(body.global_position)
		body.apply_bounce(direction * knockback_force)

# Disables the physical hitbox and commands clients to hide the visual effect.
func _on_attack_finished() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	trigger_visual_finished.rpc()

# Resets the attack state to allow subsequent strikes.
func _on_cooldown_finished() -> void:
	can_attack = true

# Unhides the component and serves as a virtual function for child class animations.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack() -> void:
	show()
	# Child classes will override this to add Tween logic for the radius

# Hides the component across all clients when the attack window ends.
@rpc("authority", "call_local", "reliable")
func trigger_visual_finished() -> void:
	hide()

# Draws the area shape dynamically based on the synchronized radius variable.
func _draw() -> void:
	if active_tween:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.4))
