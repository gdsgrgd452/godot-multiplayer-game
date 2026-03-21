# HUD/info_bar.gd
extends Label

var active_tween: Tween

func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	text = ""

# Receives a string and animates the label. Callable locally or across the network.
@rpc("any_peer", "call_local", "reliable")
func display_message(message: String) -> void:
	
	
	if message.contains("Upgraded"):
		
		var stat_button: Node = get_parent().get_node_or_null("UpgradeUI/StatButton")
		 
		var formatted_stat: String = stat_button.format_stat_name(message) # Converts "projectile_speed" to "Projectile Speed"
		text = formatted_stat
		
		modulate = stat_button.get_colour_based_on_type(message.split(" ")[1])
	else:
		text = message
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# If a message is already showing, stop its fade-out tween so we can cleanly start over.
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	# Instantly appear, hold for 2 seconds, then fade out over 1 second.
	modulate.a = 1.0
	active_tween = create_tween()
	active_tween.tween_interval(2.0) 
	active_tween.tween_property(self, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
