class_name ConditionRampUpState
extends ConditionState


signal ramp_up_finished



var _scale = 0.1


func init_state():
	pass
	

func on_enter_state():
	pass


func on_process(_delta):
	_scale = lerp(_scale, 1.0, _delta)
	#Log.d("Scale = %f" % _scale)
	condition_view.scale = Vector3(_scale, _scale, _scale)
	
	if _scale >= 0.9:
		ramp_up_finished.emit()
		
