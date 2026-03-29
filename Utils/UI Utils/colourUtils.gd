class_name ColourUtils


# Gets a themed colour based on the category of the stat
static func get_colour_based_on_type(stat: String) -> Color:
	match stat:
		"move_speed", "body_damage":
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
