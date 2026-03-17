extends ProgressBar

@onready var grandparent: Node = get_parent().get_parent()
var target_value: float = 0.0

# Sets up the starting maximum value of the progress bar
func _ready() -> void:
	if "next_level_points" in grandparent:
		max_value = grandparent.next_level_points
	else:
		max_value = 25 # Default

	value = 0
	target_value = value

# Call this when the player gains points to begin filling the bar
func queue_points(points_change: int) -> void:
	target_value += points_change
	animate_bar()

# Creates a smooth visual fill effect for the bar
func animate_bar() -> void:
	var tween: Tween = create_tween()
	# Tween.TRANS_QUAD makes it start fast and slow down smoothly
	tween.tween_property(self, "value", target_value, 0.4).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(check_level_up)

# Checks if the visual bar has filled past its limit
func check_level_up() -> void:
	if value >= max_value:
		print("Level Up!")
		
		# Calculates how far past the goal the bar went
		var rollover_points: float = target_value - max_value 
		
		grandparent.level_up()
		reset_bar(rollover_points)

# Prepares the bar for the next level and carries over extra points
func reset_bar(rollover: float) -> void:
	max_value = max_value * 2 #This should stay updated with the level function
	print("Set to: " + str(max_value))
	
	# Reset visually
	value = 0
	target_value = rollover
	
	# Animate rollover points
	if target_value > 0:
		animate_bar()
