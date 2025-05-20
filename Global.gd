extends Node

#this is a global script, it always runs regardless of minigame being played

#the global window object from JavaScript to access its functions
var window

#the unique id of the current player
var id : int
#the unique id of the lobby
var lobby_id : int
#the host is the one who uses backend functions in place of firebase
var is_host := false
#color of the player (used in chess for example)
var color : Color

#keep track of player id's, and who is player 1, 2, 3, 4
var player1_id: int = 0
var player2_id: int = 0
var player3_id: int = 0
var player4_id: int = 0

#keep track of each player color
var player1_color : Color = Color("ff3339")
var player2_color : Color = Color.CADET_BLUE
var player3_color : Color = Color.BLUE_VIOLET
var player4_color : Color = Color.CHARTREUSE


#if this is true, don't reinitialize the player values from Global
var initialized_lobby : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window = JavaScriptBridge.get_interface("window")
	id = window.player_id
	print("ID FROM GODOT")
	print(id)

#generates a new player id (there was a conflict with player id's in the same lobby)
func generate_new_id():
	id = randi_range(10000, 99999)
	window.player_id = id
	print(id)

#restarts all data
func reset_data():
	player1_id = 0
	player2_id = 0
	player3_id = 0
	player4_id = 0
	initialized_lobby = false
	lobby_id = 0
	is_host = false
	color = "null"
	
#someone left, remove them from the game
func remove_player(id_of_leaver: int):
	#host left
	if Global.player1_id == id_of_leaver:
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
		
	elif Global.player2_id == id_of_leaver:
		Global.player2_id = 0
		
	elif Global.player3_id == id_of_leaver:
		Global.player3_id = 0
		
	elif Global.player4_id == id_of_leaver:
		Global.player4_id = 0
	
#this is the global got_data taking a dictionary (parsed JSON)
func got_data(data : Dictionary):
	if !data.has("gameState"):
		return
	var gameState = data.gameState
	
	#this is a signal to go back to lobby
	if gameState.state == "lobby":
		get_tree().change_scene_to_file("res://main_menu/lobby/lobby.tscn")
	
	#someone left
	elif gameState.state == "left":
		remove_player(gameState.leaverID)
		return "left"
