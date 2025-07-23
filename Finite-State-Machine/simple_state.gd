#	Copyright JSVickers - See License
class_name SimpleState
extends RefCounted

#	A state that can be extended with the behavior of the state.
#	State ID should come from an enum within the owner of the state machine.
#	Properties for a state can be within the extended state itself, or using the properties dictionary
#	Properties / References shared between multiple states should use the state machine's properties instead.

var state_id: int
var owner_entity: Node
var state_properties: Dictionary[String, Variant]
var owner_state_machine: SimpleFSM

func _init(_owner: Node, _state: int, _owner_state_machine: SimpleFSM, _state_properties: Dictionary[String, Variant] = {}) -> void:
	state_id = _state
	owner_entity = _owner
	owner_state_machine = _owner_state_machine
	state_properties = _state_properties

func enter() -> void:
	return

func update(_delta: float) -> void:
	return

func exit() -> void:
	return

func set_property(property_name: String, property_value: Variant):
	state_properties[property_name] = property_value

func get_property(property_name: String) -> Variant:
	if state_properties.has(property_name):
		return state_properties[property_name]
	else:
		var error_string := "No " + property_name + " property found on state"
		assert(true, error_string)
		return error_string