extends UIComponent

@onready var name_label: Label = $"../UI/Name"
@onready var health_bar: ProgressBar = $"../UI/HealthBar"
@onready var info: Label = $"../UI/InfoLabel"

@onready var main_brain: MainBrain = $"../BrainComponents/MainBrain"
@onready var combat_brain: CombatBrain = $"../BrainComponents/CombatBrain"
@onready var fleeing_brain: FleeingBrain = $"../BrainComponents/FleeingBrain"
@onready var ability_brain: AbilityBrain = $"../BrainComponents/AbilityBrain"
@onready var move_comp: Node2D = $"../Components/MovementComponent"

var update_timer: float = 0.0

# Sets the initial name label text based on a truncated version of the entity name.
func _ready() -> void:
	name_label.text = entity.name.substr(0, 8)

# Processes the server-side debug string generation every frame.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		update_timer += delta
		if update_timer >= 0.2: # Only update 5 times a second, not 60+
			show_debug_info()
			update_timer = 0.0

# Compiles internal brain variables into a formatted string on the server and broadcasts it to all clients.
func show_debug_info() -> void:
	# Accesses the split brain components to gather state and behavioral data.
	var debug_text: String = main_brain.state + "    Bold: " + str(snapped(main_brain.boldness_factor, 0.01)) + "  Kind: " + str(snapped(main_brain.kindness_factor, 0.01)) + "  Score: " + str(main_brain.my_score)
	debug_text += "  Give_Up_Chase: " + str(snapped(combat_brain.target_out_of_range_timer, 0.01)) + "  Team: " + str(entity.team_id) + "  Health: " + str(snapped(main_brain.health_scale, 0.01))
	debug_text += "  Reaction_Time: " + str(snapped(main_brain.inp_delay, 0.01)) + "\n" + "  ST: " + str(snapped(move_comp.get("context_dir"), Vector2(0.01, 0.01)))
	debug_text += "  K_Steal_Hits:  " + str(combat_brain.hits_to_kill_to_target) + "  Food_Need:  " + str(ability_brain.min_food_to_spawn_tower - combat_brain.nearby_food_count)
	
	if is_instance_valid(combat_brain.current_target):
		debug_text += "  Target: " + str(combat_brain.current_target.name)
	else:
		debug_text += "  No Target "
		
	if is_instance_valid(fleeing_brain.current_threat):
		debug_text += "  Threat: " + str(fleeing_brain.current_threat.name)
	else:
		debug_text += "  No Threat "
	
	update_info_label_rpc.rpc(debug_text)

# Updates the local info label text with the authoritative string received from the server.
@rpc("authority", "call_local", "unreliable")
func update_info_label_rpc(text: String) -> void:
	info.text = text
	
# Toggles the visibility of identifying UI elements specifically for other players.
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	if is_instance_valid(health_bar):
		health_bar.set("hide_for_others", is_hidden)
