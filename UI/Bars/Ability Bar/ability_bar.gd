extends EntityBar

@onready var player: Node = get_parent()
var last_cooldown: float = 0.0

# Hides the progress bar initially.
func _ready() -> void:
	value = 0.0
	hide()

# Detects a new cooldown cycle and initiates a continuous tween down to zero.
func _process(_delta: float) -> void:
	var ability_comp: Node = player.first_ability_component
	
	if ability_comp == null or player.current_first_ability == "None":
		hide()
		return
		
	var current_cd: float = float(ability_comp.current_cooldown)
	var max_cd: float = float(ability_comp.max_cooldown)
	
	if current_cd > 0.0 and current_cd > last_cooldown:
		show()
		value = current_cd
		animate_value(0.0, max_cd, current_cd)
	elif current_cd <= 0.0:
		hide()
		
	last_cooldown = current_cd
