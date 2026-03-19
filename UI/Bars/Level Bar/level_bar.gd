extends EntityBar

@onready var player: Node = get_parent().get_parent()
@onready var levelling_component: Node = player.get_node("Components/LevelingComponent")

# Initializes the bar's maximum value based on the synchronized leveling component.
func _ready() -> void:
	value = 0.0
	if "next_level_points" in levelling_component:
		max_value = float(levelling_component.next_level_points)

# Triggers a visual tween sequence to match the server's absolute points value.
func queue_points(new_points: int) -> void:
	var target_max: float = float(levelling_component.next_level_points)
	
	if float(value) + float(new_points) >= target_max:
		value = 0.0
		
	animate_value(float(new_points), target_max, 0.4)
