extends Node2D

@onready var entity: CharacterBody2D = get_parent()

@onready var name_label: Label = $"../Name"
@onready var health_bar: ProgressBar = $"../HealthBar"

func _ready() -> void:
	name_label.text = entity.name.substr(0, 8)

# Toggles the visibility of identifying UI elements specifically for other players
func toggle_external_ui(is_hidden: bool) -> void:
	name_label.visible = not is_hidden
	health_bar.hide_for_others = is_hidden
	print("Health bar visible: " + str(health_bar.visible))
