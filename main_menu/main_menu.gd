extends Control

@onready var menu_buttons: VBoxContainer = $CenterContainer/menu_buttons
@onready var host_screen: MarginContainer = $CenterContainer/host_screen

#host related nodes
@onready var lobby_name: LineEdit = $CenterContainer/host_screen/VBoxContainer/lobby_name_container/lobby_name
@onready var lobby_password: LineEdit = $CenterContainer/host_screen/VBoxContainer/lobby_password_container/lobby_password
@onready var host_error_message: Label = $CenterContainer/host_screen/VBoxContainer/host_error_message

#join related nodes
@onready var server_data_node = preload("res://main_menu/server_list/server_data.tscn")
@onready var server_data_node_with_password = preload("res://main_menu/server_list/server_data_with_password.tscn")
@onready var join_screen: MarginContainer = $CenterContainer/join_screen
@onready var server_list: VBoxContainer = $CenterContainer/join_screen/VBoxContainer/servers/server_list

@export var lobby_scene: PackedScene

var got_data_callback = JavaScriptBridge.create_callback(got_data)

var hosting = false
var joining = false
#a node may want to confirm if a server still exists before joining
var checking = false
var node_that_is_checking_data = null
var ignore_got_data = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.window.godot_got_data = got_data_callback


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func host_lobby(firebase_data):
	var found_unique_id = false
	var lobby_id
	
	#check if the generated lobby id is not unique, generate a new one
	while !found_unique_id:
		found_unique_id = true
		lobby_id = str(randi_range(10000, 99999))
		if(firebase_data == null):
			break;
		for existing_lobby_id in firebase_data.keys():
			if lobby_id == existing_lobby_id:
				found_unique_id = false
				break
				
	#found a unique id!
	Global.window.joined_lobby(lobby_id)
	Global.window.delete_lobby_on_host_leave()
	Global.window.addToDB("/name", JSON.stringify(lobby_name.text))
	Global.window.addToDB("lobby_id", JSON.stringify(lobby_id))
	if lobby_password.text != "":
		Global.window.addToDB("/password", JSON.stringify(lobby_password.text.sha256_text()))
		
	Global.window.addToPlayerDB(Global.id, JSON.stringify({"player_id": Global.id}))
	Global.lobby_id = lobby_id
	Global.is_host = true
	get_tree().change_scene_to_packed(lobby_scene)

func fetch_lobby_list(firebase_data):
	if(firebase_data == null):
		return
	for lobby in firebase_data.values():
		var server_node
		if lobby.has("password"):
			server_node = server_data_node_with_password.instantiate()
			server_node.hashed_password = lobby.password
		else:
			server_node = server_data_node.instantiate()

		server_node.lobby_id = lobby.lobby_id
		server_node.main_menu = self
		server_node.get_node("server_name").text = lobby.name
		server_list.add_child(server_node)
	
#this is the host button from the main menu
func _on_host_pressed() -> void:
	menu_buttons.visible = false
	host_screen.visible = true


func _on_join_pressed() -> void:
	menu_buttons.visible = false
	join_screen.visible = true
	joining = true
	Global.window.getData()


#this is the host button inside of the host button, putting in the server name and password
func _on_host_lobby_pressed() -> void:
	if(lobby_name.text == ""):
		host_error_message.text = "please provide a server name"
		return
	hosting = true
	Global.window.getData()


func _on_back_from_host_screen_pressed() -> void:
	host_screen.visible = false
	menu_buttons.visible = true


func _on_join_back_button_pressed() -> void:
	join_screen.visible = false
	menu_buttons.visible = true
	ignore_got_data = false
	for c in server_list.get_children():
		server_list.remove_child(c)
		c.queue_free()

func got_data(args):
	var data = null
	if(args[0]):
		data = JSON.parse_string(args[0])
	if(!ignore_got_data): 
		
		if hosting:
			ignore_got_data = true
			host_lobby(data)
		
		elif joining:
			ignore_got_data = true
			fetch_lobby_list(data)
		
		
		elif checking:
			ignore_got_data = true
			node_that_is_checking_data.got_data(data)
			
	print(data)

	
