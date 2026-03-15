extends CharacterBody2D

const SPEED = 300.0
var input_dir = Vector2.ZERO
var knockback = Vector2.ZERO
var damage: int = 0
var shooting = false

func _ready():
	# Color ourselves green and enemies red
	if name == str(multiplayer.get_unique_id()):
		$Sprite2D.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
	else:
		$Sprite2D.modulate = Color(1, 0, 0)
		$HUD.hide()

func _process(_delta):
	# Only update the text on our own screen
	if name == str(multiplayer.get_unique_id()):
		var pos_text = "Position: " + str(Vector2(int(position.x), int(position.y)))
		var kb_text = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y)))
		var dmg_text = "Damage: " + str(damage)
		var shoot_text = "Shooting: " + str(shooting)
		
		$HUD/StatsLabel.text = pos_text + "\n" + kb_text + "\n" + dmg_text + "\n" + shoot_text
		
			
func _physics_process(delta):
	if name == str(multiplayer.get_unique_id()):
		var x = Input.get_axis("move_left", "move_right")
		var y = Input.get_axis("move_up", "move_down")
		var new_dir = Vector2(x, y)
		
		if new_dir.length() > 0:
			new_dir = new_dir.normalized()
		
		if new_dir != input_dir:
			input_dir = new_dir
			if not multiplayer.is_server():
				rpc_id(1, "receive_input", new_dir)

	if multiplayer.is_server():
		knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)
		velocity = (input_dir * SPEED) + knockback
		move_and_slide()

		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			var normal = collision.get_normal()
			
			velocity = Vector2.ZERO
			knockback = normal * 500 #Update here to use damage or size or something
			
			if collider and collider.has_method("apply_bounce"):
				collider.apply_bounce(-normal * 500)
				
				if collider.is_in_group("food"):
					collider.take_damage(2)
					damage += 2 # Increment damage when we eat!


func apply_bounce(force: Vector2):
	if multiplayer.is_server():
		knockback = force

# Add these new functions at the bottom of player.gd:
func _input(event):
	# Only the local client window detects their own mouse clicks
	if name == str(multiplayer.get_unique_id()):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			# Get the direction from our pawn to the mouse cursor
			var click_pos = get_global_mouse_position()
			var shoot_dir = (click_pos - global_position).normalized()
			shooting = true
			# Tell the server we want to shoot!
			rpc_id(1, "request_shoot", shoot_dir)

@rpc("any_peer", "call_local", "reliable")
func request_shoot(dir: Vector2):
	if multiplayer.is_server():
		# Security check: verify the person sending the RPC is actually this player
		if str(multiplayer.get_remote_sender_id()) == name:
			# Call the spawn function on the Main scene
			get_tree().current_scene.spawn_bullet(global_position, dir, name)

# 3. THIS FUNCTION RUNS ON THE SERVER WHEN A CLIENT PRESSES A KEY
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2):
	if multiplayer.is_server():
		# Security check: Ensure the client is only moving their own node
		if str(multiplayer.get_remote_sender_id()) == name:
			input_dir = dir
