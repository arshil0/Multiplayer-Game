extends Node2D

var center_position : Vector2 = Vector2(576, 324)

var speed = 40
var rotation_speed : float = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(rotation_speed)
	global_position += (center_position - global_position).normalized() * speed * delta


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.pressed:
		get_parent().hit_meteor(self)
	print(name)
