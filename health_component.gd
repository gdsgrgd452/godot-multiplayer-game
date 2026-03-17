extends Node

signal died(attacker_id: String)

@export var max_health: int = 500
var health: int = 500

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
