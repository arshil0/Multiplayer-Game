extends ChessPiece

#used to check if you can move twice
@onready var moved := false
@onready var direction : Vector2

func highlight_possible_moves(board : Board):
	var empty_ahead = board.highlight(pos, Vector2i(direction), piece_id, false)
	if !moved and empty_ahead:
		board.highlight(pos, Vector2i(direction) * 2, piece_id, false)
		
	if direction.x == 0:
		board.highlight_only_attack(pos, Vector2i(direction + Vector2(1, 0)), piece_id)
		board.highlight_only_attack(pos, Vector2i(direction + Vector2(-1, 0)), piece_id)
	else:
		board.highlight_only_attack(pos, Vector2i(direction + Vector2(0, 1)), piece_id)
		board.highlight_only_attack(pos, Vector2i(direction + Vector2(0, -1)), piece_id)
	
func move(board : Board, pos_i : Vector2i):
	super(board, pos_i)
	moved = true
	promote(board)
	
func promote(board : Board):
	if direction == Vector2.UP and pos.y == 0:
		board.add_piece(piece_id, PIECE_TYPES.QUEEN, pos)
	elif direction == Vector2.LEFT and pos.x == 0:
		board.add_piece(piece_id, PIECE_TYPES.QUEEN, pos)
	elif direction == Vector2.DOWN and pos.y == board.rows - 1:
		board.add_piece(piece_id, PIECE_TYPES.QUEEN, pos)
	elif direction == Vector2.RIGHT and pos.x == board.columns - 1:
		board.add_piece(piece_id, PIECE_TYPES.QUEEN, pos)
		
