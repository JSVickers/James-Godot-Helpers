# Copyright @ JSVickers
# An easy to use, state-based, first person controller with tweakable settings to change game feel.

class_name SimpleFPSController
extends CharacterBody3D

const MAX_VERTICAL_ANGLE := PI/3.0
const MOVEMENT_THRESHOLD := 0.1
const CAM_TWEEN_TIME := 0.1

enum InputButtons {
	FORWARD,
	BACK,
	LEFT,
	RIGHT,
	SPRINT,
	CROUCH,
	JUMP,
	ESCAPE,
}

enum States {
	NONE,
	JOG,
	SPRINT,
	CROUCH,
	AIR
}

@export_category("Global Movement Settings")
@export var start_state: States = States.JOG: set = set_current_state
@export var camera_sensitivity := 0.0075
@export var jump_force: Vector3 = Vector3(0.0, 12.0, 0.0)
@export var acceleration_curve: Curve
@export var deceleration_activation_angle: float = 45.0
@export_range(0.0, 1, 0.01) var crouch_speed_modifier: float = 0.6
@export_range(0.0, 1, 0.01) var air_handling: float = 0.4
@export_range(0.0, 1, 0.01) var coyote_time: float = 0.1
@export var InputDict: Dictionary[InputButtons, String] = {
	InputButtons.FORWARD: "move_forward",
	InputButtons.BACK: "move_back",
	InputButtons.LEFT: "move_left",
	InputButtons.RIGHT: "move_right",
	InputButtons.SPRINT: "sprint",
	InputButtons.CROUCH: "crouch",
	InputButtons.JUMP: "jump",
	InputButtons.ESCAPE: "ui_cancel",
}

@export_category("Jog Movement Settings")
@export var jog_min_speed: float = 3.0
@export var jog_max_speed: float = 5.0
@export var jog_acceleration: float = 30.0
@export var jog_deceleration: float = 50.0

@export_category("Sprint Movement Settings")
@export var sprint_min_speed: float = 5.0
@export var sprint_max_speed: float = 10.0
@export var sprint_acceleration: float = 50.0
@export var sprint_deceleration: float = 60.0

@export_category("Air Movement Settings")
@export var air_acceleration: float = 10.0
@export var air_deceleration: float = 5.0

@export_category("Gravity Settings")
@export var fall_min_speed: float = 10.0
@export var fall_max_speed: float = 20.0
@export var gravitational_force: float = 70.0

@onready var stand_collision_shape: CollisionShape3D = %StandingCollision
@onready var crouch_collision_shape: CollisionShape3D = %CrouchingCollision
@onready var camera: Camera3D = %FPSCamera
@onready var stand_cam_target: Marker3D = %StandCam
@onready var crouch_cam_target: Marker3D = %CrouchCam
@onready var crouch_roof_cast: RayCast3D = %CrouchRoofCast
@onready var coyote_timer: Timer = %CoyoteTimer

var current_state := States.NONE: set = set_current_state
var is_jump_enabled := false
var current_min_speed := 0.0
var current_max_speed := 0.0
var current_acceleration := 0.0
var current_deceleration := 0.0
var current_jump_force := Vector3.ZERO
var current_min_fall_speed := 0.0
var current_max_fall_speed := 0.0
var current_gravitational_force := 0.0

func set_current_state(new_state: States):
	if current_state == new_state:
		return
	match current_state:
		States.CROUCH:
			modify_collision(crouch_collision_shape, stand_collision_shape, stand_cam_target)
	current_state = new_state
	match current_state:
		States.JOG: 
			start_movement(jog_min_speed, jog_max_speed, jog_acceleration, jog_deceleration, jump_force)
			is_jump_enabled = true
		States.SPRINT:
			start_movement(sprint_min_speed, sprint_max_speed, sprint_acceleration, sprint_deceleration, jump_force)
			is_jump_enabled = true
		States.CROUCH:
			start_movement(jog_min_speed * crouch_speed_modifier, jog_max_speed * crouch_speed_modifier, jog_acceleration * crouch_speed_modifier, jog_deceleration * crouch_speed_modifier)
			modify_collision(stand_collision_shape, crouch_collision_shape, crouch_cam_target)
			crouch_roof_cast.enabled = true
			is_jump_enabled = false
		States.AIR:
			start_airborne(fall_min_speed, fall_max_speed, gravitational_force, air_handling)
			coyote_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(InputDict[InputButtons.ESCAPE]):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion: Vector2 = event.screen_relative * camera_sensitivity
		rotate_camera(mouse_motion.y, mouse_motion.x)
	if is_jump_enabled and event.is_action_pressed(InputDict[InputButtons.JUMP]):
		jump()

func _ready() -> void:
	coyote_timer.wait_time = coyote_time
	set_current_state(start_state)

func _physics_process(delta: float) -> void:
	check_inputs()
	check_airborne_status()
	change_velocity(delta)
	move_and_slide()

func change_velocity(delta: float):
	modify_ground_velocity(delta, Input.get_vector(InputDict[InputButtons.LEFT], InputDict[InputButtons.RIGHT], InputDict[InputButtons.FORWARD], InputDict[InputButtons.BACK]))
	if current_state == States.AIR:
		modify_vertical_velocity(delta)

func check_inputs():
	if Input.is_action_pressed(InputDict[InputButtons.CROUCH]) and current_state != States.AIR:
		set_current_state(States.CROUCH)
	elif !Input.is_action_pressed(InputDict[InputButtons.CROUCH]) and current_state == States.CROUCH and !crouch_roof_cast.is_colliding():
		crouch_roof_cast.enabled = false
		set_current_state(States.JOG)
	
	if Input.is_action_pressed(InputDict[InputButtons.SPRINT]) and current_state == States.JOG:
		set_current_state(States.SPRINT)
	elif !Input.is_action_pressed(InputDict[InputButtons.SPRINT]) and current_state == States.SPRINT:
		set_current_state(States.JOG)

func check_airborne_status():
	if not is_on_floor():
		set_current_state(States.AIR)
	elif is_on_floor() and current_state == States.AIR:
		set_current_state(States.JOG)

func rotate_camera(x: float, y: float):
	camera.global_rotation.y = wrapf(camera.global_rotation.y - y, -PI, PI)
	camera.global_rotation.x = clampf(camera.global_rotation.x - x, -1.0 * MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	camera.orthonormalize()

func modify_collision(old_collision: CollisionShape3D, new_collision: CollisionShape3D, new_camera_marker: Marker3D):
	old_collision.disabled = true
	new_collision.disabled = false
	var cam_tween := create_tween().set_ease(Tween.EASE_OUT)
	cam_tween.tween_property(camera, "position", new_camera_marker.position, CAM_TWEEN_TIME)

func start_movement(min_speed: float, max_speed: float, accel: float, decel: float, new_jump_force: Vector3 = Vector3.ZERO):
	current_min_speed = min_speed
	current_max_speed = max_speed
	current_acceleration = accel
	current_deceleration = decel
	current_jump_force = new_jump_force

func start_airborne(min_fall_speed: float, max_fall_speed: float, grav_force: float, new_air_handling: float):
	current_acceleration = current_acceleration * new_air_handling
	current_deceleration = current_deceleration * new_air_handling
	current_min_fall_speed = min_fall_speed
	current_max_fall_speed = max_fall_speed
	current_gravitational_force = grav_force

func jump():
	velocity.y = 0.0
	velocity += current_jump_force

func modify_ground_velocity(delta: float, move_input: Vector2):
	move_input = move_input.rotated(-1.0 * camera.global_rotation.y)
	var move_input_3d := Vector3(move_input.x, 0.0, move_input.y)
	var ground_velocity := Vector3(velocity.x, 0.0, velocity.z)
	ground_velocity += calculate_velocity_change(ground_velocity, move_input_3d, MOVEMENT_THRESHOLD, current_max_speed, current_min_speed, current_acceleration, current_deceleration, delta, deceleration_activation_angle ,acceleration_curve)
	velocity.x = ground_velocity.x
	velocity.z = ground_velocity.z

func modify_vertical_velocity(delta: float):
	var gravitational_velocity := Vector3(0.0, velocity.y, 0.0)
	gravitational_velocity += calculate_velocity_change(gravitational_velocity, Vector3.DOWN, MOVEMENT_THRESHOLD, current_max_fall_speed, current_min_fall_speed, current_gravitational_force, current_gravitational_force, delta, deceleration_activation_angle ,acceleration_curve)
	velocity.y = gravitational_velocity.y

func calculate_velocity_change(current_velocity: Vector3, direction: Vector3, movement_threshold: float, max_speed: float, min_speed: float, acceleration: float, deceleration: float, delta: float, decel_angle_deg: float, accel_curve: Curve = null) -> Vector3:
	var target_velocity := Vector3.ZERO
	if direction.length() >= movement_threshold:
		target_velocity = direction.normalized() * max_speed
	
	var angle := 0.0
	if current_velocity.length() > 0.01:
		angle = rad_to_deg(acos(clampf(current_velocity.normalized().dot(target_velocity), -1, 1)))
	var decelerating := angle > decel_angle_deg or target_velocity == Vector3.ZERO
	
	var acceleration_rate := acceleration
	if decelerating:
		acceleration_rate = deceleration
	var min_speed_progress := min_speed / max_speed
	var speed_progress := clampf((current_velocity.length() / max_speed) + min_speed_progress, 0, 1)
	acceleration_rate = clampf(acceleration_rate * speed_progress, 0, acceleration_rate)
	if accel_curve != null:
		var curved_progress := accel_curve.sample(speed_progress)
		acceleration_rate = clampf(acceleration_rate * curved_progress, 0, acceleration_rate)
	
	var velocity_change := target_velocity - current_velocity
	var velocity_change_limit := acceleration_rate * delta
	if velocity_change.length() > velocity_change_limit:
		velocity_change = velocity_change.normalized() * velocity_change_limit
	
	return velocity_change

func _on_coyote_timer_timeout() -> void:
	if current_state == States.AIR:
		is_jump_enabled = false
