extends Node2D

signal died(attacker_id: String)

@export var max_health: int = 500
var health: float = 500

var healing: bool = true
@export var regen_amount: float = 2.0
@export var regen_speed: float = 10.0
var regen_cooldown: float = regen_speed

var decaying: bool = false
var decay_amount: int = 1
var decay_speed: float = 10.0
var decay_cooldown: float = decay_speed

@onready var entity: Node = get_parent().get_parent()
@onready var ui_comp: Node = entity.get_node_or_null("UIComponent")
@onready var health_bar: ProgressBar = entity.get_node("UI/HealthBar")

var active_dmg_label: Label = null
var active_heal_label: Label = null
var current_dmg: int = 0
var current_heal: int = 0
var dmg_tween: Tween = null
var heal_tween: Tween = null

var mass_heal_amount: int = 50
var mass_heal_cooldown: float = 5.0
var current_cooldown: float = 0.0
var mass_heal_duration: float = 5.0
var mass_heal_time: float = 0.0

# Sets initial health to max health.
func _ready() -> void:
	if not health_bar:
		printerr("No health bar")

# Handles passive health regeneration/decay exclusively on the server.
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if current_cooldown > 0.0:
		current_cooldown -= delta

	# Handles regeneration only when the object is damaged.
	if healing and health < max_health:
		regen_cooldown -= delta
		if regen_cooldown <= 0.0:
			regen_cooldown = regen_speed
			heal(regen_amount)

	# Handles decay regardless of current health status.
	if decaying and health > 0:
		decay_cooldown -= delta
		if decay_cooldown <= 0.0:
			decay_cooldown = decay_speed
			take_damage(decay_amount, "")

# Restores health up to the maximum limit and triggers floating heal text.
func heal(amount: float) -> void:
	if multiplayer.is_server():
		var actual_heal: float = amount
		if health + amount > max_health: # Handles overflow
			actual_heal = max_health - health
			
		if actual_heal > 0:
			health += actual_heal
			if is_instance_valid(ui_comp):
				ui_comp.spawn_floating_number.rpc(int(actual_heal), "heal")

# Deducts health, emits death signal if empty, and triggers floating damage text.
func take_damage(amount: int, attacker_id: String = "", non_entity_attacker: bool = false) -> void:
	if not multiplayer.is_server():
		return

	# Friendly Fire Check
	var attacker_node = _find_attacker_node(attacker_id)
	if not non_entity_attacker and attacker_node: # The attacker is an entity and it exists
		var attacker_team = attacker_node.get("team_id")
		var my_team = entity.get("team_id")
		
		# If both have valid teams and they match, ignore the damage
		if attacker_team != null and my_team != null:
			if attacker_team == my_team and my_team != -1:
				#print("Friendly fire blocked between " + attacker_id + " and " + entity.name)
				return
	
	health -= amount
	regen_cooldown = maxf(0.1, regen_speed)
	if is_instance_valid(ui_comp):
		ui_comp.spawn_floating_number.rpc(amount, "damage")

	if health <= 0:
		died.emit(attacker_id)

# Helper function to find the attacker node in the world
func _find_attacker_node(id: String) -> Node:
	var scene = get_tree().current_scene
	# Check players first
	var p_container = scene.get_node_or_null("SpawnedPlayers")
	if p_container:
		var p = p_container.get_node_or_null(id)
		if p: return p
		
	# Check NPCs
	var n_container = scene.get_node_or_null("SpawnedNPCs")
	if n_container:
		var n = n_container.get_node_or_null(id)
		if n: return n
		
	return null

# Request a mass heal up ability
@rpc("any_peer", "call_local", "reliable")
func request_mass_heal() -> void:
	if not multiplayer.is_server():
		return
		
	if current_cooldown <= 0.0 and health < max_health:
		# Triggers a message above the player and the ability cooldown bar
		if is_instance_valid(ui_comp) and entity.is_in_group("player"):
			ui_comp.handle_ability_activated(self, "Mass Heal", mass_heal_cooldown)
		current_cooldown = mass_heal_cooldown
		heal(mass_heal_amount)
