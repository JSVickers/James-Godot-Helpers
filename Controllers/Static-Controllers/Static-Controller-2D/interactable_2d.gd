class_name Interactable2D
extends Area2D

signal focus_changed(focused: bool)

@export var sprite: Node2D
@export var highlight_material: Material
@export var is_dragable := false

var focused := false
var original_material: Material

func _ready() -> void:
	monitoring = false
	original_material = sprite.material

func focus(node: Node) -> void:
	change_focus(true)

func unfocus(node: Node) -> void:
	change_focus(false)

func change_focus(focus: bool) -> void:
	focused = focus
	focus_changed.emit(focused)
	if sprite is AnimatedSprite2D:
		var animated_sprite := sprite as AnimatedSprite2D
		animated_sprite.play() if focused else animated_sprite.stop()
	if highlight_material != null:
		sprite.material = highlight_material if focused else original_material
