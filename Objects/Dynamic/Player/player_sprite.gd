extends Sprite2D

@onready var player: Node = get_parent()

		
@export var pawn_texture: Texture2D
@export var knight_texture: Texture2D
@export var rook_texture: Texture2D
@export var bishop_texture: Texture2D


# Updates the visual texture based on the newly applied class promotion.
func _on_promotion_applied(new_class: String) -> void:
	match new_class:
		"Knight":
			texture = knight_texture
		"Rook":
			texture = rook_texture
		"Bishop":
			texture = bishop_texture
		_:
			texture = pawn_texture
