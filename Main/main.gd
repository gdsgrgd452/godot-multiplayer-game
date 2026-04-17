extends Node2D


var spectate_target: Node2D = null
var respawn_timer: float = 0.0
@onready var spectator_camera: Camera2D = $SpectatorCamera
@onready var respawn_button: Button = $RespawnLayer/RespawnPanel/RespawnButton
@onready var respawn_label: Label = $RespawnLayer/RespawnPanel/RespawnTimerLabel

@onready var main_menu: CanvasLayer = $MainMenu
@onready var game_selection_menu: CanvasLayer = $GameSelectionMenu
@onready var multiplayer_menu: CanvasLayer = $MultiplayerMenu
@onready var how_to_play: CanvasLayer = $HowToPlay

@onready var current_layer: CanvasLayer:
	set(value):
		if current_layer:
			current_layer.hide()
		current_layer = value
		current_layer.show()

var solo_game: bool = true
var hosting: bool = false
var open_port: bool = false

var temp_username: String

@onready var setup_handler: GameSetupHandler = $Handlers/GameSetupHandler
@onready var player_handler: PlayerHandler = $Handlers/PlayerHandler
@onready var leaderboard_handler: LeaderboardHandler = $Handlers/LeaderboardHandler
@onready var multiplayer_handler: MultiplayerHandler = $Handlers/MultiplayerHandler

# Connects buttons and initializes the game boundary
func _ready() -> void:
	current_layer = main_menu
	connect_htp_buttons()
	connect_back_buttons()
	connect_game_buttons()
	$MainMenu/SoloButton.pressed.connect(on_solo_pressed)
	$MainMenu/MultButton.pressed.connect(on_multiplayer_pressed)
	respawn_button.pressed.connect(_on_respawn_pressed)
	$MultiplayerMenu/HostButton.pressed.connect(on_host_pressed)
	$OverlayLayer.hide()

func connect_htp_buttons() -> void:
	$MainMenu/HowToPlayButton.pressed.connect(on_htp_pressed)
	$MultiplayerMenu/HowToPlayButton.pressed.connect(on_htp_pressed)
	$GameSelectionMenu/HowToPlayButton.pressed.connect(on_htp_pressed)

func on_htp_pressed() -> void:
	current_layer = how_to_play

func connect_back_buttons() -> void:
	$GameSelectionMenu/BackButton.pressed.connect(on_back_pressed.bind(main_menu))
	$MultiplayerMenu/BackButton.pressed.connect(on_back_pressed.bind(main_menu))
	$HowToPlay/BackButton.pressed.connect(on_back_pressed.bind(main_menu))

func on_back_pressed(back_to: CanvasLayer) -> void:
	current_layer = back_to

func connect_game_buttons() -> void:
	$GameSelectionMenu/GameModeButtons/AloneButton.pressed.connect(start_game.bind("Alone"))
	$"GameSelectionMenu/GameModeButtons/1BotButton".pressed.connect(start_game.bind("1-Bot"))
	$GameSelectionMenu/GameModeButtons/FFAButton.pressed.connect(start_game.bind("FFA"))
	$"GameSelectionMenu/GameModeButtons/2TeamsButton".pressed.connect(start_game.bind("2T"))

func start_game(game_preset: String) -> void:
	if hosting or solo_game:
		multiplayer_handler.host_game()
	else:
		multiplayer_handler.join_game()
	setup_handler.apply_preset_or_custom(game_preset)
	print(current_layer.name)
	current_layer.hide()
	$OverlayLayer.show()

func on_solo_pressed() -> void:
	temp_username = $"MainMenu/UsernameInput".text
	current_layer = game_selection_menu

func on_multiplayer_pressed() -> void:
	temp_username = $"MainMenu/UsernameInput".text
	current_layer = multiplayer_menu

func on_host_pressed() -> void:
	hosting = true
	var op_check: CheckBox = get_node_or_null("MultiplayerMenu/HostButton/OpenPortCheck")
	if op_check and op_check.button_pressed:
		open_port = true
	current_layer = game_selection_menu

# Handles the countdown timer and smoothly pans the spectator camera to the killer.
func _process(delta: float) -> void:
	# Lerp camera to target if it exists and hasn't disconnected/died
	if spectate_target and is_instance_valid(spectate_target) and spectate_target.is_inside_tree():
		spectator_camera.global_position = spectator_camera.global_position.lerp(spectate_target.global_position, delta * 5.0)
		
	# Handle the countdown sequence
	if respawn_timer > 0.0:
		respawn_timer -= delta
		respawn_label.text = "Respawning in: " + str(ceil(respawn_timer)) + "s"
		
		if respawn_timer <= 0.0:
			respawn_label.hide()
			respawn_button.show()

# Records player death data by routing the request to the player handler.
func player_died(player_id: String, player_score: int, killer_id: String) -> void:
	player_handler.player_died(player_id, player_score, killer_id)

# Commands the local client's UI and camera to enter the spectate phase.
@rpc("authority", "call_local", "reliable")
func start_spectating(killer_id: String) -> void:
	$RespawnLayer.show()
	respawn_button.hide()
	respawn_label.show()
	respawn_timer = 4.0
	
	# Swap the active camera to the main scene's spectator camera
	spectator_camera.enabled = true
	spectator_camera.make_current()

	# Attempt to find the killer. If environmental or missing, the camera stays where the player died.
	if killer_id != "":
		var killer_node: Node2D = $SpawnedPlayers.get_node_or_null(killer_id)
		if not killer_node:
			killer_node = $SpawnedNPCs.get_node_or_null(killer_id)
		if not killer_node:
			var npcs_to_spectate: Array = $SpawnedNPCs.get_children()
			if npcs_to_spectate.size() <= 0:
				printerr("No one to specate")
			else:
				killer_node = npcs_to_spectate[0]
		if killer_node:
			spectate_target = killer_node
			# Snap the camera to the killer immediately so it doesn't drag across the entire map
			spectator_camera.global_position = spectate_target.global_position

# Hides the button locally and asks the server for a new body.
func _on_respawn_pressed() -> void:
	spectate_target = null
	respawn_button.hide()
	$RespawnLayer.hide()
	player_handler.request_respawn.rpc_id(1)
