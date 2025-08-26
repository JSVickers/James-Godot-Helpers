@tool
class_name Interactor
extends Area3D

const HIGHLIGHT_TIME := 0.2

signal state_changed(triggered_by: Node, new_status: bool)

@export var highlight_mat: ShaderMaterial
@export var mesh_instances: Array[MeshInstance3D]
@export var is_active := false: set = set_is_active
@export var is_highlighted := false: set = set_is_highlighted

var highlight_tween: Tween
var triggered_by: Node

func set_is_highlighted(highlighted: bool):
	is_highlighted = highlighted
	if highlight_mat == null or mesh_instances.is_empty():
		return
	var current_alpha: float = highlight_mat.get_shader_parameter("alpha")
	if highlight_tween != null:
		highlight_tween.kill()
	highlight_tween = create_tween()
	var target_alpha := 1.0
	var highlight_time := HIGHLIGHT_TIME * (1.0 - current_alpha)
	if is_highlighted:
		for mesh in mesh_instances:
			trigger_overlay(mesh, true)
	else:
		target_alpha = 0.0
		highlight_time = HIGHLIGHT_TIME * current_alpha
		highlight_tween.finished.connect(func():
			for mesh in mesh_instances:
				trigger_overlay(mesh, false)
			highlight_tween.kill()
		)
	highlight_tween.tween_method(set_material_alpha, current_alpha, target_alpha, highlight_time)

func set_is_active(value: bool):
	is_active = value
	state_changed.emit(triggered_by, is_active)
	triggered_by = null

func set_material_alpha(alpha: float) -> void:
	highlight_mat.set_shader_parameter("alpha", alpha)

func _init() -> void:
	monitoring = false

func interact(interaction_triggered_by: Node, value: int = -1) -> void:
	triggered_by = interaction_triggered_by
	if value == -1:
		set_is_active(not is_active)
		return
	if value == 0: set_is_active(false)
	if value == 1: set_is_active(true)

func trigger_overlay(mesh: MeshInstance3D, value: bool):
	if value:
		mesh.material_overlay = highlight_mat
		return
	mesh.material_overlay = null
	return
