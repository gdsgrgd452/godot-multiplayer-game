extends Node
class_name TestingComponent

@export var commands_enabled: bool = true

@onready var main: Node2D = get_tree().current_scene
@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
var c_s: String = "q"

# Initializes the component and schedules automated initialization commands on the server.
func _ready() -> void:
	if multiplayer.is_server():
		if main.player_levels_at_start != 0:
			get_tree().create_timer(1.0).timeout.connect(_execute_initial_boost)
		if main.player_starts_as != "Pawn":
			get_tree().create_timer(1.5).timeout.connect(_execute_intital_promote)
		
# Grants the player an additional 200 levels by calculating required points and invoking the level handler.
func _execute_initial_boost() -> void:
	var level_comp: LevelingComponent = player.get_node_or_null("Components/LevelingComponent") as LevelingComponent
	if is_instance_valid(level_comp):
		var target_string: String = str(level_comp.entity_level + main.player_levels_at_start)
		_handle_levels(PackedStringArray(["initial_boost", target_string]))

# Promotes the player to the class of choice.
func _execute_intital_promote() -> void:
	_handle_promote(PackedStringArray(["initial_promote", main.player_starts_as]))

# Monitors input to toggle the visibility of the global command console UI.
func _input(event: InputEvent) -> void:
	if player == null or not is_instance_valid(player):
		return
		
	if player.name == str(multiplayer.get_unique_id()) and commands_enabled:
		if event.is_action_pressed("ui_focus_next"): # Default Tab or map a custom key
			var console: CanvasLayer = get_tree().current_scene.get_node_or_null("CommandConsole") as CanvasLayer
			if is_instance_valid(console):
				console.visible = not console.visible
				if console.visible:
					console.get_node("CommandInput").grab_focus()

# Sends a reliable RPC to the server to request command execution.
func send_command(command_text: String) -> void:
	execute_server_command.rpc_id(1, command_text)

# Validates the command system state and parses the incoming string on the server.
@rpc("any_peer", "call_local", "reliable")
func execute_server_command(command_text: String) -> void:
	if not multiplayer.is_server() or not commands_enabled:
		return
		
	var args: PackedStringArray = command_text.split(" ")
	if args.size() == 0:
		return
		
	var cmd: String = args[0].to_lower()
	if cmd.is_empty() or cmd[0] != c_s:
		printerr("Wrong code")
		return
	else:
		cmd[0] = cmd[0].substr(1)
	print(args)
	
	match cmd:
		"/spawn":
			_handle_spawn(args)
		"/promote":
			_handle_promote(args)
		"/points":
			_handle_points(args)
		"/team":
			_handle_team(args)
		"/tp":
			_handle_tp(args)
		"/levels":
			_handle_levels(args)

# 1/spawn food 0,0 Circle
# 1/spawn npc 0,0 Knight
# Instantiates either a food entity or an NPC pawn at specific coordinates with a defined sub-type or class.
func _handle_spawn(args: PackedStringArray) -> void:
	if args.size() < 4:
		return
		
	var pos_data: PackedStringArray = args[2].split(",")
	if pos_data.size() < 2:
		return
		
	var spawn_pos: Vector2 = Vector2(float(pos_data[0]), float(pos_data[1]))
	var sub_type: String = args[3].replace('"', "")
	match args[1].to_lower():
		"food":
			var food_spawner: Node = get_tree().current_scene.get_node_or_null("SpawnedFood")
			if is_instance_valid(food_spawner) and food_spawner.has_method("spawn_food"):
				food_spawner.call("spawn_food", spawn_pos, sub_type)
		"npc":
			var npc_spawner: Node = get_tree().current_scene.get_node_or_null("SpawnedNPCs")
			if is_instance_valid(npc_spawner) and npc_spawner.has_method("spawn_npc"):
				npc_spawner.call("spawn_npc", spawn_pos, sub_type)

# 1/promote Knight
# Forces a class promotion on the parent player through the promotion component.
func _handle_promote(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	var promo_comp: Node = player.get_node_or_null("Components/PromotionComponent")
	if is_instance_valid(promo_comp):
		promo_comp.request_promotion(args[1])

# 1/points 100
# Grants a specified amount of points to the parent player's leveling component.
func _handle_points(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	var level_comp: Node = player.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp):
		level_comp.get_points(int(args[1]))

# 1/levels 10
# Grants enough points to reach the requested level from the current level.
func _handle_levels(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
	
	var level_comp: Node = player.get_node_or_null("Components/LevelingComponent")
	if not is_instance_valid(level_comp):
		return
	
	var target_level: int = int(args[1])
	if target_level <= level_comp.entity_level:
		return
	
	var points_needed: int = 0
	for lvl in range(level_comp.entity_level, target_level):
		points_needed += int(pow(float(lvl), 1.5) * 10.0)
	
	# Subtract points already accumulated towards the next level
	points_needed -= level_comp.points
	
	level_comp.get_points(points_needed)

# 1/team 1
# Updates the player's team ID and triggers the corresponding visual color update.
func _handle_team(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	player.team_id = int(args[1])
	if player.has_method("apply_team_color"):
		player.apply_team_color()

# 1/tp 0,0
# Teleports the player to the position specified
func _handle_tp(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	var pos_data: PackedStringArray = args[1].split(",")
	if pos_data.size() < 2:
		return
	var spawn_pos: Vector2 = Vector2(float(pos_data[0]), float(pos_data[1]))

	player.position = spawn_pos
