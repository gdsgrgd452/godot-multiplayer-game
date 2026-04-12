extends DynamicEntity
class_name Player

# Synchronizes the cosmetic username and updates the overhead label on all clients.
@export var player_username: String = "Guest":
	set(value):
		player_username = value
		if is_node_ready() and has_node("UI/Name"):
			var name_label: Label = get_node("UI/Name") as Label
			name_label.text = value
var input_needed: bool = false # An input is needed, block everything until then


@export var team_id: int = 0

# Initializes UI, colors, and connects component signals.
func _ready() -> void:
	
	if is_node_ready():
		sprite_component._on_promotion_applied(current_class)
		$UI/Name.text = player_username
	collision_layer = LAYER_NPC_PLAYER_AND_FOOD # Resides on
	collision_mask = LAYER_NPC_PLAYER_AND_FOOD | LAYER_WORLD_BOUNDARIES # Collides with
	
	# Initialises the weapons and class, uses call_deferred to give the MultiplayerSpawner time to sync sub-nodes
	if multiplayer.is_server() or name == str(multiplayer.get_unique_id()):
		promotion_component.request_promotion.rpc_id.call_deferred(1, current_class)
	if name == str(multiplayer.get_unique_id()):
		$SpriteComponent.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		for button: Node in $HUD/UpgradeUI.get_children():
			if button is Button:
				button.stat_chosen.connect(_on_stat_chosen)
		for button: Node in $HUD/PromotionUILabel/PromotionUI.get_children():
			if button is Button:
				button.type_chosen.connect(_on_type_chosen)
	else:
		$SpriteComponent.modulate = Color(1, 0, 0)

func apply_team_color() -> void:
	var sprite: Sprite2D = get_node_or_null("SpriteComponent") as Sprite2D
	if not sprite:
		return
		
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node2D = get_tree().current_scene.find_child(local_id, true, false) as Node2D
	
	if local_player and "team_id" in local_player:
		if self.team_id == local_player.get("team_id"):
			sprite.modulate = Color(0.0, 1.0, 0.0)
		else:
			sprite.modulate = Color(1.0, 0.0, 0.0)


# Processes server-side physics and calls local client input gathering.
func _physics_process(delta: float) -> void:
	if name == str(multiplayer.get_unique_id()):
		if input_needed:
			check_second_input_wof()
			return

		#if not shielding: # TODO Add this back in
		check_player_input()
		check_ranged_input()
		check_melee_input()
		check_first_ability_input()
		check_second_ability_input()
		check_shield_input()
		check_switch_weapon_input()
		
		kill_if_outside_bounds()
	
	if multiplayer.is_server():
		decrease_knockback(delta)
		var move_velocity: Vector2 = movement_component.get_movement_velocity(delta)
		velocity = move_velocity + knockback
		move_and_slide()
		handle_collisions()


# Reads WASD input and transmits the movement direction to the server.
func check_player_input() -> void:
	if movement_component.movement_blocked:
		movement_component.set_movement_direction(Vector2.ZERO)
		return
		
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("move_up", "move_down")
	var new_dir: Vector2 = Vector2(x, y).normalized() if x != 0 or y != 0 else Vector2.ZERO
	
	if new_dir != movement_component.input_dir:
		movement_component.set_movement_direction(new_dir)
		if not multiplayer.is_server():
			movement_component.receive_input.rpc_id(1, new_dir)

# Charges up / Triggers a ranged attack
func check_ranged_input() -> void:
	if not is_instance_valid(ranged_w_component) or weapon_in_hand != WeaponType.Ranged:
		return
	if get_viewport().gui_get_hovered_control() != null: # Prevents clicking a button from triggering this
		return
		
	if Input.is_action_just_pressed("attack"):
		ranged_w_component.request_start_charge.rpc_id(1)
		
	if Input.is_action_just_released("attack"):
		ranged_w_component.request_release_charge.rpc_id(1, get_global_mouse_position())

# Triggers a melee attack
func check_melee_input() -> void:
	if melee_w_component and Input.is_action_pressed("attack") and weapon_in_hand == WeaponType.Melee:
		if get_viewport().gui_get_hovered_control() != null: # Prevents clicking a button from triggering this
			return
		
		var target_pos: Vector2 = get_global_mouse_position()
		melee_w_component.request_melee_attack.rpc_id(1, target_pos)

# Triggers the first ability
func check_first_ability_input() -> void:
	if first_ability_component and Input.is_action_just_pressed("first_ability"):
		match current_first_ability:
			"Magic":
				first_ability_component.request_area_attack.rpc_id(1)
			"Teleport":
				first_ability_component.request_teleport.rpc_id(1, get_global_mouse_position())
			"Illusion":
				first_ability_component.request_scattered_illusions.rpc_id(1)
			"Stealth":
				first_ability_component.request_stealth.rpc_id(1)
			"Spawner":
				first_ability_component.request_spawn.rpc_id(1, get_global_mouse_position())
			"Teleport_Crush":
				first_ability_component.request_teleport_area.rpc_id(1, get_global_mouse_position())
			"WOF":
				first_ability_component.request_wof.rpc_id(1, get_global_mouse_position())
			"Mass_Heal":
				health_component.request_mass_heal.rpc_id(1)

# Gets the second input for the wall of fire
func check_second_input_wof() -> void:
	if first_ability_component and current_first_ability == "WOF" and Input.is_action_just_pressed("first_ability"):
		first_ability_component.request_second_pos.rpc_id(1, get_global_mouse_position())
	elif second_ability_component and current_second_ability == "WOF" and Input.is_action_just_pressed("second_ability"):
		second_ability_component.request_second_pos.rpc_id(1, get_global_mouse_position())

# Triggers the second ability 
func check_second_ability_input() -> void:
	if second_ability_component and Input.is_action_just_pressed("second_ability"):
		match current_second_ability:
			"Magic":
				second_ability_component.request_area_attack.rpc_id(1)
			"Teleport":
				second_ability_component.request_teleport.rpc_id(1, get_global_mouse_position())
			"Illusion":
				second_ability_component.request_scattered_illusions.rpc_id(1)
			"Stealth":
				second_ability_component.request_stealth.rpc_id(1)
			"Spawner":
				second_ability_component.request_spawn.rpc_id(1, get_global_mouse_position())
			"Teleport_Crush":
				second_ability_component.request_teleport_area.rpc_id(1, get_global_mouse_position())
			"WOF":
				second_ability_component.request_wof.rpc_id(1, get_global_mouse_position())
			"Mass_Heal":
				health_component.request_mass_heal.rpc_id(1)

# Evaluates continuous input to request shield activation and deactivation from the server.
func check_shield_input() -> void:
	if shield_component:
		var shield_testing: bool = false
		if not shield_testing:
			if Input.is_action_just_pressed("shield"):
				print("Trying to activate shield")
				shield_component.request_shield_activation.rpc_id(1)
			elif Input.is_action_just_released("shield"):
				shield_component.request_shield_deactivation.rpc_id(1)
		else:
			if Input.is_action_just_pressed("shield"):
				print("Trying to activate shield")
				shield_component.request_shield_activation.rpc_id(1)

# Switches from melee to ranged and back again
func check_switch_weapon_input() -> void:
	if Input.is_action_just_pressed("switch_weapon") and is_instance_valid(melee_w_component) and is_instance_valid(ranged_w_component):
		match weapon_in_hand:
			WeaponType.Melee:
				weapon_in_hand = WeaponType.Ranged
			WeaponType.Ranged:
				weapon_in_hand = WeaponType.Melee



# Awards points to the attacker, disables the player, and triggers the death UI.
func _on_player_died(attacker_id: String) -> void:
	var total_score: int = leveling_component.get("total_score")
	KillingUtils.route_kill_credits_and_points(get_tree().current_scene, attacker_id, total_score, player_username)

	# Triggers the component manager to remove lingering ability visuals
	manager_component.cleanup_all_abilities()
	
	# Calls the main script on the server to record the score before the node is disabled.
	var main_node: Node = get_tree().current_scene
	if multiplayer.is_server() and main_node.has_method("player_died"):
		main_node.player_died(name, total_score, attacker_id)
	
	# Disable collisions and processing so the dead body doesn't interact with the world
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	$HUD.hide()

func _update_points(new_points: int) -> void:
	$HUD/LevelBar.queue_points(new_points)

# Transmits the selected stat upgrade to the server.
func _on_stat_chosen(chosen_stat: String) -> void:
	$HUD/UpgradeUI.hide() 
	if multiplayer.is_server():
		leveling_component.apply_upgrade(chosen_stat)
	else:
		leveling_component.rpc_id(1, "request_upgrade", chosen_stat)

# Transmits the selected class promotion to the server via the promotion component.
func _on_type_chosen(chosen_type: String) -> void:
	$HUD/PromotionUILabel.hide()
	promotion_component.request_promotion.rpc_id(1, chosen_type)

# Defines an RPC for the server to command the local client to update its sprite.
@rpc("any_peer", "call_local", "reliable")
func update_sprite_rpc(choice: String) -> void:
	sprite_component._on_promotion_applied(choice)
