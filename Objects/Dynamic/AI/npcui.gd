extends Node2D

@onready var entity: CharacterBody2D = get_parent()

@onready var name_label: Label = $"../Name"
@onready var health_bar: ProgressBar = $"../HealthBar"

@onready var info: Label = $"../InfoLabel"

@onready var ai: Node2D = $"../Components/AIControllerComponent"
@onready var move_comp = $"../Components/MovementComponent"

func _ready() -> void:
	name_label.text = entity.name.substr(0, 8)

func _process(_delta: float) -> void:
	show_debug_info()

func show_debug_info() -> void:
	info.text = ai.state + "  B:" + str(snapped(ai.boldness_factor,0.01)) + "  K:" + str(snapped(ai.kindness_factor,0.01)) + "  S:" + str(ai.my_score)
	info.text += "  G_C:" + str(snapped(ai.give_up_chase_time,0.01)) + "  T:" + str(entity.team_id) + " H: " + str(snapped(ai.health_scale,0.01))
	info.text += "  RT: " + str(snapped(ai.inp_delay,0.01)) + " ST: " + str(move_comp.context_dir)
	
# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden
	print("Health bar visible: " + str(health_bar.visible))
