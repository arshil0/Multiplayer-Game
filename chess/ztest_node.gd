extends Node2D

@onready var text: RichTextLabel = $text


var on_data_callback_func = JavaScriptBridge.create_callback(on_data_callback)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.window.godot_got_data = on_data_callback_func
	Global.window.addToPlayerDB(Global.id, JSON.stringify({"player_id": Global.id}))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	Global.is_host = true
	Global.color = "red"
	Global.window.getData()
	
func on_data_callback(data):
	data = data[0]
	data = JSON.parse_string(data)
	Global.color = "blue"
	var gameData = data.get("gameState")
	if gameData:
		if data.players.size() > 1 and gameData.game == "Chess" and gameData.state == "initialize":
			Global.is_host = false
			get_tree().change_scene_to_file("res://chess/chess.tscn")
	if Global.is_host:
		if data.players.size() < 2:
			Global.is_host = false
			text.text = "[font_size=36][color=red][center]No one else seems to be online[/center][/color][/font_size]"
		else:
			get_tree().change_scene_to_file("res://chess/chess.tscn")
