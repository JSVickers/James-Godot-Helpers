class_name FPSStateLogic
extends RefCounted

const MOVEMENT_THRESHOLD := 0.1

enum Events {
	ENTER_SPRINT,
	ENTER_JOG,
	ENTER_AIR
}

class FPSData extends RefCounted:
	var fp_camera: Camera3D = null
	var controller: CharacterBody3D = null
	var acceleration_curve: Curve = null
	func _init(char_body: CharacterBody3D, cam_3d: Camera3D, accel_curve: Curve = null):
		fp_camera = cam_3d
		controller = char_body
		acceleration_curve = accel_curve

class FPSBase extends JamFSM.JamState:
	var data: FPSData = null
	func _init(owner_state_machine: JamFSM, owner_node: Node) -> void:
		super(owner_state_machine, owner_node)
		data = owner_state_machine.get_shared_data() as FPSData

class FPSMoveState extends FPSBase:
	var min_speed := 2.0
	var max_speed := 5.0
	var acceleration := 30.0
	var deceleration := 50.0
	var decel_angle_deg := 45.0
	var jump_enabled := false
	func _init(owner_state_machine: JamFSM, owner_node: Node, _min_speed: float, _max_speed: float, _acceleration: float, _deceleration: float, _decel_angle_deg: float, _jump_enabled: bool) -> void:
		super(owner_state_machine, owner_node)
		min_speed = _min_speed
		max_speed = _max_speed
		acceleration = _acceleration
		deceleration = _deceleration
		decel_angle_deg = _decel_angle_deg
		jump_enabled = _jump_enabled
	func update(delta: float):
		var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		move_input = move_input.rotated(-1.0 * data.fp_camera.global_rotation.y)
		var move_input_3d := Vector3(move_input.x, 0.0, move_input.y)
		var velocity := data.controller.velocity
		velocity += VectorUtils.calculate_velocity_change(velocity, move_input_3d, MOVEMENT_THRESHOLD, max_speed, min_speed, acceleration, deceleration, delta, data.acceleration_curve)
		data.controller.velocity = velocity
