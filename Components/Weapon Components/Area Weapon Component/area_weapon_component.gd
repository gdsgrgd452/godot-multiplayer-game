extends Node2D
class_name AreaWeaponComponent

@export var area_damage: int = 10
@export var max_radius: float = 200.0
@export var knockback_force: float = 500.0
@export var max_cooldown: float = 5.0
@export var attack_duration: float = 0.5

var current_cooldown: float = 0.0
var current_duration: float = 0.0
var active_tween: Tween

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

var radius: float = 100.0:
	set(value):
		radius = value
		queue_redraw()
		if is_node_ready() and hitbox_shape.shape is CircleShape2D:
			var circle_shape: CircleShape2D = hitbox_shape.shape as CircleShape2D
			circle_shape.radius = value

# Initializes the component, hides visuals, ensures unique shapes, and connects the overlap signal.
func _ready() -> void:
	hide()
	
	if hitbox_shape.shape:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
		
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)

# Tracks cooldown and attack duration natively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		if current_cooldown > 0.0:
			current_cooldown -= delta
			
		if current_duration > 0.0:
			current_duration -= delta
			if current_duration <= 0.0:
				_on_attack_finished()

# Validates the attack request, activates the server-side hitbox, and starts tracking variables.
@rpc("any_peer", "call_local", "reliable")
func request_area_attack() -> void:
	if not multiplayer.is_server() or current_cooldown > 0.0:
		return
		
	current_cooldown = max_cooldown
	current_duration = attack_duration
	
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	
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

# Unhides the component and serves as a virtual function for child class animations.
@rpc("authority", "call_local", "reliable")
func trigger_visual_attack() -> void:
	show()

# Hides the component across all clients when the attack window ends.
@rpc("authority", "call_local", "reliable")
func trigger_visual_finished() -> void:
	hide()

# Draws the area shape dynamically based on the synchronized radius variable.
func _draw() -> void:
	if active_tween:
		draw_circle(Vector2.ZERO, radius, Color(0, 0, 1, 0.4))
