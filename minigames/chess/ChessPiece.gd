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
func move(board: Board, pos_i : Vector2i, update_to_db : bool = true):
	board.move_piece(pos, pos_i, update_to_db)
	
#update the piece position using a tween, given a tile's GLOBAL position
func update_position_with_tween(tile_pos : Vector2):
	if tween and tween.is_running():
		tween.stop()
		
	tween = create_tween()
	
	tween.tween_property(self, "global_position", tile_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func change_color(color : Color):
	sprite.modulate = color
