extends RangedWeaponComponent
class_name FireballShooterComponent

@export var fireball_shooter_audio: AudioStream = preload("res://Sound Effects/fireball.wav")

func _ready() -> void:
	projectile_type = "Fireball"
	
func play_audio() -> void:
	audio_comp.play_weapon_sound(fireball_shooter_audio)
