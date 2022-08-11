extends KinematicBody

const SPEED = 10
const MOUSE_SENSITIVITY = 0.01

onready var camera = $Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-MOUSE_SENSITIVITY * event.relative.x)
		camera.rotate_x(-MOUSE_SENSITIVITY * event.relative.y)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_vec = Vector3(input_vec.x, 0, input_vec.y)
	move_vec = transform.basis.xform(move_vec)
	move_and_slide(move_vec * SPEED, Vector3.UP)
