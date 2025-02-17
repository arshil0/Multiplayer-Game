extends Node2D

class_name ChessPiece

#current position on board
var pos : Vector2i
#who owns the piece, this id will be equal to the players' id
var piece_id : int
#keeps track whether this piece is currently focused on
var focused := false

@onready var sprite = $Sprite2D

enum PIECE_TYPES {
	PAWN,
	BISHOP,
	QUEEN,
	ROOK,
	KING,
	KNIGHT
}

static var color_sprites = {
	"red" : {
		"king" : preload("res://chess/pieces/king/red.png"),
		"queen" : preload("res://chess/pieces/queen/red.png"),
		"rook" : preload("res://chess/pieces/rook/red.png"),
		"bishop" : preload("res://chess/pieces/bishop/red.png"),
		"knight" : preload("res://chess/pieces/knight/red.png"),
		"pawn" : preload("res://chess/pieces/pawn/red.png"),
	},
	"blue": {
		"king" : preload("res://chess/pieces/king/blue.png"),
		"queen" : preload("res://chess/pieces/queen/blue.png"),
		"rook" : preload("res://chess/pieces/rook/blue.png"),
		"bishop" : preload("res://chess/pieces/bishop/blue.png"),
		"knight" : preload("res://chess/pieces/knight/blue.png"),
		"pawn" : preload("res://chess/pieces/pawn/blue.png"),
	}
}


var tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#ABSTRACT FUCTIONS

#given a board object, which contains a matrix, highlight the tiles that this piece can move into
func highlight_possible_moves(board : Board):
	pass
	
#when this piece is eaten, this is called, I am recieving board so when the king is eaten, remove all 
func remove(board : Board):
	var holding_tile = board.get_tile(pos)
	if holding_tile.chess_piece == self:
		holding_tile.chess_piece = null;
	queue_free()
	
#make a move given a vector2i position
func move(board: Board, pos_i : Vector2i):
	board.move_piece(pos, pos_i, true)
	
#update the piece position using a tween, given a tile's GLOBAL position
func update_position_with_tween(tile_pos : Vector2):
	if tween and tween.is_running():
		tween.stop()
		
	tween = create_tween()
	
	tween.tween_property(self, "global_position", tile_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func change_color(color : String, piece_name : String):
	sprite.texture = color_sprites.get(color).get(piece_name.to_lower())
