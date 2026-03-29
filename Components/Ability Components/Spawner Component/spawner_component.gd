extends Node2D
class_name SpawnerComponent

@export var max_cooldown: float = 15.0
var current_cooldown: float = 0.0
@export var max_spawns: int = 2
var current_spawns: int = 0

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

var active_towers: Array[Node2D] = []

func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta
		current_spawns = active_towers.size()

@rpc("any_peer", "call_local", "reliable")
func request_spawn(spawn_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	_cleanup_dead_towers()
	
	if current_cooldown <= 0.0 and active_towers.size() < max_spawns:
		var tower_manager: Node = get_tree().current_scene.get_node_or_null("SpawnedTowers")
		
		if tower_manager and tower_manager.has_method("spawn_tower"):
			current_cooldown = max_cooldown
			
			var ui_comp: Node = entity.get_node_or_null("UIComponent")
			if ui_comp and entity.is_in_group("player"):
				ui_comp.display_message.rpc_id(entity.name.to_int(), "Spawned a sentry tower!")
			
			var new_tower: Node2D = tower_manager.spawn_tower(spawn_pos, entity.name, entity.team_id)
			if new_tower:
				active_towers.append(new_tower)

# Cleans up the array so players can spawn more if old ones were destroyed
func _cleanup_dead_towers() -> void:
	for i in range(active_towers.size() - 1, -1, -1):
		if not is_instance_valid(active_towers[i]):
			active_towers.remove_at(i)
