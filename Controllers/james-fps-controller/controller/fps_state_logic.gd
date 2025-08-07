class_name FPSStateLogic
extends RefCounted

const MOVEMENT_THRESHOLD := 0.1

enum Events {
	ENTER_SPRINT,
	RELEASE_SPRINT,
	ENTER_AIR,
	CROUCHED,
	STOOD_UP,
	LANDED
}

class FPSData extends RefCounted:
	var fp_camera: Camera3D = null
	var controller: CharacterBody3D = null
	var acceleration_curve: Curve = null
	var last_min_speed: float = 0.0
	var last_max_speed: float = 0.0
	var curr_collision: CollisionShape3D
	var curr_cam_marker: Marker3D
	var coyote_time: float = 0.0
	var coyote_timer: float = 0.0
	var coyote_time_enabled := false
	var crouch_roof_cast: RayCast3D = null
	func _init(char_body: CharacterBody3D, cam_3d: Camera3D, start_collision: CollisionShape3D, start_cam_marker: Marker3D, start_coyote_time: float, roof_cast: RayCast3D, accel_curve: Curve = null):
		fp_camera = cam_3d
		controller = char_body
		acceleration_curve = accel_curve
		curr_collision = start_collision
		curr_cam_marker = start_cam_marker
		coyote_time = start_coyote_time
		crouch_roof_cast = roof_cast

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
	var jump_force := Vector3.ZERO
	var collision: CollisionShape3D = null
	var camera_pos: Marker3D = null
	func enter():
		if state_name == "Crouch":
			data.crouch_roof_cast.enabled = true
		if data.curr_collision != collision:
			data.curr_collision.disabled = true
			collision.disabled = false
			data.curr_collision = collision
		if data.curr_cam_marker != camera_pos:
			data.fp_camera.global_position = camera_pos.global_position
			data.curr_cam_marker = camera_pos
	func _init(owner_state_machine: JamFSM, owner_node: Node, _min_speed: float, _max_speed: float, _acceleration: float, _deceleration: float, _decel_angle_deg: float, _jump_enabled: bool, _collision: CollisionShape3D, _camera_pos: Marker3D, _jump_force: Vector3 = Vector3.ZERO, _crouch_hitbox: bool = false) -> void:
		super(owner_state_machine, owner_node)
		min_speed = _min_speed
		max_speed = _max_speed
		acceleration = _acceleration
		deceleration = _deceleration
		decel_angle_deg = _decel_angle_deg
		jump_enabled = _jump_enabled
		jump_force = _jump_force
		collision = _collision
		camera_pos = _camera_pos
	func update(delta: float):
		if !data.controller.is_on_floor():
			data.last_min_speed = min_speed
			data.last_max_speed = max_speed
			state_machine.trigger_event(Events.ENTER_AIR)
		var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		move_input = move_input.rotated(-1.0 * data.fp_camera.global_rotation.y)
		var move_input_3d := Vector3(move_input.x, 0.0, move_input.y)
		var ground_velocity := Vector3(data.controller.velocity.x, 0.0, data.controller.velocity.z)
		ground_velocity += VectorUtils.calculate_velocity_change(ground_velocity, move_input_3d, MOVEMENT_THRESHOLD, max_speed, min_speed, acceleration, deceleration, delta, data.acceleration_curve)
		data.controller.velocity.x = ground_velocity.x
		data.controller.velocity.z = ground_velocity.z
		if Input.is_action_just_pressed("jump") and jump_enabled:
			data.coyote_time_enabled = false
			data.controller.velocity += jump_force
		if !Input.is_action_pressed("crouch") and data.crouch_roof_cast.enabled and !data.crouch_roof_cast.is_colliding():
			data.crouch_roof_cast.enabled = false
			state_machine.trigger_event(Events.STOOD_UP)
		if Input.is_action_pressed("sprint"):
			state_machine.trigger_event(Events.ENTER_SPRINT)
		elif Input.is_action_just_released("sprint"):
			state_machine.trigger_event(Events.RELEASE_SPRINT)
	func input_event(event: InputEvent):
		if event.is_action_pressed("crouch"):
			state_machine.trigger_event(Events.CROUCHED)

class FPSAirborneState extends FPSMoveState:
	var max_fall_speed: float = 0.0
	var min_fall_speed: float = 0.0
	var gravitational_force: float = 0.0
	func enter():
		super()
		min_speed = data.last_min_speed
		max_speed = data.last_max_speed
	func _init(owner_state_machine: JamFSM, owner_node: Node, air_acceleration: float, air_deceleration: float, _decel_angle_deg: float, _min_fall_speed: float, _max_fall_speed: float, _grav_force: float, _jump_enabled: bool, _collision: CollisionShape3D, _camera_pos: Marker3D, _jump_force: Vector3) -> void:
		super(owner_state_machine, owner_node, 0.0, 0.0, air_acceleration, air_deceleration, _decel_angle_deg, _jump_enabled, _collision, _camera_pos, _jump_force)
		max_fall_speed = _max_fall_speed
		min_fall_speed = _min_fall_speed
		gravitational_force = _grav_force
	func update(delta: float):
		var in_coyote_time := data.coyote_timer < data.coyote_time
		if !jump_enabled and in_coyote_time and data.coyote_time_enabled:
			if Input.is_action_just_pressed("jump"):
				data.controller.velocity.y = 0.0
				data.coyote_time_enabled = false
				data.controller.velocity += jump_force
			data.coyote_timer += delta
		var gravitational_velocity := Vector3(0.0, data.controller.velocity.y, 0.0)
		gravitational_velocity += VectorUtils.calculate_velocity_change(gravitational_velocity, Vector3.DOWN, MOVEMENT_THRESHOLD, max_fall_speed, min_fall_speed, gravitational_force, gravitational_force, delta, data.acceleration_curve)
		data.controller.velocity.y = gravitational_velocity.y
		super(delta)
		if data.controller.is_on_floor():
			state_machine.trigger_event(Events.LANDED)
	func exit():
		data.coyote_time_enabled = true
		data.coyote_timer = 0.0
