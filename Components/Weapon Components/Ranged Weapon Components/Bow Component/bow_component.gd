extends RangedWeaponComponent
class_name BowComponent

func _ready() -> void:
	projectile_type = "Arrow"
	projectile_speed *= 2
