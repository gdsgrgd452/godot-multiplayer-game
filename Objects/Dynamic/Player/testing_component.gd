extends Node
class_name TestingComponent

@export var commands_enabled: bool = true

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

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
	
	print(cmd)
	
	match cmd:
		"//spawn":
			_handle_spawn(args)
		"//promote":
			_handle_promote(args)
		"//points":
			_handle_points(args)
		"//team":
			_handle_team(args)

# //spawn food 0,0 Circle

# Instantiates a food entity at specific coordinates with a defined shape type.
func _handle_spawn(args: PackedStringArray) -> void:
	if args.size() < 4 or args[1] != "food":
		return
		
	var pos_data: PackedStringArray = args[2].split(",")
	if pos_data.size() < 2:
		return
		
	var spawn_pos: Vector2 = Vector2(float(pos_data[0]), float(pos_data[1]))
	var shape: String = args[3].replace('"', "")
	
	var food_container: Node = get_tree().current_scene.get_node_or_null("SpawnedFood")
	if is_instance_valid(food_container):
		var food_scene: PackedScene = load("res://Objects/Static/Food/food.tscn")
		var food_instance: CharacterBody2D = food_scene.instantiate() as CharacterBody2D
		food_instance.global_position = spawn_pos
		food_instance.shape_type = shape
		food_container.add_child(food_instance, true)

# //promote Knight

# Forces a class promotion on the parent player through the promotion component.
func _handle_promote(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	var promo_comp: Node = player.get_node_or_null("Components/PromotionComponent")
	if is_instance_valid(promo_comp):
		promo_comp.request_promotion(args[1])

# //points 100

# Grants a specified amount of points to the parent player's leveling component.
func _handle_points(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	var level_comp: Node = player.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp):
		level_comp.get_points(int(args[1]))

# //team 1

# Updates the player's team ID and triggers the corresponding visual color update.
func _handle_team(args: PackedStringArray) -> void:
	if args.size() < 2:
		return
		
	player.team_id = int(args[1])
	if player.has_method("apply_team_color"):
		player.apply_team_color()
