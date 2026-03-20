extends Button

@onready var player: Node = owner
@onready var player_sprite: Node = player.get_node("PlayerSprite")

@onready var icon_rect: TextureRect = $VBoxContainer/TextureRect
@onready var text_label: Label = $VBoxContainer/Label


var type_id: String = "":
	set(value):
		type_id = value
		if is_node_ready() and player_sprite:
			icon_rect.texture = player_sprite.get_texture_from_type(value)
			text_label.text = type_id
			
signal type_chosen(type_id: String)

# Initializes the button text and connects the press event
func _ready() -> void:
	if not player_sprite:
		printerr("No player sprite")
	pressed.connect(_on_pressed)

# Emits the selected type_id to the listening components
func _on_pressed() -> void:
	print("Pressed")
	type_chosen.emit(type_id)
