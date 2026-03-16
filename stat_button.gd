extends Button

var stat_id: String = ""
@export var display_text: String = "Upgrade: "

# We will send this signal to the player script when clicked
signal stat_chosen(stat_id: String)

func _ready():
	text = display_text + stat_id
	pressed.connect(_on_pressed)

func refresh_text():
	text = display_text + stat_id

func _on_pressed():
	# Tell whoever is listening (the player) which stat we picked
	stat_chosen.emit(stat_id)
