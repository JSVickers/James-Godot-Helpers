#	Class to be extended with behaviour functions
#	Copyright JSVickers

class_name FSMBehaviours
extends RefCounted

#	These references allow simpler access to properties that may be used across behaviours
#	They also contain some common behaviours for ease of use
#	Any common event should use a negative number, so as to not overlap with other events
#	Note how data related to a state is stored in a dictionary referenced by the state ID
#	Data may also be stored using the state machine's set_data function

enum CommonEvents {
	NONE = -1,
	TIME_ELAPSED = -2
}

var owner_node: Node
var owner_state_machine: FunctionalFSM

var timers: Dictionary[int, float] = {}

#	Simple example of how data can be stored / accessed:

#class IdleStateData:
	#var how_long := 0.0
	#var name := "hello"

#var idle_data = IdleStateData.new()
#idle_data.how_long = 5.0
#idle_data.name = "Jim"
#owner_state_machine.set_data(idle_data)

#var fetched_idle_data: IdleStateData = owner_state_machine.get_data() as IdleStateData
#var current_name := fetched_idle_data.name

func _init(init_owner_node: Node, init_owner_state_machine: FunctionalFSM) -> void:
	owner_node = init_owner_node
	owner_state_machine = init_owner_state_machine

func do_nothing(_delta: float = 0.0) -> int:
	return CommonEvents.NONE

func timer(delta: float, time_to_wait: float = 0.0) -> int:
	if !timers.has(owner_state_machine.current_state_id):
		timers[owner_state_machine.current_state_id] = 0.0
	timers[owner_state_machine.current_state_id] += delta
	if timers[owner_state_machine.current_state_id] >= time_to_wait and !time_to_wait == 0.0:
		timers[owner_state_machine.current_state_id] = 0.0
		return CommonEvents.TIME_ELAPSED
	return CommonEvents.NONE

func reset_timer():
	timers[owner_state_machine.current_state_id] = 0.0
