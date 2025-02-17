extends ChessPiece

func highlight_possible_moves(board : Board):
	board.highlight_repetitive(pos, Vector2i(-1, -1), piece_id)
	board.highlight_repetitive(pos, Vector2i(1, -1), piece_id)
	board.highlight_repetitive(pos, Vector2i(-1, 1), piece_id)
	board.highlight_repetitive(pos, Vector2i(1, 1), piece_id)
