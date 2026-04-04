extends Node
class_name FloatingTextUtils

# Creates a new label anchored to the entity that maintains a consistent visual size.
static func create_label(text: String, color: Color, size: int, offset: Vector2, entity_scale: Vector2) -> Label:
	var label: Label = Label.new()
	label.top_level = false
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var inv_scale: Vector2 = Vector2.ONE / entity_scale
	label.scale = inv_scale
	label.position = offset / entity_scale
	return label

# Animates the local position and transparency of a label to create a floating effect.
static func animate_label(parent: Node, label: Label, start_offset: Vector2, duration: float, entity_scale: Vector2) -> Tween:
	var inv_scale: Vector2 = Vector2.ONE / entity_scale
	label.position = start_offset / entity_scale
	label.modulate.a = 1.0
	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	var target_y: float = (start_offset.y - 60.0) / entity_scale.y
	tween.tween_property(label, "position:y", target_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
	return tween
