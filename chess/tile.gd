extends Node2D

static var board : Board
static var focused_piece : ChessPiece = null
var tile_coords : Vector2i

@onready var sprite: Sprite2D = $sprite
@onready var tile_size = get_parent().tile_size
@onready var weak_highlight_sprite: Sprite2D = $weak_highlight
@onready var strong_highlight_sprite: Sprite2D = $strong_highlight
@onready var highlighted := false

var mouse_inside := false
var chess_piece : ChessPiece = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tile_coords = position / tile_size
	
	if (tile_coords.x % 2 == 0 and tile_coords.y % 2 == 0) or (tile_coords.x % 2 == 1 and tile_coords.y % 2 == 1):
		sprite.texture = load("res://chess/tile_dark.png")
		
	global_position += Vector2(0, 1000)
	
	

func appear():
	var tween = create_tween()
	var rand = randf_range(0.5, 3)
	tween.parallel().tween_property(self, "global_position", global_position - Vector2(0, 1000), rand).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if chess_piece:
		tween.parallel().tween_property(chess_piece, "global_position", global_position - Vector2(0, 1000), rand).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.play()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_click") and mouse_inside:
		if focused_piece != null:
			attempt_to_move_chess_piece()
			
		elif chess_piece != null:
			if chess_piece.piece_id == board.id_of_current_player and chess_piece.piece_id == Global.id:
				chess_piece.focused = true
				focused_piece = chess_piece
				board.strengthen_highlights()
	if event.is_action_released("mouse_click") and mouse_inside:
		#if there isn't a focused piece, nothing to do when releasing left click
		if !focused_piece:
			return
			
		
		#letting go of mouse button on the same tile
		if chess_piece and chess_piece.focused:
			return
			
		attempt_to_move_chess_piece()
		
		if focused_piece:
			focused_piece.focused = false
			focused_piece = null
			
		update_board_highlights()
		
	
func assign_chess_piece(piece : ChessPiece, initialization : bool = false):
	#this means that an opponent is eating a piece
	if chess_piece != null:
		chess_piece.remove(board)
	
	chess_piece = piece
	piece.pos = tile_coords
	
	if initialization:
		piece.global_position = global_position
		
	else:
		piece.update_position_with_tween(global_position)
	
	
func remove_chess_piece():
	chess_piece = null;
	
#attempts to weak highlight the tile, the returned value lets the board know whether to continue with repetitive pattern
func highlight_weak(highlighting_piece_id : int, attacking : bool) -> bool:
	if chess_piece:
		if !attacking or chess_piece.piece_id == highlighting_piece_id:
			return false
	highlighted = true
	weak_highlight_sprite.visible = true
	if chess_piece:
		return false
	return true
	
#just strengthen the highlights
func highlight_strong():
	if highlighted:
		strong_highlight_sprite.visible = true
	
func unhighlight():
	highlighted = false
	weak_highlight_sprite.visible = false
	strong_highlight_sprite.visible = false
	

func update_board_highlights():
	board.unhighlight_tiles()
	if chess_piece:
		chess_piece.highlight_possible_moves(board)
		
func attempt_to_move_chess_piece():
	if highlighted:
		focused_piece.move(board, tile_coords)
	focused_piece.focused = false
	focused_piece = null
	update_board_highlights()

func _on_area_2d_mouse_entered() -> void:
	mouse_inside = true
	update_board_highlights()


func _on_area_2d_mouse_exited() -> void:
	mouse_inside = false
