# @ Copyright JSVickers - See License
class_name JamFSM
extends Node

const EMPTY_STATE := -1

signal event_triggered(event_id)
signal state_exited(state_name)
signal state_entered(state_name)

var states : Array[JamState]
var transitions: Array[Dictionary]
var current_state: int = EMPTY_STATE
var start_state: int = EMPTY_STATE
var shared_data: Variant = null
var state_ids: Dictionary[String, int]

class JamState extends RefCounted:
	var state_name: String = ''
	var state_machine: JamFSM = null
	var target_node_2d: Node2D = null
	var target_node_3d: Node3D = null
	var state_id: int = -1
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
	func input_event(_event: InputEvent):
		pass

func _on_event_triggered(event_id: int):
	if transitions[current_state].has(event_id):
		transition(transitions[current_state][event_id])

func _set_current_state(new_state: int):
	if current_state != EMPTY_STATE:
		states[current_state].exit()
		state_exited.emit(current_state)
	current_state = new_state
	states[current_state].enter()
	state_entered.emit(current_state)

func _ready() -> void:
	event_triggered.connect(_on_event_triggered)
	_set_current_state(start_state)

func add_state(unique_state_name: String, state_object: JamState):
	var name_already_used = state_ids.has(unique_state_name)
	assert(!name_already_used, 'State ID is already in use in state machine.')
	if name_already_used:
		return
	state_object.state_id = states.size()
	state_object.state_name = unique_state_name
	state_ids[unique_state_name] = states.size()
	states.append(state_object)
	transitions.append({})
	if start_state == EMPTY_STATE:
		start_state = states.size()

func set_start_state(state_id: int):
	var state_is_valid := state_id < states.size() and state_id > -1
	assert(state_is_valid, 'State ' + str(state_id) + ' is an invalid start state.')
	if state_is_valid:
		start_state = state_id

func get_current_state() -> JamState:
	return states[current_state]

func update_state(state_id: int, new_state_object: JamState):
	var state_is_valid := state_id < states.size() and state_id > -1
	assert(state_is_valid, 'State ' + str(state_id) + ': ' + str(new_state_object) + ' is invalid.')
	if state_is_valid:
		states[state_id] = new_state_object

func set_shared_data(new_shared_data: Variant):
	shared_data = new_shared_data

func get_shared_data() -> Variant:
	if shared_data == null:
		print_debug("State machine contains no shared data")
		return null
	return shared_data

func get_state_id(state_unique_name: String) -> int:
	if state_ids.has(state_unique_name):
		return state_ids[state_unique_name]
	return -1

func add_transition(state_from: int, state_to: int, event: int):
	if transitions[state_from].has(event):
		print_debug('State ' + str(state_from) + ' already has a transition for event, overwriting.')
	transitions[state_from][event] = state_to

func tick(delta: float) -> void:
	states[current_state].update(delta)

func transition(new_state: int):
	if states[new_state] == null:
		print_debug('State ' + str(new_state) + ' does not exist in state machine')
		return
	_set_current_state(new_state)

func trigger_event(event_id: int):
	event_triggered.emit(event_id)

func pass_input_event(event: InputEvent):
	states[current_state].input_event(event)
