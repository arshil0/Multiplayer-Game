extends Node

var window

#the unique id of the current player
var id : int
#the host is the one who uses backend functions in place of firebase
var is_host := false
#color of the player (used in chess for example)
var color : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window = JavaScriptBridge.get_interface("window")
	id = window.player_id
	print("ID FROM GODOT")
	print(id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
