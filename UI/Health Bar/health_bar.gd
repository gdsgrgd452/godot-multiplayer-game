extends ProgressBar

@onready var parent: Node = get_parent()
var target_health_node: Node = null

# Finds the correct node to track health from
func _ready() -> void:
	# Look for the new component. If it doesn't exist, fallback to the parent!
	if parent.has_node("Components/HealthComponent"):
		target_health_node = parent.get_node("Components/HealthComponent")
	else:
		target_health_node = parent

	if "max_health" in target_health_node:
		max_value = target_health_node.max_health
	else:
		max_value = 100

# Continually updates the bar visually to match the entity's health
func _process(_delta: float) -> void:
	if target_health_node and "health" in target_health_node:
		value = target_health_node.health
		max_value = target_health_node.max_health
