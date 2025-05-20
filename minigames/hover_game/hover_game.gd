extends Node2D


var got_data_callback = JavaScriptBridge.create_callback(got_data)

#score of local player
var score : float = 0
#will be intiailized later, this is when the meteors will get spawned
var next_spawn_time : float = 0
#how fast each meteor will spawn (for 1 player, it's 1 second)
var spawn_speed : float = 1

#using an array will be much better and convenient, but I was running out of time :D
@onready var player_1_score: Label = $player1score
@onready var player_2_score: Label = $player2score
@onready var player_3_score: Label = $player3score
@onready var player_4_score: Label = $player4score

#displays the current game timer on the top middle (how long until the game ends)
@onready var timer: Label = $timer

@onready var black_hole: Node2D = $black_hole
#keeps track of how much time is left until the game ends
@onready var game_time: Timer = $game_time

var random_seed = -1
var rng = RandomNumberGenerator.new()

#the mouse position object of each player
var player_1_mouse = null
var player_2_mouse = null
var player_3_mouse = null
var player_4_mouse = null

@onready var window = Global.window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.is_host:
		add_child(load("res://main_menu/lobby/leave_game_button.tscn").instantiate())
		
	#set up score display colors, if an n'th player doesn't exist, remove the timer object
	if Global.player1_id != 0:
		player_1_score.modulate = Global.player1_color
	else:
		remove_child(player_1_score)
	if Global.player2_id != 0:
		spawn_speed = 0.8
		player_2_score.modulate = Global.player2_color + Color(0.3, 0.3, 0.3)
	else:
		remove_child(player_2_score)
	if Global.player3_id != 0:
		spawn_speed = 0.6
		player_3_score.modulate = Global.player3_color
	else:
		remove_child(player_3_score)
	if Global.player4_id != 0:
		spawn_speed = 0.4
		player_4_score.modulate = Global.player4_color
	else:
		remove_child(player_4_score)
	
	window.godot_got_data = got_data_callback
	
	#objects start spawning after 1.5 seconds of starting the game
	next_spawn_time = game_time.wait_time - 1.5
	
	#the host decides the random seed
	if Global.is_host:
		random_seed = randi()
		rng.seed = random_seed
		window.addToDB("gameState", JSON.stringify({"game": "hoverGame", "state": "initialized", "randomSeed" : random_seed}))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#update the time display
	timer.text = str("0:%02d" % int(game_time.time_left))
	
	#if the timer has ended, end the game
	if game_time.time_left <= 0 and Global.is_host:
		Global.window.addToDB("gameState", JSON.stringify({"state" : "lobby"}))
	#time to spawn a meteor
	if game_time.time_left < next_spawn_time:
		var random_position = choose_random_meteor_position()
		next_spawn_time -= 1
		add_meteor(random_position)
		
	#black hole will scale up by +3 throughout the time limit
	var scale_up = delta * 3 / game_time.wait_time
	black_hole.scale += Vector2(scale_up, scale_up)

	#send the mouse position to other players
	var mouse_pos = get_global_mouse_position()
	window.updateDB("gameState/players/" + str(Global.id), JSON.stringify({"position" : {"x" : mouse_pos.x, "y" : mouse_pos.y}, "score": int(score)}))

#choose a random location to spawn the next meteor
func choose_random_meteor_position():
	var pos : Vector2 = Vector2.ZERO
	#choose y position
	if rng.randi_range(0, 1) == 0:
		
		#choose x position
		if rng.randi_range(0, 1) == 0:
			pos.x = 1152 + 100
		else:
			pos.x = -100
			
		pos.y = rng.randf_range(-50, 648 + 100)
		
	#choose x position
	if rng.randi_range(0, 1) == 0:
		
		#choose y position
		if rng.randi_range(0, 1) == 0:
			pos.y = 648 + 100
		else:
			pos.y = -100
			
		pos.x = rng.randf_range(-50, 1152 + 100)
		
	return pos

#create a meteor object
func add_meteor(random_position : Vector2):
	var meteor = load("res://minigames/hover_game/meteor.tscn").instantiate()
	add_child(meteor)
	meteor.global_position = random_position
	meteor.name = str(rng.randi())

#a meteor was hit (by you), destroy it and notify others
func hit_meteor(meteor_object : Node2D):
	score += 1
	if Global.id == Global.player1_id:
		player_1_score.text = "player 1: " + str(score)
	if Global.id == Global.player2_id:
		player_2_score.text = "player 2: " + str(score)
	if Global.id == Global.player3_id:
		player_3_score.text = "player 3: " + str(score)
	if Global.id == Global.player4_id:
		player_4_score.text = "player 4: " + str(score)

	remove_child(meteor_object)
	window.addToDB("gameState", JSON.stringify({"state" : "hit", "meteorHit" : meteor_object.name}))

func got_data(args):
	var data = args[0]
	data = JSON.parse_string(data)
	if(!data.has("lobby_id")):
		data = data[str(Global.lobby_id)]
		
	if Global.got_data(data) == "left":
		var leaver = str(data.gameState.leaverID)
		if int(leaver) == Global.player1_id:
			remove_child(player_1_score)
		elif int(leaver) == Global.player2_id:
			remove_child(player_2_score)
		elif int(leaver) == Global.player3_id:
			remove_child(player_3_score)
		elif int(leaver) == Global.player4_id:
			remove_child(player_4_score)
		
	
	var gameState = data.get("gameState")
	if gameState != null:
		if random_seed == -1:
			random_seed = int(gameState.get("randomSeed"))
			rng.seed = random_seed
		
		var state = gameState.get("state")
		
		
		if state == "hit":
			var meteor_hit = gameState.meteorHit
			remove_child(get_node(meteor_hit))
		
		
		var players = gameState.get("players")
		if players != null:
			for playerId in players:
				playerId = int(playerId)
				if playerId == Global.id:
					continue
				print(players)
				var score = players[str(playerId)].score
				var mouse_pos = players[str(playerId)].position
				
				if playerId == Global.player1_id:
					player_1_score.text = "player 1: " + str(score)
					if player_1_mouse == null:
						player_1_mouse = load("res://minigames/hover_game/player_mouse.tscn").instantiate()
						add_child(player_1_mouse)
						player_1_mouse.modulate = Global.player1_color
					player_1_mouse.global_position = Vector2(mouse_pos.x, mouse_pos.y)
				elif playerId == Global.player2_id:
					player_2_score.text = "player 2: " + str(score)
					if player_2_mouse == null:
						player_2_mouse = load("res://minigames/hover_game/player_mouse.tscn").instantiate()
						add_child(player_2_mouse)
						player_2_mouse.modulate = Global.player2_color + Color(0.3, 0.3, 0.3)
					player_2_mouse.global_position = Vector2(mouse_pos.x, mouse_pos.y)
				elif playerId == Global.player3_id:
					player_3_score.text = "player 3: " + str(score)
					if player_3_mouse == null:
						player_3_mouse = load("res://minigames/hover_game/player_mouse.tscn").instantiate()
						add_child(player_3_mouse)
						player_3_mouse.modulate = Global.player3_color
					player_3_mouse.global_position = Vector2(mouse_pos.x, mouse_pos.y)
				elif playerId == Global.player4_id:
					player_4_score.text = "player 4: " + str(score)
					if player_4_mouse == null:
						player_4_mouse = load("res://minigames/hover_game/player_mouse.tscn").instantiate()
						add_child(player_4_mouse)
						player_4_mouse.modulate = Global.player4_color
					player_4_mouse.global_position = Vector2(mouse_pos.x, mouse_pos.y)

#when a meteor enters the black hole, delete it
func _on_black_hole_area_area_entered(area: Area2D) -> void:
	remove_child(area.get_parent())
