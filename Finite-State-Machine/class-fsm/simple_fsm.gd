#	Copyright JSVickers - See License
@tool
class_name SimpleFSM
extends Node

# State machine can be added directly in code, or as a node.
# States must be created in code and added to the state machine using add_state
# States and Events should use an enum to determine their ID's (No strings supported)
# Transitions happen when an appropriate event is fired using fire_event
# Events may be fired from anywhere

signal state_entered(state)
signal state_exited(state)

enum Status {
	STOPPED,
	PAUSED,
	RUNNING
}

var current_status: Status = Status.STOPPED

class Transition:
	var to_state: int
	var event: int

var states: Dictionary[int, SimpleState]
var transitions: Dictionary[int, Array]

var current_state := -1: set = set_current_state
var running := false

func set_current_state(new_state: int):
	if current_state != -1:
		states[current_state].exit()
		state_exited.emit(current_state)
	current_state = new_state
	if current_state != -1:
		states[current_state].enter()
		state_entered.emit(current_state)

func add_state(state: SimpleState):
	states[state.state_id] = state

func add_transition_for_state(state_from: int, state_to: int, event: int):
	var transition: Transition = Transition.new()
	transition.to_state = state_to
	transition.event = event
	if !transitions.has(state_from):
		transitions[state_from] = [transition]
	else:
		transitions[state_from].append(transition)

func start(start_state: int) -> void:
	set_current_state(start_state)
	current_status = Status.RUNNING
	running = true

func pause() -> void:
	current_status = Status.PAUSED
	running = false

func stop() -> void:
	set_current_state(-1)
	current_status = Status.STOPPED
	running = false

func resume() -> void:
	current_status = Status.RUNNING
	running = true

func stop_and_clear() -> void:
	running = false
	set_current_state(-1)
	states = {}
	transitions = {}

func fire_event(event: int):
	if !running:
		return
	if transitions.has(current_state):
		var state_transitions := transitions[current_state]
		for transition in state_transitions:
			transition = transition as Transition
			if transition.event == event:
				set_current_state(transition.to_state)

func _process(delta: float) -> void:
	if !running:
		return
	if current_state != -1:
		states[current_state].update(delta)

func _physics_process(delta: float) -> void:
	if !running:
		return
	if current_state != -1:
		states[current_state].phys_update(delta)
