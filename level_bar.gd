extends ProgressBar

@onready var grandparent = get_parent().get_parent()
var target_value: float = 0.0

func _ready():
	if "next_level_points" in grandparent:
		max_value = grandparent.next_level_points
	else:
		max_value = 25 # Default

	value = 0
	target_value = value

# Call this when the player gains points
func queue_points(points_change: int) -> void:
	target_value += points_change
	animate_bar()

func animate_bar():
	# Create a new tween for smooth animation
	var tween = create_tween()
	
	# Animate our 'value' to the 'target_value' over 0.4 seconds
	# Tween.TRANS_QUAD makes it start fast and slow down smoothly
	tween.tween_property(self, "value", target_value, 0.4).set_trans(Tween.TRANS_QUAD)
	
	# When the animation finishes, check for level up
	tween.tween_callback(check_level_up)

func check_level_up():
	if value >= max_value:
		print("Level Up!")
		
		var rollover_points = target_value - max_value 
		
		grandparent.level_up()
		reset_bar(rollover_points)

func reset_bar(rollover: float):
	if "next_level_points" in grandparent:
		max_value = grandparent.next_level_points
	
	# Reset visually
	value = 0
	target_value = rollover
	
	# Animate rollover points
	if target_value > 0:
		animate_bar()
