class_name Hazard extends DeviceNode

var is_raised = false

func apply(beams: TNodeBeams):
	var should_be_raised = beams.input.size() > 0
	if should_be_raised != is_raised:
		is_raised = should_be_raised
		Game.s_raise_alarm(self, is_raised)
		