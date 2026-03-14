extends CharacterBody2D

const SPEED = 300.0
var input_dir = Vector2.ZERO
var knockback = Vector2.ZERO
var damage: int = 0

func _ready():
	# Color ourselves green and enemies red
	if name == str(multiplayer.get_unique_id()):
		$Sprite2D.modulate = Color(0, 0, 1)
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
		
		$HUD/StatsLabel.text = pos_text + "\n" + kb_text + "\n" + dmg_text
		
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

# 3. THIS FUNCTION RUNS ON THE SERVER WHEN A CLIENT PRESSES A KEY
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2):
	if multiplayer.is_server():
		# Security check: Ensure the client is only moving their own node
		if str(multiplayer.get_remote_sender_id()) == name:
			input_dir = dir
