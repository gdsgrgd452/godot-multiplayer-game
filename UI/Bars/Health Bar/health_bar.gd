extends EntityBar

@onready var entity: Node = get_parent()
var health_component: Node = null
var last_health: float = -1.0
var fill_style: StyleBoxFlat
var hide_for_others: bool = false

# Locates the health component, initializes boundaries, and prepares the dynamic color stylebox.
func _ready() -> void:
	if entity.has_node("Components/HealthComponent"):
		health_component = entity.get_node("Components/HealthComponent")
	else:
		health_component = entity

	if "max_health" in health_component:
		max_value = float(health_component.max_health)
	else:
		max_value = 100.0
		
	if has_theme_stylebox_override("fill"):
		fill_style = get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	else:
		fill_style = StyleBoxFlat.new()
		
	add_theme_stylebox_override("fill", fill_style)

# Monitors health changes, triggers tween updates, and interpolates the bar color based on current value.
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
		if hide_for_others:
			if entity.name == str(multiplayer.get_unique_id()): # Only shows for you
				show()
			else:
				hide()
		else:
			show()
		
	if fill_style and max_value > 0.0:
		var health_ratio: float = value / max_value
		var current_color: Color
		
		if health_ratio > 0.5:
			current_color = Color(1.0, 1.0, 0.0).lerp(Color(0.0, 0.702, 0.0, 1.0), (health_ratio - 0.5) * 2.0)
		else:
			current_color = Color(0.675, 0.0, 0.0, 1.0).lerp(Color(1.0, 1.0, 0.0), health_ratio * 2.0)
			
		fill_style.bg_color = current_color
