extends Camera3D

const MAX_VERTICAL_ANGLE := PI/3.0

@export var movement_enabled := true
@export var sensitivity := 0.0075

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel" ):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and movement_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion: Vector2 = event.screen_relative * sensitivity
		rotate_camera(mouse_motion.y, mouse_motion.x)

func rotate_camera(x: float, y: float):
	global_rotation.y = wrapf(global_rotation.y - y, -PI, PI)
	global_rotation.x = clampf(global_rotation.x - x, -1.0 * MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	orthonormalize()
