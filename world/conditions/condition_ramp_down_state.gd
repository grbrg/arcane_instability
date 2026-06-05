class_name ConditionRampDownState
extends ConditionState


signal ramp_down_finished



var _scale = 1.0


func init_state():
	pass
	

func on_enter_state():
	pass


func on_process(_delta):
	_scale = lerp(_scale, 0.0, _delta)
	#Log.d("Scale = %f" % _scale)
	condition_view.scale = Vector3(_scale, _scale, _scale)
	
	if _scale <= 0.1:
		ramp_down_finished.emit()
		
