@tool
class_name PhysicsMover
extends Node

signal movement_ended

enum Axis {
	UP,
	RIGHT,
	BACK
}

@export var movement_target: Node3D
@export var rotation_target: Node3D
@export var interactable_trigger: Interactor = null: set = set_interactable_trigger

@export_category("Time Settings")
@export var path_time := 1.0
@export var auto_start := false
@export var start_backwards := false
@export var loops := false
@export var num_loops: int = 0
@export var delay_duraction: float = 0.0

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

var start_basis: Basis
var path_tween: Tween = null
var current_progress := 0.0
var current_loop: int = 0
var current_direction := true
var rotation_enabled := false
var finish_movement := false
var movement_enabled := false

func set_interactable_trigger(new_trigger: Interactor):
	if interactable_trigger != null and interactable_trigger.state_changed.is_connected(trigger_movement):
		interactable_trigger.state_changed.disconnect(trigger_movement)
	interactable_trigger = new_trigger
	if not is_inside_tree():
		return
	if interactable_trigger != null:
		interactable_trigger.state_changed.connect(trigger_movement)
		start_movement(interactable_trigger.is_active)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_interactable_trigger(interactable_trigger)
	current_progress = 0.0
	if path != null and movement_target != null:
		movement_enabled = true
		movement_target.global_position = path.global_position
		current_progress = path.progress_ratio
	if rotation_target != null:
		rotation_enabled = true
		angle_1 = deg_to_rad(angle_1)
		angle_2 = deg_to_rad(angle_2)
		start_basis = rotation_target.transform.basis
	if auto_start:
		if start_backwards:
			current_progress = 1.0
		start_movement(!start_backwards)

func trigger_movement(_trigger_node: Node, direction: bool):
	start_movement(direction)

func start_movement(direction: bool = true) -> void:
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
		path_tween.tween_property(self, "current_progress", 1.0, path_time * (1 - current_progress)).set_delay(delay_duraction)
		return
	path_tween.tween_property(self, "current_progress", 0.0, path_time * current_progress).set_delay(delay_duraction)

func end_movement() -> void:
	path_tween.kill()
	movement_ended.emit()

func loop(_loop_count: int) -> void:
	finish_movement = true
	if current_direction:
		current_progress = 0.0
		return
	current_progress = 1.0

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or path_tween == null:
		return
	if movement_enabled:
		path.progress_ratio = current_progress
		movement_target.global_position = path.global_position
		movement_target.orthonormalize()
	if rotation_enabled:
		var rotation_offset = start_basis.rotated(AxisDict[rotation_axis_1], angle_1 * current_progress).rotated(AxisDict[rotation_axis_2], angle_2 * current_progress).get_euler()
		rotation_target.rotation = rotation_offset
		rotation_target.orthonormalize()
	if finish_movement:
		if movement_enabled: movement_target.reset_physics_interpolation()
		if rotation_enabled: rotation_target.reset_physics_interpolation()
		finish_movement = false
