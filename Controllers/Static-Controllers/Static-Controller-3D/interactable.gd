@tool
class_name Interactable
extends Area3D

static var highlight_tween: Tween

const HIGHLIGHT_DURATION := 0.1
const HOLD_SCALE := Vector2(0.9, 0.9)
const LERP_SPEED = 20.0

signal focus_changed(is_focused: bool)

@export_category("Highlight Properties")
@export var is_highlightable := false
@export var highlight_overlay: TextureRect
@export var highlight_scale: Vector2 = Vector2(1, 1)
@export var texture: Texture2D

var is_focused := false
var is_highlighted := false
var camera: Camera3D
var target_alpha := 1.0
var overlay_size := Vector2()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		highlight_overlay.scale = HOLD_SCALE
	elif event.is_action_released("interact"):
		highlight_overlay.scale = Vector2(1.0, 1.0)

func _ready() -> void:
	monitoring = false
	camera = get_viewport().get_camera_3d()
	if is_highlightable:
		focus_changed.connect(highlight)
		overlay_size = texture.get_size() * highlight_scale

func _process(delta: float) -> void:
	if not is_highlightable:
		return
	if is_highlighted:
		var target_position = camera.unproject_position(global_position) - (highlight_overlay.size * 0.5)
		highlight_overlay.position = lerp(highlight_overlay.position, target_position, LERP_SPEED * delta)

func hover() -> void:
	return

func focused() -> void:
	is_focused = true
	focus_changed.emit(true)

func unfocused() -> void:
	is_focused = false
	focus_changed.emit(false)

func highlight(highlighted: bool = true) -> void:
	is_highlighted = highlighted
	if is_highlighted:
		highlight_overlay.size = overlay_size
	modulate_highlight(Color(1, 1, 1, float(!highlighted)))
	highlight_overlay.position = camera.unproject_position(global_position) - (overlay_size * 0.5)
	highlight_overlay.pivot_offset = overlay_size * 0.5
	highlight_overlay.texture = texture
	if highlight_tween != null:
		highlight_tween.kill()
	highlight_tween = highlight_overlay.create_tween()
	var target_modulate: Color = Color(1, 1, 1, float(highlighted))
	highlight_tween.tween_method(modulate_highlight, highlight_overlay.modulate, target_modulate, HIGHLIGHT_DURATION)

func modulate_highlight(new_modulate: Color) -> void:
	highlight_overlay.modulate = new_modulate
