extends DynamicEntity
class_name NPC

@onready var main_brain: MainBrain = $BrainComponents/MainBrain

var team_id: int = -1:
	set(value):
		team_id = value
		if is_node_ready():
			apply_team_color()
		else:
			get_tree().create_timer(0.5).timeout.connect(apply_team_color)

# Initializes the NPC, sets the starting class configuration, and connects death signals.
func _ready() -> void:
	add_to_group("npc")
	collision_layer = LAYER_NPC_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_NPC_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	if not has_node("MultiplayerSynchronizer"):
		printerr("NPC ", multiplayer.get_unique_id(), " missing Synchronizer on ", name)
		
	if is_node_ready():
		apply_team_color()
		
	health_component.died.connect(_on_npc_died)

# Force initialization of weapons, sprite and abilities based on the default class.
func force_promotion_refresh() -> void:
	if is_instance_valid(promotion_component):
		promotion_component.change_weapon(current_class)
		promotion_component.apply_promotion_stats(current_class)
	if is_instance_valid(sprite_component):
		sprite_component._on_promotion_applied(current_class)

# Evaluates the team_id against the local player to apply a green or red modulate
func apply_team_color() -> void:
	var sprite: Sprite2D = get_node_or_null("SpriteComponent") as Sprite2D
	if not sprite:
		printerr("No sprite")
		return
		
	var local_id: String = str(multiplayer.get_unique_id())
	var players_container: Node = get_tree().current_scene.get_node_or_null("SpawnedPlayers")
	
	if not is_instance_valid(players_container):
		printerr("No players")
		return
		
	var local_player: Node2D = players_container.get_node_or_null(local_id) as Node2D
	
	# If the local player hasn't spawned yet, wait and try again shortly
	if not is_instance_valid(local_player):
		get_tree().create_timer(0.5).timeout.connect(apply_team_color)
		printerr("No local player")
		return
	
	if "team_id" in local_player:
		if self.team_id == local_player.get("team_id"):
			sprite.modulate = Color(0.0, 1.0, 0.0) # Green for teammate
		else:
			sprite.modulate = Color(1.0, 0.0, 0.0) # Red for enemy

# Manages server-side physics and movement for the NPC entity.
func _physics_process(delta: float) -> void:
	kill_if_outside_bounds()
	
	if is_queued_for_deletion():
		return
		
	decrease_knockback(delta)
	var move_velocity: Vector2 = movement_component.get_movement_velocity(delta)
	velocity = move_velocity + knockback
	move_and_slide()
	handle_collisions()

# Grants points to the attacker and removes the NPC from the scene tree.
func _on_npc_died(attacker_id: String) -> void:
	set_process(false)
	KillingUtils.route_kill_credits_and_points(get_tree().current_scene, attacker_id, leveling_component.total_score + kill_value, name)
	manager_component.cleanup_all_abilities() # Triggers the component manager to remove lingering ability visuals
	process_mode = Node.PROCESS_MODE_DISABLED# Disable collisions and processing so the dead body doesn't interact with the world
	hide()
	queue_free()
