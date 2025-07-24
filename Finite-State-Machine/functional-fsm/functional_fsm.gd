#	State machine that only uses callables, rather than state objects
#	Copyright JSVickers

class_name FunctionalFSM
extends RefCounted

#	Same logic as a regular state machine
#	Shifted to be a struct of arrays, rather than an array of structs
#	Update funcs must return a string (Which contains an event name)

var state_names: Dictionary[String, int] = {}
var entry_funcs: Array[Callable] = []
var update_funcs: Array[Callable] = []
var exit_funcs: Array[Callable] = []
var transitions: Array[Dictionary] = []
var state_datas: Dictionary[int, Variant] = {}

var current_state_id: int = -1
var current_state_name: String = ""

func update(delta: float) -> void:
	var curr_event := -1
	if current_state_id >= 0:
		curr_event = update_funcs[current_state_id].call(delta)
	if curr_event != -1:
		fire_event(curr_event)

func set_current_state(new_state_name: String) -> void:
	if current_state_id != -1:
		exit_funcs[current_state_id].call()
	var new_state_id = state_names[new_state_name]
	current_state_id = new_state_id
	current_state_name = new_state_name
	entry_funcs[new_state_id].call()

func add_state(state_name: String, enter_func: Callable, update_func: Callable, exit_func: Callable, state_transitions: Dictionary[int, String], state_data: Variant = null) -> void:
	var state_id := state_names.size()
	state_names[state_name] = state_id
	entry_funcs.append(enter_func)
	update_funcs.append(update_func)
	exit_funcs.append(exit_func)
	transitions.append(state_transitions)
	if state_data != null:
		state_datas[state_id] = state_data

func fire_event(event_id: int) -> void:
	var state_transitions: Dictionary[int, String] = transitions[current_state_id]
	var new_state_name = ""
	if state_transitions.has(event_id):
		new_state_name = state_transitions[event_id]
	if new_state_name != "":
		set_current_state(new_state_name)

func get_data(for_state: String = "") -> Variant:
	var data_id = current_state_id
	if for_state != "":
		if !state_names.has(for_state):
			return "State does not exist"
		data_id = state_names[for_state]
	if !state_datas.has(data_id):
		return "No data for state found"
	return state_datas[data_id]

func set_data(new_data: Variant, for_state: String = "") -> void:
	var data_id = current_state_id
	if for_state != "":
		if !state_names.has(for_state):
			return
		data_id = state_names[for_state]
	state_datas[data_id] = new_data
