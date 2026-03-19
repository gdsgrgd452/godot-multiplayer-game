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
	match new_class:
		"Pawn_I":
			texture = pawn_i_texture
		"Pawn_II":
			texture = pawn_ii_texture
		"Mini_Rook":
			texture = mini_rook_texture
		"Knight":
			texture = knight_texture
		"Shadow_Knight":
			texture = shadow_knight_texture
		"Flower_Knight":
			texture = flower_knight_texture
		"Bishop":
			texture = bishop_texture
		"Rook":
			texture = rook_texture
		"Ottoman_Knight":
			texture = ottoman_knight_texture
		"Rook_Knight":
			texture = rook_knight_texture
		"Bishop_Knight":
			texture = bishop_knight_texture
		"King_Knight":
			texture = king_knight_texture
		"King":
			texture = king_texture
		"Queen":
			texture = queen_texture
		"Sultan":
			texture = sultan_texture
		"Jester":
			texture = jester_texture
		"Super_Queen":
			texture = super_queen_texture
		"Holy_Queen":
			texture = holy_queen_texture
		_:
			texture = pawn_texture
