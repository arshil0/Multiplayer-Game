extends Node2D

@onready var timer_label: Label = $timer_label
@onready var timer: Timer = $Timer
@onready var board: Board = $board

#how much time each player has to make a move
var move_time = 10


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.one_shot = true
	timer.start()
	
	if Global.is_host:
		add_child(load("res://main_menu/lobby/leave_game_button.tscn").instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(board.is_my_turn()):
		timer_label.modulate = Global.color + Color(0.1, 0.1, 0.1)
	else:
		timer_label.modulate = Color(1, 1, 1)
	timer_label.text = str("%0.1f" % timer.time_left)

func reset_timer():
	timer.stop()
	timer.start(move_time)

func _on_timer_timeout() -> void:
	if(board.is_my_turn()):
		board.unhighlight_tiles()
		print("Skipping turn")
		board.skip_move(true)
