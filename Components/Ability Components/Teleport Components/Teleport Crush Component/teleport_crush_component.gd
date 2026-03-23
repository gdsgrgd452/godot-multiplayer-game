extends Node2D
class_name TeleportCrushComponent

# Teleport settings
@export var max_range: float = 600.0
@export var teleport_time: float = 0.5
@export var max_cooldown: float = 8.0

# Area settings
@export var area_damage: int = 25
@export var max_radius: float = 300.0
@export var knockback_force: float = 800.0
@export var attack_duration: float = 0.6

var current_cooldown: float = 0.0
var active_illusion: Node2D = null
var active_tween_sprite: Tween
var active_tween_components: Tween
var crush_visual_tween: Tween
var current_radius: float = 0.0

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node2D = player.get_node("Components/MovementComponent")
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

# Initializes the component, duplicates the collision shape, and connects the damage signal.
func _ready() -> void:
	if hitbox_shape.shape:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
	
	var circle_shape: CircleShape2D = hitbox_shape.shape as CircleShape2D
	if circle_shape:
		circle_shape.radius = max_radius
		
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_crush_body_entered)
	queue_redraw()

# Reduces the ability cooldown on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Validates the teleport request and initiates the server-side execution sequence.
@rpc("any_peer", "call_local", "reliable")
func request_teleport_crush(target_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		_perform_teleport_crush(target_pos)

# Orchestrates the physical movement, movement blocking, and the subsequent crush attack.
func _perform_teleport_crush(target_pos: Vector2) -> void:
	var start_pos: Vector2 = player.global_position
	var direction: Vector2 = start_pos.direction_to(target_pos)
	var distance: float = minf(start_pos.distance_to(target_pos), max_range)
	var final_position: Vector2 = start_pos + (direction * distance)
	
	current_cooldown = max_cooldown
	move_comp.movement_blocked = true
	
	trigger_teleport_visuals.rpc(true, final_position)
	await get_tree().create_timer(teleport_time + 0.05).timeout
	
	if not is_instance_valid(player):
		return
		
	player.global_position = final_position
	trigger_teleport_visuals.rpc(false, final_position)
	
	_trigger_server_crush()
	
	move_comp.movement_blocked = false

# Enables the physical hitbox on the server and broadcasts the crush visual trigger to clients.
func _trigger_server_crush() -> void:
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	trigger_crush_visual.rpc()
	
	await get_tree().create_timer(attack_duration).timeout
	
	hitbox.monitoring = false
	hitbox_shape.disabled = true

# Evaluates targets inside the crush area to apply damage and knockback.
func _on_crush_body_entered(body: Node2D) -> void:
	if body == player:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(area_damage, player.name)
		
	if body.has_method("apply_bounce"):
		var direction: Vector2 = global_position.direction_to(body.global_position)
		body.apply_bounce(direction * knockback_force)

# Synchronizes the player scaling and illusion spawning across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_teleport_visuals(going_out: bool, target_pos: Vector2 = Vector2.ZERO) -> void:
	var sprite: Sprite2D = player.get_node("PlayerSprite") as Sprite2D
	var components: Node2D = player.get_node("Components") as Node2D
	
	if active_tween_sprite and active_tween_sprite.is_valid():
		active_tween_sprite.kill()
	if active_tween_components and active_tween_components.is_valid():
		active_tween_components.kill()
		
	if going_out:
		active_tween_sprite = create_tween()
		active_tween_components = create_tween()
		active_tween_sprite.tween_property(sprite, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.5, 1.5))
		active_tween_components.tween_property(components, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.0, 1.0))
		_spawn_teleport_illusion(target_pos)
	else:
		sprite.scale = Vector2(1.5, 1.5)
		components.scale = Vector2(1.0, 1.0)
		if is_instance_valid(active_illusion):
			active_illusion.queue_free()

# Executes the expanding visual circle animation at the teleport destination.
@rpc("authority", "call_local", "reliable")
func trigger_crush_visual() -> void:
	if crush_visual_tween and crush_visual_tween.is_valid():
		crush_visual_tween.kill()
	
	current_radius = 0.0
	crush_visual_tween = create_tween()
	crush_visual_tween.tween_property(self, "current_radius", max_radius, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	crush_visual_tween.parallel().tween_property(self, "modulate:a", 0.0, attack_duration).from(1.0)
	crush_visual_tween.tween_callback(func() -> void: current_radius = 0.0; modulate.a = 1.0)

# Creates a visual duplicate of the player at the destination during the teleport transition.
func _spawn_teleport_illusion(spawn_pos: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if is_instance_valid(active_illusion):
		active_illusion.queue_free()

	active_illusion = Node2D.new()
	active_illusion.global_position = spawn_pos
	main_scene.add_child(active_illusion)
	
	var player_sprite: Sprite2D = player.get_node_or_null("PlayerSprite") as Sprite2D
	if player_sprite:
		var sprite_dup: Sprite2D = player_sprite.duplicate(0) as Sprite2D
		sprite_dup.scale = Vector2(0.1, 0.1)
		_strip_physics_and_scripts(sprite_dup)
		active_illusion.add_child(sprite_dup)
		var tween: Tween = create_tween().bind_node(active_illusion)
		tween.tween_property(sprite_dup, "scale", Vector2(0.3, 0.3), teleport_time)
	
	var comp_container: Node2D = Node2D.new()
	comp_container.scale = Vector2(0.1, 0.1)
	active_illusion.add_child(comp_container)
	
	var active_comps: Array[Node] = [player.melee_w_component, player.ranged_w_component, player.shield_component]
	for comp in active_comps:
		if comp and comp.visible:
			var dup: Node = comp.duplicate(0)
			_strip_physics_and_scripts(dup)
			comp_container.add_child(dup)
			
	var tween_c: Tween = create_tween().bind_node(active_illusion)
	tween_c.tween_property(comp_container, "scale", Vector2(0.3, 0.3), teleport_time)

# Strips scripts and physics properties from a node to convert it into a visual-only prop.
func _strip_physics_and_scripts(node: Node) -> void:
	node.set_script(null)
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.queue_free()
	elif node is Area2D:
		node.monitoring = false
		node.monitorable = false
	elif node is PhysicsBody2D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_strip_physics_and_scripts(child)

# Draws the ability range boundary and the active crush visual effect.
func _draw() -> void:
	if player.name == str(multiplayer.get_unique_id()):
		draw_arc(Vector2.ZERO, max_range, 0.0, TAU, 300, Color(1.0, 0.0, 0.086, 0.71), 1.0)
	
	if current_radius > 0.0:
		draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.2, 0.2, 0.4))
