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

class ExampleSharedData extends RefCounted:
	var label_to_change: Label
	var distance_to_detect: float = 200.0
	func _init(in_label: Label, in_distance: float) -> void:
		label_to_change = in_label
		distance_to_detect = in_distance

class ExampleBaseState extends JamFSM.JamState:
	var shared_data: ExampleSharedData
	func _init(sm: JamFSM, target: Node) -> void:
		super(sm, target)
		shared_data = sm.get_shared_data() as ExampleSharedData

class CountingUpState extends ExampleBaseState:
	var current_time := 0.0
	func update(delta: float):
		current_time += delta
		shared_data.label_to_change.text = str(snappedf(current_time, 0.1))
		var mouse_distance := target_node_2d.global_position.distance_to(target_node_2d.get_viewport().get_mouse_position())
		if mouse_distance <= shared_data.distance_to_detect:
			return state_machine.trigger_event(Events.MOUSE_ENTERED)

class CountingDownState extends ExampleBaseState:
	var current_time := 0.0
	var count_from := 30.0
	func _init(sm: JamFSM, target: Node, in_count_from: float) -> void:
		super(sm, target)
		count_from = in_count_from
	func enter():
		current_time = 0.0
	func update(delta: float):
		current_time += delta
		var remaining := count_from - current_time
		shared_data.label_to_change.text = str(snappedf(remaining, 0.1))
		if remaining <= 0:
			return state_machine.trigger_event(Events.TIME_ELAPSED)
		var mouse_distance := target_node_2d.global_position.distance_to(target_node_2d.get_viewport().get_mouse_position())
		if mouse_distance > shared_data.distance_to_detect:
			return state_machine.trigger_event(Events.MOUSE_EXITED)

func _ready() -> void:
	var shared_state_data: ExampleSharedData = ExampleSharedData.new(label, detection_distance)
	state_machine = JamFSM.new()
	state_machine.set_shared_data(shared_state_data)
	var count_up := CountingUpState.new(state_machine, marker)
	var count_down := CountingDownState.new(state_machine, marker, count_down_from)
	state_machine.add_state('Count Up', count_up)
	state_machine.add_state('Count Down', count_down)
	state_machine.set_start_state(count_up.state_id)
	state_machine.add_transition(count_up.state_id, count_down.state_id, Events.MOUSE_ENTERED)
	state_machine.add_transition(count_down.state_id, count_up.state_id, Events.MOUSE_EXITED)
	state_machine.add_transition(count_down.state_id, count_up.state_id, Events.TIME_ELAPSED)
	add_child(state_machine)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
