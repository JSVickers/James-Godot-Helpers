extends CharacterBody3D

@export_category("Global Movement Settings")
@export var acceleration_curve: Curve
@export var deceleration_activation_angle: float

@export_category("Jog Movement Settings")
@export var jog_min_speed: float
@export var jog_max_speed: float
@export var jog_acceleration: float
@export var jog_deceleration: float

@onready var state_machine: JamFSM = %FPSStateMachine
@onready var camera: Camera3D = %FPSCamera

func _ready() -> void:
	var fps_data := FPSStateLogic.FPSData.new(self, camera, acceleration_curve)
	state_machine.set_shared_data(fps_data)
	var jog_state := FPSStateLogic.FPSMoveState.new(
		state_machine, 
		self, 
		jog_min_speed, 
		jog_max_speed, 
		jog_acceleration, 
		jog_deceleration, 
		deceleration_activation_angle, 
		true)
	state_machine.add_state("Jog", jog_state)
	state_machine.set_start_state(jog_state.state_id)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	move_and_slide()
