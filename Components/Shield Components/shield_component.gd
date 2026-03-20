extends Node2D
class_name ShieldComponent

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

@export var max_shield_health: int = 100
var shield_health: int = 100
@export var active_duration: float = 200.0

var is_active: bool = false

# Initializes the shield state, groups, and connects collision signals.
func _ready() -> void:
	hide()
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.area_entered.connect(_on_body_entered)
	add_to_group("shield")

# Validates activation criteria and starts the shield timer on the server.
@rpc("any_peer", "call_local", "reliable")
func request_shield_activation() -> void:
	if not multiplayer.is_server() or is_active:
		return
		
	shield_health = max_shield_health
	trigger_shield_visuals.rpc(true)
	get_tree().create_timer(active_duration).timeout.connect(_on_shield_timeout)

# Validates deactivation criteria and stops the shield on the server.
@rpc("any_peer", "call_local", "reliable")
func request_shield_deactivation() -> void:
	if not multiplayer.is_server() or not is_active:
		return
	deactivate_shield()

# Deactivates the shield when the active duration timer finishes.
func _on_shield_timeout() -> void:
	if is_active:
		deactivate_shield()

# Triggers network-wide deactivation of the shield visuals and state.
func deactivate_shield() -> void:
	trigger_shield_visuals.rpc(false)

# Toggles the active state, player variable, and visibility of the shield across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_shield_visuals(activate: bool) -> void:
	is_active = activate
	player.shielding = activate
	if activate:
		show()
	else:
		hide()

# Evaluates incoming collisions to reduce health, retract melee weapons, or reflect projectiles.
func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server() or not is_active or body == player:
		return

	if body.is_in_group("shield_blockable"):
		shield_health -= 1
		
		if body.has_method("apply_bounce"):
			var direction: Vector2 = global_position.direction_to(body.global_position)
			body.apply_bounce(direction * 500.0)
			
		var parent_node: Node = body.get_parent()
		if parent_node and parent_node.has_method("trigger_visual_retract"):
			parent_node.has_hit = true
			parent_node.is_attacking = false
			parent_node.trigger_visual_retract.rpc()
			
	if shield_health <= 0:
		deactivate_shield()
