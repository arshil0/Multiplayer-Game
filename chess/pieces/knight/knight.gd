extends ChessPiece


func highlight_possible_moves(board : Board):
	board.highlight(pos, Vector2i(-2, -1), piece_id)
	board.highlight(pos, Vector2i(-2, 1), piece_id)
	board.highlight(pos, Vector2i(2, 1), piece_id)
	board.highlight(pos, Vector2i(2, -1), piece_id)
	
	board.highlight(pos, Vector2i(-1, -2), piece_id)
	board.highlight(pos, Vector2i(1, -2), piece_id)
	board.highlight(pos, Vector2i(1, 2), piece_id)
	board.highlight(pos, Vector2i(-1, 2), piece_id)
