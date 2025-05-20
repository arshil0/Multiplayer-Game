extends Server_data

var hashed_password
@onready var line_edit: LineEdit = $LineEdit


func _on_button_pressed() -> void:
	if line_edit.text.sha256_text() == hashed_password:
		check_server_still_exists()
