class_name StaticConPivot
extends Node3D

const MAX_VERTICAL_ANGLE := PI/60.0
const MAX_HORIZONTAL_ANGLE := PI/45.0
const BASE_RESOLUTION := Vector2(1920, 1080)
const ROTATION_RADIUS := 300.0

@export var movement_speed := 30.0
@export var rotation_speed := 2.0

@onready var camera: Camera3D = %MainCamera

var target_pos: Vector3 = Vector3()
var controller: Node
var is_following := false
var base_diagonal := 0.0

var follow_node: Node3D = null: set = _set_follow_node

func _set_follow_node(target: Node3D):
	follow_node = target
	if follow_node == null:
		is_following = false
	is_following = true

func _ready() -> void:
	controller = owner
	var current_rotation := global_rotation
	base_diagonal = get_viewport().get_visible_rect().position.distance_to(BASE_RESOLUTION)

func _process(delta: float) -> void:
	calc_rotation(delta)
	if is_following:
		follow_target_node(delta)

func calc_rotation(delta: float) -> void:
	var diagonal_length := get_viewport().get_visible_rect().position.distance_to(get_viewport().get_visible_rect().size)
	var length_multiplier := diagonal_length / base_diagonal
	var final_radius := ROTATION_RADIUS * length_multiplier
	var screen_centre := get_viewport().get_visible_rect().size * 0.5
	var distance_to_cursor := screen_centre.distance_to(get_viewport().get_mouse_position())
	distance_to_cursor = clampf(distance_to_cursor, 0.0, final_radius)
	var rotation_factor = distance_to_cursor / final_radius
	var rotation_direction = screen_centre.direction_to(get_viewport().get_mouse_position())
	var rotation_amount := Vector2()
	rotation_amount.x = rotation_direction.x * rotation_factor
	rotation_amount.y = rotation_direction.y * rotation_factor
	
	var target_horizontal = MAX_HORIZONTAL_ANGLE * rotation_amount.y
	var target_vertical = MAX_VERTICAL_ANGLE * rotation_amount.x
	
	global_rotation.x = lerp_angle(global_rotation.x, -target_horizontal, rotation_speed * delta)
	global_rotation.y = lerp_angle(global_rotation.y, -target_vertical, rotation_speed * delta)

func follow_target_node(delta: float) -> void:
	var target_trans: Transform3D = follow_node.get_global_transform_interpolated()
	target_pos = lerp(target_pos, target_trans.origin, min(movement_speed * delta, 1.0))
	global_position = target_pos
