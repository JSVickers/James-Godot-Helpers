#	Copyright JSVickers - See License
class_name SimpleState
extends RefCounted

#	A state that can be extended with the behavior of the state.
#	State ID should come from an enum within the owner of the state machine.
#	Properties for a state can be within the extended state itself, or using the properties dictionary
#	Properties / References shared between multiple states should use the state machine's properties instead.

var state_id: int
var owner_entity: Node
var owner_state_machine: SimpleFSM

func _init(_owner: Node, _state: int, _owner_state_machine: SimpleFSM) -> void:
	state_id = _state
	owner_entity = _owner
	owner_state_machine = _owner_state_machine

func enter() -> void:
	return

func update(_delta: float) -> void:
	return

func phys_update(_delta: float) -> void:
	return

func exit() -> void:
	return
