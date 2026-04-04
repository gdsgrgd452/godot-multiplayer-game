extends Node2D
class_name TeleportCrushComponent

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var ui_comp: Node2D = entity.get_node("UIComponent")
@onready var move_comp: Node2D = entity.get_node("Components/MovementComponent")
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision

@export var max_range: float = 600.0
@export var teleport_time: float = 1.5
@export var tp_crush_cooldown: float = 8.0

@export var area_damage: int = 25
@export var max_radius: float = 300.0
@export var knockback_force: float = 1200.0
@export var attack_duration: float = 0.5

var current_cooldown: float = 0.0
var active_illusion: Node2D = null
var active_tween_sprite: Tween
var active_tween_components: Tween
var active_area_tween: Tween

# Synchronizes the physics shape and visual drawing with the current radius value.
var current_radius: float = 0.0:
	set(value):
		current_radius = value
		queue_redraw()
		if is_node_ready() and hitbox_shape.shape is CircleShape2D:
			var circle_shape: CircleShape2D = hitbox_shape.shape as CircleShape2D
			circle_shape.radius = value


# Duplicates the collision shape and ensures the physical hitbox is initially disabled.
func _ready() -> void:
	if hitbox_shape.shape:
		hitbox_shape.shape = hitbox_shape.shape.duplicate()
	
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_body_entered)
	queue_redraw()

# Reduces the active ability cooldown timer on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Receives the requested teleport destination and triggers the sequence if the cooldown is ready.
@rpc("any_peer", "call_local", "reliable")
func request_teleport_area(target_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0:
		if not AbilityUtils.is_position_within_map(get_tree().current_scene, target_pos):
			if ui_comp and entity.is_in_group("player"):
				ui_comp.display_message.rpc_id(entity.name.to_int(), "Naughty Naughty, Cant teleport outside the arena")
				return
		_perform_teleport_area(target_pos)

# Orchestrates the movement, timing, and the subsequent area attack execution on the server.
func _perform_teleport_area(target_pos: Vector2) -> void:
	var start_pos: Vector2 = entity.global_position
	var direction: Vector2 = start_pos.direction_to(target_pos)
	var distance: float = minf(start_pos.distance_to(target_pos), max_range)
	var final_position: Vector2 = start_pos + (direction * distance)
	
	current_cooldown = tp_crush_cooldown + teleport_time
	move_comp.movement_blocked = true

	# Triggers a message above the player and the ability cooldown bar
	if is_instance_valid(ui_comp) and entity.is_in_group("player"):
		ui_comp.handle_ability_activated(self, "Teleport", tp_crush_cooldown + teleport_time)
	
	trigger_teleport_visuals.rpc(true, final_position)
	await get_tree().create_timer(teleport_time + 0.05).timeout
	
	if not is_instance_valid(entity):
		return
		
	entity.global_position = final_position
	trigger_teleport_visuals.rpc(false, final_position)
	
	_execute_crush_attack()
	
	move_comp.movement_blocked = false

# Teleport V

# Manages the player scaling and illusion spawning across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_teleport_visuals(going_out: bool, target_pos: Vector2 = Vector2.ZERO) -> void:
	var sprite: Sprite2D = entity.get_node("SpriteComponent") as Sprite2D
	var components: Node2D = entity.get_node("Components") as Node2D
	
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

# Spawns a visual duplicate of the player at the destination.
func _spawn_teleport_illusion(spawn_pos: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if is_instance_valid(active_illusion):
		active_illusion.queue_free()

	active_illusion = Node2D.new()
	active_illusion.global_position = spawn_pos
	main_scene.add_child(active_illusion)
	
	var player_sprite: Sprite2D = entity.get_node_or_null("SpriteComponent") as Sprite2D
	if player_sprite:
		var sprite_dup: Sprite2D = player_sprite.duplicate(0) as Sprite2D
		sprite_dup.scale = Vector2(0.1, 0.1)
		AbilityUtils.strip_physics_and_scripts(sprite_dup)
		active_illusion.add_child(sprite_dup)
		var tween: Tween = create_tween().bind_node(active_illusion)
		tween.tween_property(sprite_dup, "scale", Vector2(0.3, 0.3), teleport_time)

# Crush V

# Commands all clients to show the expanding crush circle animation.
@rpc("authority", "call_local", "reliable")
func trigger_visual_crush() -> void:
	if entity.name == str(multiplayer.get_unique_id()):
		show()
		hitbox.show()
		hitbox_shape.show()
		if active_area_tween and active_area_tween.is_valid():
			active_area_tween.kill()
		
		active_area_tween = create_tween()
		current_radius = 0.0
		active_area_tween.tween_property(self, "current_radius", max_radius, attack_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Activates the server-side hitbox and broadcasts the visual expansion to clients.
func _execute_crush_attack() -> void:
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	
	trigger_visual_crush.rpc()
	
	await get_tree().create_timer(attack_duration).timeout
	
	hitbox.monitoring = false
	hitbox_shape.disabled = true
	trigger_visual_finished.rpc()

# Evaluates targets within the area radius to apply damage and knockback.
func _on_body_entered(body: Node2D) -> void:
	if body == entity:
		return

	var dir: Vector2 = global_position.direction_to(body.global_position)
	CandDUtils.knockback_and_damage(body, area_damage, entity.name, dir, knockback_force)

# Finished V

# Hides the component visuals across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_visual_finished() -> void:
	hitbox.hide()
	hitbox_shape.hide()

# Renders the range boundary and the active crush circle.
func _draw() -> void:
	if entity.name == str(multiplayer.get_unique_id()):
		draw_arc(Vector2.ZERO, max_range, 0.0, TAU, 100, Color(1.0, 0.0, 1.0, 0.5), 2.0)
		
	if visible and current_radius > 0.0:
		draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.2, 0.2, 0.4))
