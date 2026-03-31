extends Node2D
class_name SpawningNPCs

const NPC_NAMES: Array[String] = ["Bob", "Jack", "Lily", "Harvey", "Luke", "John", "Sam", "Ruby", "Jack", "Tom", "Mary", "Alf", "Mike", "Zara", "Kael", "Nyx", "Dusk", "Vex", "Oryn", "Thal", "Mira", "Blaze", "Crix", "Lyra", "Gorn", "Skye", "Rune", "Fael", "Zolt", "Wren", "Drax", "Sola", "Kira", "Ox", "Ryker", "Fen", "Talon", "Zed", "Casix", "Ivo", "Brynn", "Ace", "Voren"]

# Periodically spawns NPCs on the server to maintain world population.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		_handle_npc_spawning(delta)

# Checks the current NPC count and instantiates new pawns if below the limit.
func _handle_npc_spawning(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(self) and get_child_count() < owner.max_bots:
		var npc_spawn_range = owner.arena_size/2 - 50
		var spawn_pos: Vector2 = Vector2(randf_range(-npc_spawn_range, npc_spawn_range), randf_range(-npc_spawn_range, npc_spawn_range))
		_spawn_npc(spawn_pos)

# Instantiates the NPC Pawn scene at the provided coordinates.
func _spawn_npc(spawn_pos: Vector2) -> void:
	var npc_scene: PackedScene = load("res://Objects/Dynamic/NPC/npc.tscn")
	var npc_instance: CharacterBody2D = npc_scene.instantiate() as CharacterBody2D
	npc_instance.name = NPC_NAMES.pick_random() + "-" + str(Time.get_ticks_msec()) + "_" + str(randi())
	npc_instance.global_position = spawn_pos
	
	match owner.game_type:
		"FFA":
			npc_instance.team_id = randi_range(10,1000)
		"2_Teams":
			npc_instance.team_id = randi_range(1,2)

	npc_instance.current_class = owner.bot_spawn_classes.pick_random()
	add_child(npc_instance, true)
