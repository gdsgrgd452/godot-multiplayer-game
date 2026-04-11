extends Node2D
class_name SpawningNPCs

@export var npc_scene: PackedScene

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
		var npc_spawn_range: float = owner.arena_size/2 - 50
		var spawn_pos: Vector2 = Vector2(randf_range(-npc_spawn_range, npc_spawn_range), randf_range(-npc_spawn_range, npc_spawn_range))
		spawn_npc(spawn_pos)

# Instantiates the NPC Pawn scene at the provided coordinates.
func spawn_npc(spawn_pos: Vector2, force_class: String = "") -> void:
	var npc_instance: CharacterBody2D = npc_scene.instantiate() as CharacterBody2D
	npc_instance.name = NPC_NAMES.pick_random() + "-" + str(randi_range(1, 999))
	npc_instance.global_position = spawn_pos

	var main_scene: Node = get_tree().current_scene
	var current_game_mode: String = main_scene.get("game_type")

	# Add to tree first so setters and synchronizers behave correctly
	add_child(npc_instance, true)

	match current_game_mode:
		"FFA":
			npc_instance.team_id = randi_range(10, 1000)
		"2_Teams":
			npc_instance.team_id = randi_range(1, 2)
		_:
			npc_instance.team_id = randi_range(1001, 2000)

	if force_class != "":
		npc_instance.current_class = force_class
	elif main_scene.get("bot_spawn_classes"):
		#print("Changing npc class")
		npc_instance.current_class = main_scene.bot_spawn_classes.pick_random()
	
	npc_instance.force_promotion_refresh()

	
