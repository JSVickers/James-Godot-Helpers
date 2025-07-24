@tool
class_name StateMachine
extends Node

signal fire_event(event_name)

@export var target_node: Node
@export var start_state: StateNode
@export var persistent_properties: StateMachineProperties

var current_state: StateNode = null: set = set_current_state

func set_current_state(new_state: StateNode):
	if current_state != null:
		current_state.exit()
	if new_state != null:
		current_state = new_state
		current_state.enter()

func _on_fire_event(event_name: String):
	if current_state.transitions.has(event_name):
		var new_state := current_state.transitions[event_name]
		set_current_state(new_state)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	fire_event.connect(_on_fire_event)
	for node in get_children():
		assert(node is StateNode, "Child node of state machine must be a state node")
		var state_node = node as StateNode
		state_node.setup(
			state_node.get_index(),
			self,
			fire_event,
			target_node
		)
		state_node.load_properties()
	set_current_state(start_state)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		current_state.phys_update(delta)
