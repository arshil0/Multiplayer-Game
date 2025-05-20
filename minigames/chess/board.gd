extends Node2D

class_name Board

var rows = 10
var columns = 10

@onready var Tile = preload("res://minigames/chess/tile.tscn")
@onready var tile_size = 64
@onready var chess_pieces: Node2D = $chess_pieces

var board = []
#keeps track of which tiles are highlighted
var highlighted_tiles = []
#keeps track if a chess piece is focusesd
var focused := false
#the list of player id's
var player_ids = []
#my current id
var id =  Global.id
#the id of the player whos' their turn to make a move
var id_of_current_player : int
#the index of the player who's their turn to make a move, used to pass the move onto the next player
var index_of_current_player : int

var got_data_callback = JavaScriptBridge.create_callback(got_data)
var initialized_board := false

#the chance of which each tile (in each player's side) will contain a piece
var chance_of_adding_piece : float = 0.55
#keeps track of the pieces arrangement, each element is an array [piece_type, index]
var piece_arrangement : Array
var is_host : bool = false
#keep track if you have lost the game, to skip your turn if it happens to be your turn somehow
var lost : bool = false

#MINI-MECHANICS VARIABLES
#the chance to remove a block IN PERCENTAGE
var chance_to_remove_block : int = 0;



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window = Global.window
	window.godot_got_data = got_data_callback

	Global.window.getData()
	

func initialize_board():
	global_position -= Vector2(4 * tile_size, 4 * tile_size)
	for x in range(columns):
		var board_column = []
		for y in range(rows):
			var tile_instance = Tile.instantiate()
			tile_instance.position = Vector2(x * tile_size, y * tile_size)
			add_child(tile_instance)
			board_column.append(tile_instance)
		board.append(board_column)
	board[0][0].board = self
	
		
	
	
func prepare_player_nodes(server_data : Dictionary):
	for id in player_ids:
		var player_node = Node2D.new()
		player_node.name = str(id)
		chess_pieces.add_child(player_node)
	
	if Global.is_host:
		index_of_current_player = randi_range(0, player_ids.size() - 1)
		id_of_current_player = chess_pieces.get_child(index_of_current_player).name.to_int()
	else:
		index_of_current_player = server_data.gameState.index_of_player_to_move.to_int()
		id_of_current_player = chess_pieces.get_child(index_of_current_player).name.to_int()
	

func add_piece(to_player_id : int, piece_type : ChessPiece.PIECE_TYPES, pos_i : Vector2i, direction_of_movement : Vector2 = Vector2.ZERO):
	var piece_name = ChessPiece.PIECE_TYPES.keys()[piece_type].to_lower()
	var piece = load("res://minigames/chess/pieces/" + piece_name + "/" + piece_name + ".tscn").instantiate()
	var player_node = chess_pieces.get_node(str(to_player_id))
	player_node.add_child(piece)
	piece.piece_id = to_player_id
	if to_player_id == player_ids[0]:
		if to_player_id == Global.id:
			Global.color = Color("ff3339")
		piece.change_color(Color("ff3339"))
	elif to_player_id == player_ids[1]:
		if to_player_id == Global.id:
			Global.color = Color.CADET_BLUE + Color(0.15, 0.15, 0)
		piece.change_color(Color.CADET_BLUE)
	elif to_player_id == player_ids[2]:
		if to_player_id == Global.id:
			Global.color = Color.BLUE_VIOLET + Color(0.15, 0.15, 0.15)
		piece.change_color(Color.BLUE_VIOLET)
	elif to_player_id == player_ids[3]:
		if to_player_id == Global.id:
			Global.color = Color.CHARTREUSE
		piece.change_color(Color.CHARTREUSE)
	if piece_type == ChessPiece.PIECE_TYPES.PAWN:
		piece.direction = direction_of_movement
		
	var tile = board[pos_i.x][pos_i.y]
	if tile:
		tile.assign_chess_piece(piece, true)
	
#plays an animation to bring up the tiles at random times
func bring_up_tiles():
	for arr in board:
		for tile in arr:
			tile.appear()
	
#highlights pieces in a repetitive way, so if direction is (1,0) it will repeatidly check tiles on the right
#no need for "attacking", as all repetitive pieces are attacking
func highlight_repetitive(pos_i : Vector2i, direction : Vector2i, piece_id : int):
	var repeat = true
	var new_dir = direction
	while(repeat):
		repeat = highlight(pos_i, new_dir, piece_id, true)
		new_dir += direction
	
func highlight(pos_i : Vector2i, direction : Vector2i = Vector2i.ZERO, piece_id : int = 0, attacking : bool = true) -> bool:
	var coord = pos_i + direction
	if coordinates_inside_board(coord):
		var tile = board[coord.x][coord.y]
		if tile != null and tile.focused_piece == null:
			highlighted_tiles.append(tile)
			return tile.highlight_weak(piece_id, attacking)
	return false
	
func highlight_only_attack(pos_i : Vector2i, direction : Vector2i = Vector2i.ZERO, piece_id : int = 0):
	var coord = pos_i + direction
	if coordinates_inside_board(coord):
		var tile = board[coord.x][coord.y]
		if tile != null and tile.focused_piece == null:
			if tile.chess_piece:
				highlighted_tiles.append(tile)
				return tile.highlight_weak(piece_id, true)
	return false
	
func strengthen_highlights():
	for tile in highlighted_tiles:
		tile.highlight_strong()
	
func unhighlight_tiles():
	for tile in highlighted_tiles:
		tile.unhighlight()
		
	highlighted_tiles = []
	
func coordinates_inside_board(coordinates : Vector2i):
	return coordinates.x >= 0 and coordinates.x < columns and coordinates.y >= 0 and coordinates.y < rows
	
#move the piece
func move_piece(from : Vector2i, to : Vector2i, update_to_db : bool = false):
	#the player made a move, but it's not their turn (they missed the time), so just do nothing
	if(update_to_db and !is_my_turn()):
		return
	get_parent().reset_timer()
	var from_tile = board[from.x][from.y]
	var to_tile = board[to.x][to.y]
	
	var piece = from_tile.chess_piece
	
	from_tile.remove_chess_piece()
	to_tile.assign_chess_piece(piece)
	
	index_of_current_player = (index_of_current_player + 1) % player_ids.size()
	id_of_current_player = chess_pieces.get_child(index_of_current_player).name.to_int()
	
	chance_to_remove_block += 5;
	
	#if I am the mover
	if update_to_db:
		var removing_a_tile := false
		var chance = randi_range(0, 100)
		if chance < chance_to_remove_block:
			var random_row = randi_range(0, rows - 1)
			var random_column = randi_range(0, columns - 1)
			var tile = board[random_column][random_row]
			if tile != null and tile.chess_piece == null:
				removing_a_tile = true
				chance_to_remove_block = 0
				board[random_column][random_row] = null
				tile.fall()
				Global.window.addToDB("gameState", JSON.stringify({"game": "Chess", "state": "move", "sub_state" : "remove_tile", "index_of_player_to_move": str(index_of_current_player), "id_of_mover" : str(id) , "last_move" : {"from_x" : from.x, "from_y" : from.y, "to_x" : to.x, "to_y" : to.y}, "removed_tile_position" : {"x" : random_column, "y" : random_row}}))
		
		if !removing_a_tile:
			Global.window.addToDB("gameState", JSON.stringify({"game": "Chess", "state": "move", "index_of_player_to_move": str(index_of_current_player), "id_of_mover" : str(id) , "last_move" : {"from_x" : from.x, "from_y" : from.y, "to_x" : to.x, "to_y" : to.y}}))

#skips a move (someone didn't make a move and the timer ran out, or it was a lost player's turn)
func skip_move(update_to_db : bool = false):
	get_parent().reset_timer()
	index_of_current_player = (index_of_current_player + 1) % player_ids.size()
	id_of_current_player = chess_pieces.get_child(index_of_current_player).name.to_int()
	
	chance_to_remove_block += 5;
	
	#if I am the mover
	if update_to_db:
		var removing_a_tile := false
		var chance = randi_range(0, 100)
		if chance < chance_to_remove_block:
			var random_row = randi_range(0, rows - 1)
			var random_column = randi_range(0, columns - 1)
			var tile = board[random_column][random_row]
			if tile != null and tile.chess_piece == null:
				removing_a_tile = true
				chance_to_remove_block = 0
				board[random_column][random_row] = null
				tile.fall()
				Global.window.addToDB("gameState", JSON.stringify({"game": "Chess", "state": "skip", "sub_state" : "remove_tile", "index_of_player_to_move": str(index_of_current_player), "id_of_mover" : str(id), "removed_tile_position" : {"x" : random_column, "y" : random_row}}))
		
		if !removing_a_tile:
			Global.window.addToDB("gameState", JSON.stringify({"game": "Chess", "state": "skip", "index_of_player_to_move": str(index_of_current_player), "id_of_mover" : str(id)}))

#checks if it's my turn currently
func is_my_turn() -> bool:
	return id_of_current_player == id
	
#return the tile given a position
func get_tile(pos_i : Vector2i):
	return board[pos_i.x][pos_i.y]

func create_piece_arrangement():
	var number_of_pieces : int = 0
	
	var start = 2
	var finish = columns - 2
	
	while(start < finish):
		number_of_pieces += finish - start + 1
		start += 1
		finish -= 1
		
	for i in range(number_of_pieces):
		var chance = randf()
		
		#about to add piece
		if chance < chance_of_adding_piece:
			if piece_arrangement.size() == 0:
				piece_arrangement.append([ChessPiece.PIECE_TYPES.KING, i])
				
			else:
				var piece_array = ChessPiece.PIECE_TYPES.values()
				piece_array.remove_at(4)
				piece_arrangement.append([piece_array.pick_random(), i])

#uses the "piece_arrangement" variable to put the pieces on the board
func arrange_pieces_on_board(player_id : int, start_position : int, go_by_row : bool, increment : bool, moving_direction : Vector2i):
	var start = 2;
	var finish : int = columns - 2;
	var piece_index = 0
	var index = 0

	#either the x or y coordinate will be this value
	#if "go_by_row == true", then this will be the y value
	#else this will be the x value
	var pos1 = start_position
	while(start < finish):
		for pos2 in range(start, finish):
			var piece_data = piece_arrangement[piece_index]
			if piece_data[1] == index:
				if go_by_row:
					add_piece(player_id, piece_data[0], Vector2i(pos1, pos2), moving_direction)
				else:
					add_piece(player_id, piece_data[0], Vector2i(pos2, pos1), moving_direction)
				piece_index += 1
				if piece_index >= piece_arrangement.size():
					return;
			index += 1
		start += 1
		finish -= 1
		
		if increment:
			pos1 += 1
		else:
			pos1 -= 1
			
#if someone lost, remove them from the game (so it can't be their turn)
func remove_player(loser_id : int):
	var upcoming_player_turn_id = chess_pieces.get_child((index_of_current_player + 1) % player_ids.size()).name.to_int()
	player_ids.remove_at(player_ids.find(loser_id))
	print("Currently it will be the turn of player")
	print(upcoming_player_turn_id)
	print("This player lost")
	print(loser_id)
	print("This is my id")
	print(Global.id)
	#if I lost and it became my turn, skip it
	if loser_id == Global.id: 
		print("I lost")
		if upcoming_player_turn_id == Global.id:
			skip_move(true)
			print("skipping turn")
	
#JAVASCRIPT CODE
func got_data(args):
	var data = args[0]
	data = JSON.parse_string(data)
	if(!data.has("lobby_id")):
		data = data[str(Global.lobby_id)]
	
	if Global.got_data(data) == "left":
		get_node("chess_pieces").get_node(str(data.gameState.leaverID)).get_node("King").remove(self)
	
	if !initialized_board:
		for playerID in data.players.keys():
			print(playerID)
			player_ids.append(playerID.to_int())
			
		initialized_board = true
		
		
		#probably keep track of a bool "initialized" and call all of this inside the got_data callback
		#and then everytime you recieve new data, make the corresponding move for each player
		initialize_board()
		prepare_player_nodes(data)
		
		#this will start the game for other clients
		if Global.is_host:
			is_host = true
			create_piece_arrangement()
			Global.window.addToDB("gameState", JSON.stringify({"game": "Chess", "state": "initialized", "index_of_player_to_move": str(index_of_current_player), "piece_arrangement": piece_arrangement}))
		else:
			piece_arrangement = data.gameState.piece_arrangement
		
		for i in range(player_ids.size()):
			if i > 3:
				break;
				
			var player_id = player_ids[i];
				
			#to have a symmetrical (NOT PARALLEL) set of pieces on each side, I will go from start to finish on i = 0
			#and finish to start on i = 1, and so on.
			
			var index = 0;
			var piece_index = 0;
			#setting pieces for player i, also initialize the piece arangement
			#initializing from ABOVE!
			if i == 0:
				arrange_pieces_on_board(player_id, 0, false, true, Vector2i.DOWN)
			#from below
			elif i == 1:
				arrange_pieces_on_board(player_id, rows - 1, false, false, Vector2i.UP)
			#from left
			elif i == 2:
				arrange_pieces_on_board(player_id, 0, true, true, Vector2i.RIGHT)
			#from right
			elif i == 3:
				arrange_pieces_on_board(player_id, columns - 1, true, false, Vector2i.LEFT)
		
		bring_up_tiles()
		
	#someone made a move, or something happened in the game
	else:
		var gameState = data.gameState
		if gameState.state == "move":
			get_parent().reset_timer()
			if gameState.id_of_mover.to_int() == id:
				return
			var last_move = gameState.last_move
			var from = Vector2i(last_move.from_x, last_move.from_y)
			var to = Vector2i(last_move.to_x, last_move.to_y)
			
			var from_tile = board[from.x][from.y]
			
			if from_tile and from_tile.chess_piece:
				from_tile.chess_piece.move(self, to, false)
		elif gameState.state == "skip":
			get_parent().reset_timer()
			if gameState.id_of_mover.to_int() == id:
				return
			skip_move(false)

		
		if gameState.has("sub_state"):
			if gameState.sub_state == "remove_tile":
				var removed_position = gameState.removed_tile_position;
				var tile = board[removed_position.x][removed_position.y]
				if tile != null and tile.chess_piece == null:
					chance_to_remove_block = 0;
					board[removed_position.x][removed_position.y] = null
					tile.fall()
					

		

#regular chess board
#add_piece(player1ID, ChessPiece.PIECE_TYPES.ROOK, Vector2i(0, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.KNIGHT, Vector2i(1, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.BISHOP, Vector2i(2, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.QUEEN, Vector2i(3, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.KING, Vector2i(4, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.BISHOP, Vector2i(5, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.KNIGHT, Vector2i(6, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.ROOK, Vector2i(7, 0))
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(0, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(1, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(2, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(3, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(4, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(5, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(6, 1), Vector2.DOWN)
#add_piece(player1ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(7, 1), Vector2.DOWN)
#
#add_piece(player2ID, ChessPiece.PIECE_TYPES.ROOK, Vector2i(0, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.KNIGHT, Vector2i(1, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.BISHOP, Vector2i(2, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.QUEEN, Vector2i(3, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.KING, Vector2i(4, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.BISHOP, Vector2i(5, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.KNIGHT, Vector2i(6, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.ROOK, Vector2i(7, 7))
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(0, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(1, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(2, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(3, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(4, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(5, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(6, 6), Vector2.UP)
#add_piece(player2ID, ChessPiece.PIECE_TYPES.PAWN, Vector2i(7, 6), Vector2.UP)
