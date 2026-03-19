class_name EntityBar
extends ProgressBar

var bar_tween: Tween

# Smoothly interpolates the bar's current value to the newly provided target.
func animate_value(target_value: float, target_max: float, duration: float) -> void:
	max_value = target_max
	
	if bar_tween and bar_tween.is_running():
		bar_tween.kill()
		
	bar_tween = create_tween()
	bar_tween.tween_property(self, "value", target_value, duration).set_trans(Tween.TRANS_QUAD)
