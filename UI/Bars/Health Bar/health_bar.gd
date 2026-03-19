extends EntityBar

@onready var parent: Node = get_parent()
var health_component: Node = null
var last_health: float = -1.0

# Locates the health component and initializes the bar's maximum boundary.
func _ready() -> void:
	if parent.has_node("Components/HealthComponent"):
		health_component = parent.get_node("Components/HealthComponent")
	else:
		health_component = parent

	if "max_health" in health_component:
		max_value = float(health_component.max_health)
	else:
		max_value = 100.0

# Monitors the component for health changes and triggers visual tween updates.
func _process(_delta: float) -> void:
	if health_component == null:
		return
		
	var current_health: float = float(health_component.health)
	var current_max: float = float(health_component.max_health)
	
	if current_health != last_health:
		last_health = current_health
		animate_value(current_health, current_max, 0.2)
		
	if current_health >= current_max:
		hide()
	else:
		show()
	
