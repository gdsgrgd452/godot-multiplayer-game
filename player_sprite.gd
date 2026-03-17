extends Sprite2D

@onready var player: Node = get_parent()
@export var texture_path: String = "res://chess-pieces/white-pawn.png":
	set(value):
		texture_path = value
		_update_texture()
		
var pawn_texture = "res://chess-pieces/white-pawn.png"
var knight_texture = "res://chess-pieces/white-knight.png"
var bishop_texture = "res://chess-pieces/white-bishop.png"
var rook_texture = "res://chess-pieces/white-rook.png"

func _ready():
	# Initial application
	_update_texture()

func _update_texture():
	if texture_path != "":
		# load() is thread-safe for resources already in memory
		texture = load(texture_path)

func change_outfit(new_path: String):
	if is_multiplayer_authority():
		texture_path = new_path

# Routes the clients promotion choice to the server
@rpc("any_peer", "call_remote", "reliable")
func request_promotion(chosen_type: String) -> void:
	if multiplayer.is_server():
		if str(multiplayer.get_remote_sender_id()) == player.name:
			apply_promotion(chosen_type)

# Actually applies the upgrade stats (Server Side Only)
func apply_promotion(chosen_type: String) -> void:
	match chosen_type:
		"Knight":
			change_outfit(knight_texture)
		"Bishop":
			change_outfit(bishop_texture)
		"Rook":
			change_outfit(rook_texture)

	print("Should have promoted to: " + chosen_type)
			
	player.promotion_aquired(chosen_type)
