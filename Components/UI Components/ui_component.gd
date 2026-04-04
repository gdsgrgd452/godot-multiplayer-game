extends Node2D
class_name UIComponent

@onready var entity: Node2D = get_parent() as Node2D

var active_labels: Dictionary = {}
var label_values: Dictionary = {}
var active_tweens: Dictionary = {}

# Updates numeric indicators and restarts their floating animation relative to the entity.
@rpc("authority", "call_local", "unreliable")
func spawn_floating_number(amount: int, category: String) -> void:
	var color: Color = Color.WHITE
	var prefix: String = ""
	var local_offset: Vector2 = Vector2(-20.0, -40.0)
	var duration: float = 5.0
	
	match category:
		"damage":
			color = Color.RED
			prefix = "-"
		"heal":
			color = Color.GREEN
			prefix = "+"
		"level":
			color = Color.BLUE
			prefix = "LVL +"

	var inv_scale: Vector2 = Vector2.ONE / entity.scale

	if active_labels.has(category) and is_instance_valid(active_labels[category]):
		var label: Label = active_labels[category]
		label_values[category] += amount
		label.text = prefix + str(label_values[category])
		
		if active_tweens.has(category) and active_tweens[category].is_valid():
			active_tweens[category].kill()
			
		label.scale = inv_scale * 1.3
		var scale_tween: Tween = create_tween()
		scale_tween.tween_property(label, "scale", inv_scale, 0.1)
		
		active_tweens[category] = FloatingTextUtils.animate_label(self, label, local_offset, duration, entity.scale)
		return

	label_values[category] = amount
	var new_label: Label = FloatingTextUtils.create_label(prefix + str(amount), color, 20, local_offset, entity.scale)
	new_label.name = entity.name.substr(0, 4) + str(randi_range(0, 10))
	add_child(new_label)
	
	active_labels[category] = new_label
	active_tweens[category] = FloatingTextUtils.animate_label(self, new_label, local_offset, duration, entity.scale)

# Displays animated status messages above the entity with scale-aware positioning.
@rpc("any_peer", "call_local", "reliable")
func display_message(message: String, pos_offset: Vector2 = Vector2(-100.0, -50.0), font_size: int = 20, override_color: Color = Color(0, 0, 0, 0)) -> void:
	var color: Color = override_color if override_color.a > 0.0 else Color.RED
	var message_formatted: String = message
	var duration: float = 1.5
	
	if message.contains("Upgraded"):
		color = ColourUtils.get_colour_based_on_type(message.split(" ")[1])
		color.a = 1.0
		var parts: PackedStringArray = message.split(" ")[1].split("_")
		var stat_name: String = parts[0].capitalize()
		if parts.size() > 1:
			stat_name += " " + parts[1].capitalize()
		message_formatted = "Upgraded: " + stat_name
	elif message.contains("Promoted"):
		color = Color.GREEN
	
	var inv_scale: Vector2 = Vector2.ONE / entity.scale
	var label: Label = FloatingTextUtils.create_label(message_formatted, color, font_size, pos_offset, entity.scale)
	add_child(label)
	
	label.scale = inv_scale * 0.5
	var grow_tween: Tween = create_tween()
	grow_tween.tween_property(label, "scale", inv_scale, 0.2).set_trans(Tween.TRANS_BACK)
	
	FloatingTextUtils.animate_label(self, label, pos_offset, duration, entity.scale)
