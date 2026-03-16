extends ProgressBar

@onready var parent = get_parent()

func _ready():
	# If the parent has a max_health variable, use it. Otherwise default to 100.
	if "max_health" in parent:
		max_value = parent.max_health
	else:
		max_value = 100

func _process(_delta):
	# Continuously update the bar to match the parent's current health
	if "health" in parent:
		value = parent.health
	if "max_health" in parent:
		max_value = parent.max_health
