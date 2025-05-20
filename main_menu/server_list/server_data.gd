extends HBoxContainer
class_name Server_data

@export var lobby_scene: PackedScene

var lobby_id
var main_menu


func _on_button_pressed() -> void:
	check_server_still_exists()

#checks if the server we are trying to connect to still exists and then connect to it
func check_server_still_exists():
	main_menu.joining = false
	main_menu.hosting = false
	main_menu.checking = true
	main_menu.ignore_got_data = false
	main_menu.node_that_is_checking_data = self
	Global.window.getData()
	
func got_data(data):
	var join = false
	for id in data.keys():
		if(id == "lobby_id"):
			if str(lobby_id) == data.lobby_id:
				join = true
		if str(lobby_id) == id:
			join = true
		
		if join:
			while(data[lobby_id].players.has(Global.id)):
				Global.generate_new_id()
			Global.window.joined_lobby(lobby_id)
			Global.window.addToPlayerDB(Global.id, JSON.stringify({"player_id": Global.id}))
			Global.lobby_id = lobby_id
			Global.window.addToDB("gameState", JSON.stringify({"state" : "joined", "joinerID" : Global.id}))
			get_tree().change_scene_to_packed(lobby_scene)
			return
		
