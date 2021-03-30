extends Spatial

export var rotation_speed = 1.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func rotate_with_action(obj, axis, act0, act1, delta):
	var rot = 0
	if Input.is_action_pressed(act0):
		rot += 1
	if Input.is_action_pressed(act1):
		rot -= 1
	
	obj.rotate_object_local(axis, rot * rotation_speed * delta)
	
	
func get_input_keyboard(delta):
	rotate_with_action(self, Vector3.UP, "cam_right", "cam_left", delta)
	rotate_with_action($InnerGimbal, Vector3.RIGHT, "cam_down", "cam_up", delta)
	
func _process(delta):
	get_input_keyboard(delta)

