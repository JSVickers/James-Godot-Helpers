class_name StaticController
extends Node3D

signal changed_focus(previous_node: Interactable, new_node: Interactable)

const INTERACT_RANGE := 5000.0

enum InputMode {
	MOUSE,
	GAMEPAD
}

@export var joystick_sensitivity := 1000.0

@onready var camera: Camera3D = %MainCamera as Camera3D

var input_mode: InputMode = InputMode.MOUSE
var cursor_img := load("res://cursor.png")
var active_node: Interactable: set = _set_active_node
var is_using_v_cursor := false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate_gamepad"):
		input_mode == InputMode.GAMEPAD
	elif event is InputEventMouseButton:
		input_mode == InputMode.MOUSE
	if event is InputEventJoypadMotion and input_mode == InputMode.GAMEPAD:
		var motion := event as InputEventJoypadMotion
		var movement := Vector2()
		if motion.axis == JOY_AXIS_LEFT_X:
			movement.x = motion.axis_value
		if motion.axis == JOY_AXIS_LEFT_Y:
			movement.y = motion.axis_value
		var mouse_pos := get_viewport().get_mouse_position()
		get_viewport().warp_mouse(mouse_pos + (movement * joystick_sensitivity))

func _set_active_node(new_node: Interactable):
	if active_node == new_node:
		return
	changed_focus.emit(active_node, new_node)
	active_node = new_node

func _init() -> void:
	Input.set_custom_mouse_cursor(cursor_img)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _ready() -> void:
	changed_focus.connect(_on_changed_focus)

func _physics_process(delta: float) -> void:
	if !is_using_v_cursor: active_node = get_object_at_cursor()
	if active_node != null:
		active_node.hover()

func get_joystick_movement() -> Vector2:
	var joystick_x := Input.get_axis("v_cursor_left", "v_cursor_right")
	var joystick_y := Input.get_axis("v_cursor_up", "v_cursor_down")
	var joystick_movement := Vector2(joystick_x, joystick_y) * joystick_sensitivity
	return joystick_movement

func get_object_at_cursor() -> Interactable:
	var space_state := get_world_3d().direct_space_state
	var ray_start := camera.project_ray_origin(get_viewport().get_mouse_position())
	var ray_end := ray_start + camera.project_ray_normal(get_viewport().get_mouse_position()) * INTERACT_RANGE
	var ray_query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = false
	var result := space_state.intersect_ray(ray_query)
	if result.is_empty():
		return null
	var hit := result["collider"] as Interactable
	if hit == null:
		return null
	if hit == active_node:
		return active_node
	return hit

func _on_changed_focus(previous_node: Interactable, new_node: Interactable) -> void:
	if previous_node != null:
		previous_node.unfocused()
	if new_node != null:
		new_node.focused()
