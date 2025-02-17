extends ChessPiece


func highlight_possible_moves(board : Board):
	board.highlight(pos, Vector2i(-1, -1), piece_id)
	board.highlight(pos, Vector2i(1, -1), piece_id)
	board.highlight(pos, Vector2i(-1, 1), piece_id)
	board.highlight(pos, Vector2i(1, 1), piece_id)
	
	board.highlight(pos, Vector2i(0, -1), piece_id)
	board.highlight(pos, Vector2i(1, 0), piece_id)
	board.highlight(pos, Vector2i(0, 1), piece_id)
	board.highlight(pos, Vector2i(-1, 0), piece_id)

func remove(board : Board):
	var all_pieces_by_this_id = get_parent().get_children()
	for piece in all_pieces_by_this_id:
		if piece != self:
			piece.remove(board)
			
	#if this is 2, this means that only 1 player will remain, they win!
	var number_of_players = get_parent().get_parent().get_child_count()
	
	if number_of_players == 2:
		pass
		#do something
	super(board)
