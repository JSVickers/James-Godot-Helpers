class_name FPCameraPivot
extends Node3D

const MAX_VERTICAL_ANGLE := PI/3.0
const CAM_SMOOTH_FRACTION := 0.6

@export var target_node: Node3D
@export var sensitivity := 0.003
@export var follow_speed := 30.0

@onready var camera: Camera3D = $Camera
@onready var interaction_cast: RayCast3D = $InteractionCast

var target_pos: Vector3 = Vector3()
var mouse_motion: Vector2 = Vector2()
var controller: SimpleFPSController
var focused_node: Interactor

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = event.screen_relative * sensitivity
	if event.is_action_pressed("interact") and focused_node != null:
		focused_node.interact(controller)

func _ready() -> void:
	controller = owner
	top_level = true
	set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	global_position = target_node.global_position
	
	interaction_cast.collide_with_bodies = false
	interaction_cast.collide_with_areas = true

func _process(delta: float) -> void:
	var y_movement = mouse_motion.x
	var x_movement = mouse_motion.y
	var lerped_y_movement = lerp_angle(global_rotation.y, wrapf(global_rotation.y - y_movement, -PI, PI), CAM_SMOOTH_FRACTION)
	var lerped_x_movement = lerp_angle(global_rotation.x, clampf(global_rotation.x - x_movement, -1.0 * MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE), CAM_SMOOTH_FRACTION)
	global_rotation.y = lerped_y_movement
	global_rotation.x = lerped_x_movement
	mouse_motion = Vector2()
	
	var target_trans: Transform3D = target_node.get_global_transform_interpolated()
	target_pos = lerp(target_pos, target_trans.origin, min(delta * follow_speed, 1.0))
	global_position = target_pos

func _physics_process(_delta: float) -> void:
	interaction_cast.force_raycast_update()
	var interactable := interaction_cast.get_collider() as Interactor
	if interactable == focused_node:
		return
	if interactable == null and focused_node != null:
		focused_node.is_highlighted = false
	focused_node = interactable
	if focused_node != null:
		focused_node.is_highlighted = true
