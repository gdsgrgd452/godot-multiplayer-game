extends Node2D

@onready var entity: CharacterBody2D = get_parent()

@onready var name_label: Label = $"../Name"
@onready var health_bar: ProgressBar = $"../HealthBar"

@onready var info: Label = $"../InfoLabel"

@onready var npc: Node2D = $"../Components/NPCControllerComponent"
@onready var move_comp = $"../Components/MovementComponent"

func _ready() -> void:
	name_label.text = entity.name.substr(0, 8)

func _process(_delta: float) -> void:
	show_debug_info()

func show_debug_info() -> void:
	info.text = npc.state + "  B:" + str(snapped(npc.boldness_factor,0.01)) + "  K:" + str(snapped(npc.kindness_factor,0.01)) + "  S:" + str(npc.my_score)
	info.text += "  G_C:" + str(snapped(npc.give_up_chase_time,0.01)) + "  T:" + str(entity.team_id) + " H: " + str(snapped(npc.health_scale,0.01))
	info.text += "  RT: " + str(snapped(npc.inp_delay,0.01)) + " ST: " + str(move_comp.context_dir)
	
# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden
	print("Health bar visible: " + str(health_bar.visible))
