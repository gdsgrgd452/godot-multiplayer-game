class_name ImageUtils

static var sword_image: Texture2D = preload("res://images/Weapons/sword_new.png")
static var spear_image: Texture2D = preload("res://images/Weapons/spear.png")
static var bow_image: Texture2D = preload("res://images/Weapons/bow-slack.png")
static var fireball_shooter_image: Texture2D = preload("res://images/Projectiles/fireball.png")
static var pin_shooter_image: Texture2D = preload("res://images/Projectiles/pinRed.png")
static var null_image: Texture2D = preload("res://images/upgrade.png")


static func get_image_by_component_name(comp_name: String) -> Texture2D:
	var img: Texture2D = null_image
	match comp_name:
		"Sword":
			img = sword_image
		"Spear":
			img = spear_image
		"Bow":
			img = bow_image
		"Fireball_Shooter":
			img = fireball_shooter_image
		"Pin_Shooter":
			img = pin_shooter_image

	return img
