extends Button

var stat_id: String = ""

signal stat_chosen(stat_id: String)

# Initializes the button text and connects the press event
func _ready() -> void:
	text = format_stat_name(stat_id)
	update_button_color()
	pressed.connect(_on_pressed)

# Updates the visual text to match the currently assigned stat_id
func refresh_text() -> void:
	text = format_stat_name(stat_id)
	update_button_color()

func format_stat_name(stat: String) -> String: # Turns reload_speed into Reload Speed
	return " ".join(Array(stat.split("_")).map(func(w): return w.capitalize()))

# Emits the selected stat_id to the listening components
func _on_pressed() -> void:
	stat_chosen.emit(stat_id)

# Updates the button colour 
func update_button_color() -> void:
	var new_style: StyleBoxFlat = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	new_style.bg_color = get_colour_based_on_type(stat_id)
	
	add_theme_stylebox_override("normal", new_style)

# Gets a themed colour based on the category of the stat
func get_colour_based_on_type(stat: String) -> Color:
	match stat:
		"player_speed", "body_damage":
			return Color(0.553, 0.902, 0.196, 0.6)
		"max_health", "regen_speed", "regen_amount":
			return Color(0.184, 0.498, 0.165, 0.6)
		"projectile_damage", "projectile_speed", "reload_speed", "accuracy":
			return Color(0.506, 0.157, 0.941, 0.6)
		"melee_damage", "melee_knockback", "melee_cooldown":
			return Color(0.682, 0.212, 0.059, 0.6)
		"area_damage", "knockback_force", "max_radius", "max_cooldown":
			return Color(0.816, 0.212, 0.604, 0.6)
		"max_cooldown", "max_range":
			return Color(0.792, 0.102, 0.949, 0.6)
		"max_cooldown", "illusion_duration", "illusions_count":
			return Color(0.0, 0.337, 0.0, 0.6)
		_:
			return Color(0.424, 0.396, 0.388, 0.6)
