# @ Copyright JSVickers - See License
class_name JamFSM
extends Node

const EMPTY_STATE_NAME := 'NONE'

signal event_triggered(event_id)
signal state_exited(state_name)
signal state_entered(state_name)

var state_dict: Dictionary[String, JamState]
var trans_dict: Dictionary[String, Dictionary]		#Inner dictionary is [Event_ID: To_State]
var current_state_name: String = EMPTY_STATE_NAME
var start_state_name: String = EMPTY_STATE_NAME
var shared_data: Variant = null

class JamState extends RefCounted:
	var state_machine: JamFSM = null
	var target_node_2d: Node2D = null
	var target_node_3d: Node3D = null
	func _init(in_state_machine: JamFSM, in_target_node: Node) -> void:
		if in_target_node is Node3D:
			target_node_3d = in_target_node
		else:
			target_node_2d = in_target_node
		state_machine = in_state_machine
	func enter():
		pass
	func update(_delta: float):
		pass
	func exit():
		pass

func _on_event_triggered(event_id: int):
	if trans_dict[current_state_name].has(event_id):
		transition(trans_dict[current_state_name][event_id])

func _set_current_state(new_state_unique_name: String):
	if current_state_name != EMPTY_STATE_NAME:
		state_dict[current_state_name].exit()
		state_exited.emit(current_state_name)
	current_state_name = new_state_unique_name
	state_dict[current_state_name].enter()
	state_entered.emit(current_state_name)

func _ready() -> void:
	event_triggered.connect(_on_event_triggered)
	_set_current_state(start_state_name)

func add_state(state_unique_name: String, state_object: JamState, is_start_state := false):
	if state_dict.has(state_unique_name):
		print_debug('State ' + state_unique_name + ' already exists in state machine')
		return
	state_dict[state_unique_name] = state_object
	trans_dict[state_unique_name] = {}
	if is_start_state or start_state_name == EMPTY_STATE_NAME:
		start_state_name = state_unique_name

func update_state(state_unique_name: String, state_object: JamState):
	if !state_dict.has(state_unique_name):
		print_debug('State ' + state_unique_name + ' does not exist in state machine')
		return
	state_dict[state_unique_name] = state_object

func set_shared_data(new_shared_data: Variant):
	shared_data = new_shared_data

func get_shared_data() -> Variant:
	if shared_data == null:
		print_debug("State machine contains no shared data")
		return null
	return shared_data

func add_transition(state_from_unique_name: String, event_id: int, state_to_unique_name: String):
	if trans_dict.has(state_from_unique_name):
		if trans_dict[state_from_unique_name].has(event_id):
			print_debug('State ' + state_from_unique_name + ' already has a transition for event, overwriting.')
	trans_dict[state_from_unique_name][event_id] = state_to_unique_name

func tick(delta: float) -> void:		#Must be called from the parent node
	state_dict[current_state_name].update(delta)

func transition(new_state_unique_name: String):		#Move to another state
	if !state_dict.has(new_state_unique_name):
		print_debug('State ' + new_state_unique_name + ' does not exist in state machine')
		return
	_set_current_state(new_state_unique_name)

func trigger_event(event_id: int):
	event_triggered.emit(event_id)
