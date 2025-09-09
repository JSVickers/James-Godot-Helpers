class_name StaticController2D
extends Node2D

signal interactable_focused(interactable: Interactable2D)
signal interactable_unfocused(interactable: Interactable2D)

@export var gamepad_sensitivity := 1000.0

var gamepad_enabled := false
var focused_interactable: Interactable2D
var target_locked := false

func _ready() -> void:
	interactable_focused.connect(_on_interactable_focused)
	interactable_unfocused.connect(_on_interactable_unfocused)

func _process(delta: float) -> void:
	if gamepad_enabled:
		var delta_motion := get_gamepad_motion() * delta
		var new_mouse_position := get_viewport().get_mouse_position() + delta_motion
		get_viewport().warp_mouse(new_mouse_position)

func _physics_process(delta: float) -> void:
	var hovered_interactable: Interactable2D = get_interactable_at_position(get_viewport().get_mouse_position())
	var changed_focus := hovered_interactable != focused_interactable
	if not target_locked and hovered_interactable != null and changed_focus:
		interactable_unfocused.emit(focused_interactable)
		interactable_focused.emit(hovered_interactable)
	elif not target_locked and hovered_interactable == null and changed_focus:
		interactable_unfocused.emit(focused_interactable)
	focused_interactable = hovered_interactable

func get_gamepad_motion() -> Vector2:
	var stick_direction := Input.get_vector("cursor_left", "cursor_right", "cursor_up", "cursor_down")
	return stick_direction * gamepad_sensitivity

func get_interactable_at_position(pos: Vector2) -> Interactable2D:
	var space_2d := get_world_2d().direct_space_state
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.collide_with_areas = true
	point_query.collide_with_bodies = false
	point_query.position = pos
	var result := space_2d.intersect_point(point_query, 1)
	if result.is_empty():
		return null
	return result[0]["collider"] as Interactable2D

func _on_interactable_focused(interactable: Interactable2D):
	interactable.focus(self)

func _on_interactable_unfocused(interactable: Interactable2D):
	interactable.unfocus(self)
