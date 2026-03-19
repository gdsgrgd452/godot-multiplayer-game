extends Node

signal died(attacker_id: String)

@export var max_health: int = 500
var health: int = 500
@export var regen_amount: int = 2
@export var regen_speed: float = 10.0
var regen_cooldown: float = regen_speed

@onready var object: CharacterBody2D = get_parent().get_parent()
var health_bar: ProgressBar 

# Sets initial health to max health.
func _ready() -> void:
	health_bar = object.get_node("HealthBar")
	if not health_bar:
		printerr("No health bar")

# Deducts health and emits death signal if empty.
func take_damage(amount: int, attacker_id: String = "") -> void:
	if multiplayer.is_server():
		health -= amount
		if health <= 0:
			died.emit(attacker_id)

# Restores health up to the maximum limit.
func heal(amount: int) -> void:
	if multiplayer.is_server():
		health += amount
		if health >= max_health:
			health = max_health

# Handles passive health regeneration exclusively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and health < max_health:
		regen_cooldown -= delta
		if regen_cooldown <= 0.0:
			regen_cooldown = regen_speed
			heal(regen_amount)
