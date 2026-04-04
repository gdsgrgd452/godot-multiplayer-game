extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")


func add_player(id: int, start_score: int = 0, node_name: String = "") -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	
	# Uses the authoritative username as the node name for the hierarchy.
	if node_name != "":
		player_instance.name = node_name
	else:
		player_instance.name = str(id)
		
	# Stores the technical ID for RPC routing and authoritative checks.
	player_instance.peer_id = id
	
	var arena_half: float = owner.arena_size / 2.0 - 50.0
	player_instance.position = Vector2(randf_range(-arena_half, arena_half), randf_range(-arena_half, arena_half))
	
	match owner.game_type:
		"FFA":
			player_instance.team_id = 1 if id == 1 else get_child_count() + 1
		"2_Teams":
			player_instance.team_id = 1 if id == 1 else (get_child_count() % 2) + 1
	
	add_child(player_instance, true)
	
	if start_score != 0:
		get_tree().create_timer(1.0).timeout.connect(func() -> void: give_player_points_on_start(player_instance, start_score))

func give_player_points_on_start(player: Node2D, points: int):
	var level_comp: Node2D = player.get_node_or_null("Components/LevelingComponent")
	level_comp.get_points(points)
