# @ Copyright JSVickers - See License
extends Node2D

@export var detection_distance := 100.0
@export var label: Label
@export var count_down_from := 20.0

var state_machine: JamFSM
@onready var marker: Node2D = $Marker2D

enum Events{
	TIME_ELAPSED,
	MOUSE_ENTERED,
	MOUSE_EXITED,
}

enum ExampleState{
	COUNT_UP,
	COUNT_DOWN,
}

var states: Dictionary[ExampleState, String] = {
	ExampleState.COUNT_UP: 'Count Up',
	ExampleState.COUNT_DOWN: 'Count Down',
}

class ExampleSharedData extends RefCounted:
	var label_to_change: Label
	var distance_to_detect: float = 200.0
	func _init(in_label: Label, in_distance: float) -> void:
		label_to_change = in_label
		distance_to_detect = in_distance

class CountingUpState extends JamFSM.JamState:
	var current_time := 0.0
	var detection_distance: float
	var label: Label
	func _init(sm: JamFSM, target: Node) -> void:
		super(sm, target)
		detection_distance = sm.get_shared_data().distance_to_detect
		label = sm.get_shared_data().label_to_change
	func update(delta: float):
		current_time += delta
		label.text = str(snappedf(current_time, 0.1))
		var mouse_distance := target_node_2d.global_position.distance_to(target_node_2d.get_viewport().get_mouse_position())
		if mouse_distance <= detection_distance:
			return state_machine.trigger_event(Events.MOUSE_ENTERED)

class CountingDownState extends JamFSM.JamState:
	var current_time := 0.0
	var count_from := 30.0
	var detection_distance: float
	var label: Label
	func _init(sm: JamFSM, target: Node, in_count_from: float) -> void:
		super(sm, target)
		count_from = in_count_from
		detection_distance = sm.get_shared_data().distance_to_detect
		label = sm.get_shared_data().label_to_change
	func enter():
		current_time = 0.0
	func update(delta: float):
		current_time += delta
		var remaining := count_from - current_time
		label.text = str(snappedf(remaining, 0.1))
		if remaining <= 0:
			return state_machine.trigger_event(Events.TIME_ELAPSED)
		var mouse_distance := target_node_2d.global_position.distance_to(target_node_2d.get_viewport().get_mouse_position())
		if mouse_distance > detection_distance:
			return state_machine.trigger_event(Events.MOUSE_EXITED)

func _ready() -> void:
	var shared_state_data: ExampleSharedData = ExampleSharedData.new(label, detection_distance)
	state_machine = JamFSM.new()
	state_machine.set_shared_data(shared_state_data)
	var count_up_state := CountingUpState.new(state_machine, marker)
	var count_down_state := CountingDownState.new(state_machine, marker, count_down_from)
	state_machine.add_state(states[ExampleState.COUNT_UP], count_up_state, true)
	state_machine.add_state(states[ExampleState.COUNT_DOWN], count_down_state)
	state_machine.add_transition(states[ExampleState.COUNT_UP], Events.MOUSE_ENTERED, states[ExampleState.COUNT_DOWN])
	state_machine.add_transition(states[ExampleState.COUNT_DOWN], Events.MOUSE_EXITED, states[ExampleState.COUNT_UP])
	state_machine.add_transition(states[ExampleState.COUNT_DOWN], Events.TIME_ELAPSED, states[ExampleState.COUNT_UP])
	add_child(state_machine)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
