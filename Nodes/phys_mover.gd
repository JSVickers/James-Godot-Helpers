@tool
class_name PhysicsMover
extends Node

signal movement_ended

enum Axis {
	UP,
	RIGHT,
	BACK
}

@export_category("Time Settings")
@export var path_time := 1.0
@export var rotation_speed := 2.0
@export var auto_start := false
@export var loops := false
@export var num_loops: int = 0

@export_category("Movement Path")
@export var path: PathFollow3D = null

@export_category("Rotation 1")
@export var rotation_axis_1: Axis = Axis.UP
@export_range(-360, 360, 0.1, "degrees") var angle_1: float
@export_category("Rotation 2")
@export var rotation_axis_2: Axis = Axis.RIGHT
@export_range(-360, 360, 0.1, "degrees") var angle_2: float

var AxisDict: Dictionary[Axis, Vector3] = {
	Axis.UP: Vector3.UP,
	Axis.RIGHT: Vector3.RIGHT,
	Axis.BACK: Vector3.BACK
}

var moveable_node: AnimatableBody3D
var start_rot: Vector3
var end_rot: Vector3
var path_tween: Tween = null
var current_progress := 0.0
var current_loop: int = 0
var current_direction := true
var rotation_enabled := false
var finish_movement := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	moveable_node = get_parent()
	if path != null:
		moveable_node.global_position = path.global_position
		current_progress = path.progress_ratio
	if !is_zero_approx(angle_1) or !is_zero_approx(angle_2):
		start_rot = moveable_node.global_rotation
		rotation_enabled = true
		angle_1 = deg_to_rad(angle_1)
		end_rot = moveable_node.transform.rotated(AxisDict[rotation_axis_1], angle_1).basis.get_euler()
	if auto_start:
		start_movement(true)

func start_movement(direction: bool) -> void:
	current_direction = direction
	if path_tween != null:
		path_tween.kill()
	path_tween = create_tween()
	path_tween.finished.connect(end_movement)
	if loops:
		path_tween.loop_finished.connect(loop)
		if num_loops > 0:
			path_tween.set_loops(num_loops)
		else:
			path_tween.set_loops()
	if direction:
		path_tween.tween_property(self, "current_progress", 1.0, path_time * (1 - current_progress))
		return
	path_tween.tween_property(self, "current_progress", 0.0, path_time * current_progress)

func end_movement() -> void:
	path_tween.kill()
	movement_ended.emit()

func loop(loop_count: int) -> void:
	if current_direction:
		finish_movement = true
		current_progress = 0.0
		return
	current_progress = 1.0

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or path_tween == null:
		return
	if path != null:
		path.progress_ratio = current_progress
		moveable_node.global_position = path.global_position
	if rotation_enabled:
		moveable_node.rotate(AxisDict[rotation_axis_1], angle_1, )
		moveable_node.rotation.y = wrapf(moveable_node.global_rotation.y + (rotation_speed * delta), -PI, PI)
	if finish_movement:
		moveable_node.rotation = end_rot
		finish_movement = false
