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
		get_tree().change_scene_to_file("res://main_menu/lobby/lobby.tscn")
	elif number_of_players > 2:
		#only the piece holder should call this method
		var grandparent = get_parent().get_parent()
		board.remove_player(piece_id)
		
		grandparent.remove_child(grandparent.get_node(str(piece_id)))
		#Global.window.addToDB("gameState/notification", JSON.stringify({"state" : "lost", "loserID" : piece_id}))
	super(board)
