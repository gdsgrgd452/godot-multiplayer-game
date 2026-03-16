extends CharacterBody2D

var player_speed: int = 300

var input_dir: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var max_health: int = 500
var health: int = 500
var body_damage: int = 5

var shooting: bool = false
var reload_speed: float = 0.2
var shot_cooldown: float = reload_speed
var bullet_speed: int = 500
var bullet_damage: int = 10

var player_level: int = 0
var next_level_points: int = 25
var total_points_incl_next_level: int = 25
var points: int = 0

var pending_upgrades: int = 0
var upgradeable_stats: Dictionary = {"max_health": 50, "body_damage": 2, "bullet_damage": 2, "bullet_speed": 50, "reload_speed": -0.01}

func _ready():
	# Color ourselves green and enemies red
	if name == str(multiplayer.get_unique_id()):
		$Sprite2D.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
		
		$HUD/UpgradeUI.hide()
		for button in $HUD/UpgradeUI.get_children():
			button.stat_chosen.connect(_on_stat_chosen)
	else:
		$Sprite2D.modulate = Color(1, 0, 0)
		$HUD.hide()

func _process(_delta):
	if name == str(multiplayer.get_unique_id()): 
		show_debug_info()

#Updates the debug info in the top right
func show_debug_info():
		var max_health_text = "Max Health: " + str(max_health) + "\n"
		var health_text = "Health: " + str(health) + "\n" + "\n"
		var pos_text = "Position: " + str(Vector2(int(position.x), int(position.y))) + "\n" + "\n"
		var kb_text = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y))) + "\n"
		var body_dmg_text = "Body Damage: " + str(body_damage) + "\n" + "\n"
		var bullet_dmg_text = "Bullet Damage: " + str(bullet_damage) + "\n"
		var bullet_speed_text = "Bullet Speed: " + str(bullet_speed) + "\n" + "\n"
		var shoot_text = "Shooting: " + str(shooting) + "\n"
		var cooldown_text = "Cooldown: " + str(snapped(shot_cooldown, 0.01)) + "\n" + "\n"
		var player_level_text = "Level: " + str(player_level) 
		var next_level_points_text = "    Points for next: " + str(total_points_incl_next_level) 
		var points_text = "    Points: " + str(points) 
		
		$HUD/StatsLabel.text = max_health_text + health_text + pos_text + kb_text + body_dmg_text + bullet_dmg_text
		$HUD/StatsLabel.text = $HUD/StatsLabel.text +  bullet_speed_text + shoot_text + cooldown_text 
		
		$HUD/LevelLabel.text = player_level_text + next_level_points_text + points_text
		
func _physics_process(delta):
	if name == str(multiplayer.get_unique_id()):
		move_player()
		hold_to_shoot()

	if multiplayer.is_server():
		handle_knockback(delta)
		handle_collisions()
		
	if multiplayer.is_server() or name == str(multiplayer.get_unique_id()):
		reload(delta)


#For moving the player with WASD
func move_player():
	var x = Input.get_axis("move_left", "move_right")
	var y = Input.get_axis("move_up", "move_down")
	var new_dir = Vector2(x, y)
		
	if new_dir.length() > 0:
		new_dir = new_dir.normalized()
		
	if new_dir != input_dir:
		input_dir = new_dir
		if not multiplayer.is_server():
			rpc_id(1, "receive_input", new_dir)

func hold_to_shoot():
	if Input.is_action_pressed("shoot"):
			shoot()

#Handles knockback after being hit by something
func handle_knockback(delta):
	knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)
	velocity = (input_dir * player_speed) + knockback
	
	move_and_slide()

#For bumping into things
func handle_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		velocity = Vector2.ZERO
		knockback = normal * 500 #Update here to use damage or size or something
		
		if collider and collider.has_method("apply_bounce"):
			collider.apply_bounce(-normal * 500)
			
			if collider.is_in_group("food"):
				do_contact_damage(collider)

#Does damage to the object you hit and also yourself
func do_contact_damage(collider):
	collider.take_damage(body_damage, name)
	health -= 2

#For when something collides into you they call this to knock you back
func apply_bounce(force: Vector2):
	if multiplayer.is_server():
		knockback = force

#For when you are damaged by something
func take_damage(amount: int, attacker_id: String = ""):
	if multiplayer.is_server():
		health -= amount
		
		if health <= 0:
			give_points_on_death(attacker_id)
			queue_free()

# Gives points to the attacker (There should be one unless 2 foods bump into each other)
func give_points_on_death(attacker_id: String):
	if attacker_id != "":
		var attacker = get_tree().current_scene.get_node_or_null("SpawnedPlayers/" + attacker_id)
		if attacker and attacker.has_method("get_points_from_kill"):
			attacker.get_points_from_kill(points)
	else:
		printerr("No attacker id")

# This is called by the server when someone dies
func get_points_from_kill(kill_value: int):
	if multiplayer.is_server():
		points += kill_value # This syncs to clients automatically via your Synchronizer
		
		# Send a direct message to the player who owns this node (name.to_int() is their ID)
		rpc_id(name.to_int(), "animate_points_ui", kill_value)

# NEW: The server triggers this on the specific client (and call_local ensures it works for the host too)
@rpc("authority", "call_local", "reliable")
func animate_points_ui(kill_value: int):
	$HUD/LevelBar.queue_points(kill_value)

func level_up():
	# Only show the UI if this is the local player's screen
	if name == str(multiplayer.get_unique_id()):
		
		# Increase the points required for the next level
		player_level += 1
		next_level_points = next_level_points * 2
		total_points_incl_next_level += next_level_points
	
		pending_upgrades += 1

		for button in $HUD/UpgradeUI.get_children():
			var stat = upgradeable_stats.keys().pick_random()
			print(stat)
			button.stat_id = stat
			button.refresh_text()
			
		$HUD/UpgradeUI.show()

#When a stat upgrade button is clicked
func _on_stat_chosen(chosen_stat: String):
	$HUD/UpgradeUI.hide() # Hide the menu again
	if multiplayer.is_server():
		apply_upgrade(chosen_stat) # Just apply it
	else:
		rpc_id(1, "request_upgrade", chosen_stat) # Ask the server to apply it
	
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(chosen_stat: String):
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == name:
			apply_upgrade(chosen_stat)

# Actually applies the upgrade (Server Side Only)
func apply_upgrade(chosen_stat: String):
	# Security check: Make sure they actually have an upgrade to claim!
	if pending_upgrades <= 0:
		return 
		
	pending_upgrades -= 1
	
	match chosen_stat:
		"health":
			max_health += 10
			health += 10 # Heal to match 
		"bullet_damage":
			bullet_damage += 1
		"bullet_speed":
			bullet_speed += 50
		"body_damage":
			body_damage += 1

	# If they STILL have upgrades waiting, force the UI back open!
	if pending_upgrades > 0:
		rpc_id(name.to_int(), "show_upgrade_ui")

#Decreases the time until you can shoot again
func reload(delta):
	if shot_cooldown > 0:
		shot_cooldown -= delta
	
	shooting = shot_cooldown > (reload_speed - 0.1)

#Spawns bullets after the player triggers the shoot input
func shoot():
	if shot_cooldown > 0:
		return
		
	var click_pos = get_global_mouse_position()
	var shoot_dir = (click_pos - global_position).normalized()
	
	shot_cooldown = reload_speed
	shooting = true
	
	if multiplayer.is_server():
		# If you are server just spawn the bullet
		get_tree().current_scene.get_node("SpawnedBullets").spawn_bullet(global_position, shoot_dir, name, bullet_speed, bullet_damage)
	else:
		# If you are client request to shoot via server
		rpc_id(1, "request_shoot", shoot_dir)


# Uses call_remote since this is only used by client players
@rpc("any_peer", "call_remote", "reliable")
func request_shoot(dir: Vector2):
	if multiplayer.is_server():
		# Verify the person sending the RPC is actually this player
		if str(multiplayer.get_remote_sender_id()) == name:
			# NEW: Server checks its own copy of the cooldown to prevent cheating
			if shot_cooldown <= 0:
				shot_cooldown = reload_speed
				get_tree().current_scene.get_node("SpawnedBullets").spawn_bullet(global_position, dir, name, bullet_speed, bullet_damage)

# To change the input for movement (server side) after a client requests to do so
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2):
	if multiplayer.is_server():
		# Ensures the client is only moving their own node
		if str(multiplayer.get_remote_sender_id()) == name:
			input_dir = dir
