@tool
class_name StateNode
extends Node

@export var transitions: Dictionary[String, StateNode]

var state_id: int = -1
var state_machine: StateMachine = null
var event: Signal
var target_node: Node

func setup(id: int, owner_machine: StateMachine, event_signal: Signal, target: Node):
	state_id = id
	state_machine = owner_machine
	event = event_signal
	target_node = target

func load_properties():
	return

func enter():
	return

func update(_delta: float):
	return

func phys_update(_delta: float):
	return

func exit():
	return
