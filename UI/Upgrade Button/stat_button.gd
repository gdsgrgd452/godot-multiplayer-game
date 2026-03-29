extends Button

var stat_id: String = ""
var curr_colour: Color
@onready var stat_bar: EntityBar = $StatProgressBar

signal stat_chosen(stat_id: String)

# Initializes the button text and connects the press event
func _ready() -> void:
	text = format_stat_name(stat_id)
	update_button_color()
	pressed.connect(_on_pressed)
	if not stat_bar:
		printerr("No bar" + str(name))
	stat_bar.anchor_left = 0

# Updates the visual text to match the currently assigned stat_id
func refresh_text() -> void:
	text = format_stat_name(stat_id)
	update_button_color()
	

func format_stat_name(stat: String) -> String: # Turns reload_speed into Reload Speed
	return " ".join(Array(stat.split("_")).map(func(w): return w.capitalize()))

# Emits the selected stat_id to the listening components
func _on_pressed() -> void:
	stat_chosen.emit(stat_id)

# Updates the button colour 
func update_button_color() -> void:
	var new_style: StyleBoxFlat = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	curr_colour = ColourUtils.get_colour_based_on_type(stat_id.split(" ")[0])
	new_style.bg_color = curr_colour
	
	add_theme_stylebox_override("normal", new_style)

# Updates the progress bar
func update_progress_bar(progress: float) -> void:
	stat_bar.value = progress
	var style_box = stat_bar.get_theme_stylebox("fill").duplicate()
	
	style_box.bg_color = curr_colour
	stat_bar.add_theme_stylebox_override("fill", style_box)
