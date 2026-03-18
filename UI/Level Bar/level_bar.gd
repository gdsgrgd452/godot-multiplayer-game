extends ProgressBar

@onready var player: Node = get_parent().get_parent()
@onready var levelling_component: Node = player.get_node("Components").get_node("LevelingComponent")

# Initializes the bar's maximum value based on the synchronized leveling component.
func _ready() -> void:
	value = 0
	if "next_level_points" in levelling_component:
		max_value = levelling_component.next_level_points

# Animates the visual bar to match the server's absolute points value.
func queue_points(new_points: int) -> void:
	if value + new_points >= max_value:
		value = 0
		max_value = levelling_component.next_level_points
		#print("Level bar: " + str(max_value))
		
	var tween: Tween = create_tween()
	tween.tween_property(self, "value", new_points, 0.4).set_trans(Tween.TRANS_QUAD)
