extends Sprite2D

@onready var player: Node = get_parent()

@export var pawn_texture: Texture2D
@export var pawn_i_texture: Texture2D
@export var pawn_ii_texture: Texture2D
@export var mini_rook_texture: Texture2D
@export var knight_texture: Texture2D
@export var shadow_knight_texture: Texture2D
@export var flower_knight_texture: Texture2D
@export var bishop_texture: Texture2D
@export var rook_texture: Texture2D
@export var ottoman_knight_texture: Texture2D
@export var rook_knight_texture: Texture2D
@export var bishop_knight_texture: Texture2D
@export var king_knight_texture: Texture2D
@export var king_texture: Texture2D
@export var queen_texture: Texture2D
@export var sultan_texture: Texture2D
@export var jester_texture: Texture2D
@export var super_queen_texture: Texture2D
@export var holy_queen_texture: Texture2D

# Updates the visual texture based on the newly applied class promotion.
func _on_promotion_applied(new_class: String) -> void:
	texture = get_texture_from_type(new_class)

# Returns the corresponding Texture2D for a given class name.
func get_texture_from_type(class_type: String) -> Texture2D:
	match class_type:
		"Pawn_I":
			return pawn_i_texture
		"Pawn_II":
			return pawn_ii_texture
		"Mini_Rook":
			return mini_rook_texture
		"Knight":
			return knight_texture
		"Shadow_Knight":
			return shadow_knight_texture
		"Flowers_Knight":
			return flower_knight_texture
		"Bishop":
			return bishop_texture
		"Rook":
			return rook_texture
		"Ottoman_Knight":
			return ottoman_knight_texture
		"Rook_Knight":
			return rook_knight_texture
		"Bishop_Knight":
			return bishop_knight_texture
		"King_Knight":
			return king_knight_texture
		"King":
			return king_texture
		"Queen":
			return queen_texture
		"Sultan":
			return sultan_texture
		"Jester":
			return jester_texture
		"Super_Queen":
			return super_queen_texture
		"Holy_Queen":
			return holy_queen_texture
		_:
			return pawn_texture
