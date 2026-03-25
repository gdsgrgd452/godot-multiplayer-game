extends Node2D
class_name SpawningNPCs

@onready var npc_spawn_range: int = owner.arena_size/2 - 50

# Periodically spawns NPCs on the server to maintain world population.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		_handle_npc_spawning(delta)

# Checks the current NPC count and instantiates new pawns if below the limit.
func _handle_npc_spawning(_delta: float) -> void:
	if not multiplayer.is_server():
		return
		
	if is_instance_valid(self) and get_child_count() < owner.max_bots:
		var spawn_pos: Vector2 = Vector2(randf_range(-npc_spawn_range, npc_spawn_range), randf_range(-npc_spawn_range, npc_spawn_range))
		_spawn_npc(spawn_pos)

# Instantiates the NPC Pawn scene at the provided coordinates.
func _spawn_npc(spawn_pos: Vector2) -> void:
	var npc_scene: PackedScene = load("res://Objects/Dynamic/AI/npc.tscn")
	var npc_instance: CharacterBody2D = npc_scene.instantiate() as CharacterBody2D
	npc_instance.name = "AI_" + str(Time.get_ticks_msec()) + "_" + str(randi())
	npc_instance.global_position = spawn_pos
	npc_instance.team_id = randi_range(10,1000)
	npc_instance.current_class = ["Pawn", "Pawn_I"].pick_random()
	add_child(npc_instance, true)
	print("Spawned npc")
