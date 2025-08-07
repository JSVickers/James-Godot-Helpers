extends CharacterBody3D

@export_category("Global Movement Settings")
@export var acceleration_curve: Curve
@export var deceleration_activation_angle: float
@export_range(0.0, 1, 0.01) var crouch_speed_modifier: float = 0.6
@export_range(0.0, 1, 0.01) var coyote_time: float = 0.2

@export_category("Jog Movement Settings")
@export var jog_min_speed: float
@export var jog_max_speed: float
@export var jog_acceleration: float
@export var jog_deceleration: float

@export_category("Sprint Movement Settings")
@export var sprint_min_speed: float
@export var sprint_max_speed: float
@export var sprint_acceleration: float
@export var sprint_deceleration: float

@export_category("Air Movement Settings")
@export var jump_force: Vector3
@export var air_acceleration: float
@export var air_deceleration: float

@export_category("Gravity Settings")
@export var fall_min_speed: float
@export var fall_max_speed: float
@export var gravitational_force: float
var gravitational_direction: Vector3 = Vector3.DOWN

@onready var state_machine: JamFSM
@onready var stand_collision_shape: CollisionShape3D = %StandingCollision
@onready var crouch_collision_shape: CollisionShape3D = %CrouchingCollision
@onready var camera: Camera3D = %FPSCamera
@onready var stand_cam_target: Marker3D = %StandCam
@onready var crouch_cam_target: Marker3D = %CrouchCam
@onready var crouch_roof_cast: RayCast3D = %CrouchRoofCast

func _ready() -> void:
	state_machine = JamFSM.new()
	var fps_data := FPSStateLogic.FPSData.new(
		self, 
		camera,
		stand_collision_shape,
		stand_cam_target,
		coyote_time,
		crouch_roof_cast)
	state_machine.set_shared_data(fps_data)
	var jog_state := FPSStateLogic.FPSMoveState.new(
		state_machine, 
		self, 
		jog_min_speed, 
		jog_max_speed, 
		jog_acceleration, 
		jog_deceleration, 
		deceleration_activation_angle, 
		true,
		stand_collision_shape,
		stand_cam_target,
		jump_force)
	var sprint_state := FPSStateLogic.FPSMoveState.new(
		state_machine, 
		self, 
		sprint_min_speed, 
		sprint_max_speed, 
		sprint_acceleration, 
		sprint_deceleration, 
		deceleration_activation_angle, 
		true,
		stand_collision_shape,
		stand_cam_target,
		jump_force)
	var crouch_state := FPSStateLogic.FPSMoveState.new(
		state_machine, 
		self, 
		jog_min_speed * crouch_speed_modifier, 
		jog_max_speed * crouch_speed_modifier, 
		jog_acceleration * crouch_speed_modifier, 
		jog_deceleration * crouch_speed_modifier, 
		deceleration_activation_angle, 
		false,
		crouch_collision_shape,
		crouch_cam_target,
		jump_force)
	var air_state := FPSStateLogic.FPSAirborneState.new(
		state_machine,
		self,
		air_acceleration,
		air_deceleration,
		deceleration_activation_angle,
		fall_min_speed,
		fall_max_speed,
		gravitational_force,
		false,
		stand_collision_shape,
		stand_cam_target,
		jump_force
	)
	state_machine.add_state("Jog", jog_state)
	state_machine.add_state("Sprint", sprint_state)
	state_machine.add_state("Crouch", crouch_state)
	state_machine.add_state("Air", air_state)
	state_machine.set_start_state(jog_state.state_id)
	state_machine.add_transition(jog_state.state_id, sprint_state.state_id, FPSStateLogic.Events.ENTER_SPRINT)
	state_machine.add_transition(sprint_state.state_id, jog_state.state_id, FPSStateLogic.Events.RELEASE_SPRINT)
	state_machine.add_transition(jog_state.state_id, air_state.state_id, FPSStateLogic.Events.ENTER_AIR)
	state_machine.add_transition(sprint_state.state_id, air_state.state_id, FPSStateLogic.Events.ENTER_AIR)
	state_machine.add_transition(air_state.state_id, jog_state.state_id, FPSStateLogic.Events.LANDED)
	state_machine.add_transition(jog_state.state_id, crouch_state.state_id, FPSStateLogic.Events.CROUCHED)
	state_machine.add_transition(crouch_state.state_id, jog_state.state_id, FPSStateLogic.Events.STOOD_UP)
	state_machine.add_transition(crouch_state.state_id, air_state.state_id, FPSStateLogic.Events.ENTER_AIR)
	add_child(state_machine)

func _unhandled_input(event: InputEvent) -> void:
	state_machine.pass_input_event(event)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	move_and_slide()
