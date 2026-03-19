extends Node

signal died(attacker_id: String)

@export var max_health: int = 500
var health: int = 500
var regen_amount: int = 5
var regen_speed: float = 1.0
var regen_cooldown: float = regen_speed

# Sets initial health to max health
func _ready() -> void:
	health = max_health

# Deducts health and emits death signal if empty
func take_damage(amount: int, attacker_id: String = "") -> void:
	if multiplayer.is_server():
		health -= amount
		if health <= 0:
			died.emit(attacker_id)

# Restores health up to the maximum limit
func heal(amount: int) -> void:
	if multiplayer.is_server():
		health += amount
		if health > max_health:
			health = max_health

func _process(delta: float) -> void:
	if get_parent().get_parent().is_hosting and health < max_health:
		regen_cooldown -= delta
		
		if regen_cooldown <= 0.0:
			regen_cooldown = regen_speed
			health += regen_amount
