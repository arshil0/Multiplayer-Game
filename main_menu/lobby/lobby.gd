extends Node2D

@export var player_icon: PackedScene
@onready var player_1_position: Marker2D = $player1_position
@onready var player_2_position: Marker2D = $player2_position
@onready var player_3_position: Marker2D = $player3_position
@onready var player_4_position: Marker2D = $player4_position

var got_data_callback = JavaScriptBridge.create_callback(got_data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.window.godot_got_data = got_data_callback
	
	if !Global.initialized_lobby:
		if Global.is_host:
			var player_icon_object = player_icon.instantiate()
			player_1_position.add_child(player_icon_object)
			Global.player1_id = Global.id
			Global.color = Color("ff3339")
			#the host is always player #1
			Global.window.addToPlayerDB(Global.id, JSON.stringify({"player_id": Global.id, "player_number": 1}))
		else:
			Global.window.addToDB("gameState", JSON.stringify({"state" : "nothing"}))
				
			
		Global.initialized_lobby = true
	else:
		if Global.player1_id != 0:
			add_player(Global.player1_id, 1)
		if Global.player2_id != 0:
			add_player(Global.player2_id, 2)
		if Global.player3_id != 0:
			add_player(Global.player3_id, 3)
		if Global.player4_id != 0:
			add_player(Global.player4_id, 4)
			
	if !Global.is_host:
		
		for child in get_children():
			if child is Button:
				remove_child(child)
		

func setup_lobby_for_client(player_list : Dictionary):
	var max_player_number = 1
	for player_data in player_list.values():
		if player_data.has("player_number"):
			add_player(player_data.player_id, player_data.player_number)
			max_player_number = max(player_data.player_number, max_player_number)
			
			#this means I am player 2
			if max_player_number == 1:
				Global.color = Color.CADET_BLUE
				
			#I am player 3
			elif max_player_number == 2:
				Global.color = Color.BLUE_VIOLET
			
			#I am player 4
			else:
				Global.color = Color.CHARTREUSE
			
	
	max_player_number += 1
	Global.window.addToPlayerDB(Global.id, JSON.stringify({"player_id": Global.id, "player_number": max_player_number}))
	add_player(Global.id, max_player_number)

func add_player(id_of_joiner : int, player_number : int = -1):
	print("adding player with id:")
	print(id_of_joiner)
	
	if player_number == -1:
		if Global.player2_id == 0:
			var player_icon_object = player_icon.instantiate()
			player_2_position.add_child(player_icon_object)
			Global.player2_id = id_of_joiner
			print(Global.player2_id)
			
			
		elif Global.player3_id == 0 and Global.player2_id != id_of_joiner:
			var player_icon_object = player_icon.instantiate()
			player_3_position.add_child(player_icon_object)
			Global.player3_id = id_of_joiner
			
		elif Global.player4_id == 0 and Global.player3_id != id_of_joiner:
			var player_icon_object = player_icon.instantiate()
			player_4_position.add_child(player_icon_object)
			Global.player4_id = id_of_joiner
			
	elif player_number == 1:
		var player_icon_object = player_icon.instantiate()
		player_1_position.add_child(player_icon_object)
		Global.player1_id = id_of_joiner
	elif player_number == 2:
		var player_icon_object = player_icon.instantiate()
		player_2_position.add_child(player_icon_object)
		Global.player2_id = id_of_joiner
	elif player_number == 3:
		var player_icon_object = player_icon.instantiate()
		player_3_position.add_child(player_icon_object)
		Global.player3_id = id_of_joiner
	elif player_number == 4:
		var player_icon_object = player_icon.instantiate()
		player_4_position.add_child(player_icon_object)
		Global.player4_id = id_of_joiner

func player_left(id_of_leaver: int):
	#host left
	if Global.player1_id == id_of_leaver:
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
		
	elif Global.player2_id == id_of_leaver:
		player_2_position.get_child(0).queue_free()
		Global.player2_id = 0
		
	elif Global.player3_id == id_of_leaver:
		player_3_position.get_child(0).queue_free()
		Global.player3_id = 0
		
	elif Global.player4_id == id_of_leaver:
		player_4_position.get_child(0).queue_free()
		Global.player4_id = 0

func got_data(args):
	var data = null
	if(args[0]):
		data = JSON.parse_string(args[0])
	if data:
		#if I just joined, save the ID of the other players in global
		if(Global.player1_id == 0):
			setup_lobby_for_client(data.players)
		
		var gameState = data.get("gameState")
		if gameState:
			if gameState.state == "initializing" and Global.is_host:
				Global.is_host = true
				if gameState.game == "Chess":
					get_tree().change_scene_to_file("res://minigames/chess/chess.tscn")
				elif gameState.game == "hoverGame":
					get_tree().change_scene_to_file("res://minigames/hover_game/hover_game.tscn")
					
			elif gameState.state == "initialized" and !Global.is_host:
				Global.is_host = false
				if gameState.game == "Chess":
					get_tree().change_scene_to_file("res://minigames/chess/chess.tscn")
				elif gameState.game == "hoverGame":
					get_tree().change_scene_to_file("res://minigames/hover_game/hover_game.tscn")
					
					
			elif gameState.state == "joined":
				add_player(gameState.joinerID)
				
			elif gameState.state == "left":
				player_left(gameState.leaverID)
				
			elif gameState.state == "bye":
				#FIX IDEA:
				#if a client joins (2+ players in lobby), unsubsribe from onDisconnect(ref).remove() and subscribe to sending a message to clients when the host leaves
				#if a client leaves and there is only the host in the lobby, do the opposite
				Global.window.unsubscribe()
				get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
