extends CharacterBody2D

@export var health: int = 100
var knockback = Vector2.ZERO

@export var shape_type: int = 0:
	set(value):
		shape_type = value
		queue_redraw()

func _ready():
	add_to_group("food") # Tag it so the player knows what it's bumping into
	queue_redraw()

# This built-in function draws shapes directly to the screen
func _draw():
	if shape_type == 0:
		draw_circle(Vector2.ZERO, 15, Color.WHITE)
	elif shape_type == 1:
		draw_rect(Rect2(-15, -15, 30, 30), Color.BLACK)
	elif shape_type == 2:
		var points = PackedVector2Array([Vector2(0, -15), Vector2(15, 15), Vector2(-15, 15)])
		draw_polygon(points, PackedColorArray([Color.GREEN_YELLOW]))

func _physics_process(delta):
	if multiplayer.is_server():
		# Friction: slow the food down quickly after it gets bumped
		knockback = knockback.move_toward(Vector2.ZERO, delta * 1000)
		velocity = knockback
		move_and_slide()
		
		# If the food bumps into a wall or other food while sliding, bounce it
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			var normal = collision.get_normal()
			knockback = knockback.bounce(normal)
			
			if collider and collider.has_method("apply_bounce"):
				collider.apply_bounce(-normal * 250)

func apply_bounce(force: Vector2):
	if multiplayer.is_server():
		knockback = force

func take_damage(amount: int):
	if multiplayer.is_server():
		health -= amount
		if health <= 0:
			queue_free()
