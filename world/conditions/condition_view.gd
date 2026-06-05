class_name ConditionView
extends Node3D




var ramp_up_state: ConditionRampUpState
var running_state: ConditionRunningState
var ramp_down_state: ConditionRampDownState

var state_machine: StateMachine




##
func _init() -> void:

	state_machine = StateMachine.new()

	ramp_up_state = ConditionRampUpState.new(self)
	state_machine.add_state(ramp_up_state)

	running_state = ConditionRunningState.new(self)
	state_machine.add_state(running_state)

	ramp_down_state = ConditionRampDownState.new(self)
	state_machine.add_state(ramp_down_state)

	ramp_up_state.ramp_up_finished.connect(state_machine.change_to_state.bind(running_state))
	ramp_down_state.ramp_down_finished.connect(on_ramp_down_finished)

	state_machine.init()
	add_child(state_machine)


func on_ramp_down_finished() -> void:
	get_parent().remove_child(self)
	queue_free()


##
func ramp_down() -> void:
	state_machine.change_to_state(ramp_down_state)


