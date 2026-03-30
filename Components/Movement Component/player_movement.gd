extends Node2D

@export var move_speed: int = 150
@export var acceleration: float = 1200.0
@export var friction: float = 800.0

var input_dir: Vector2 = Vector2.ZERO
var movement_blocked: bool = false
var current_velocity: Vector2 = Vector2.ZERO

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

# Updates the intended movement direction based on server-validated client input.
func receive_input(dir: Vector2) -> void:
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == entity.name:
			input_dir = dir

# Calculates the final velocity for the player by interpolating the current vector toward the input target.
func get_movement_velocity(delta: float) -> Vector2:
	if movement_blocked:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		return current_velocity
		
	var target_velocity: Vector2 = input_dir * float(move_speed)
	
	if input_dir.length() > 0.0:
		current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		
	return current_velocity

# Sets the movement direction and rotates the visual orientation node.
func set_movement_direction(dir: Vector2) -> void:
	if movement_blocked:
		return
	
	input_dir = dir.normalized()
