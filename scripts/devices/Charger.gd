class_name Charger extends DeviceNode

var is_powered = false

func apply(beams: TNodeBeams):
	var should_be_powered = beams.input.size() > 0
	if should_be_powered != is_powered:
		is_powered = should_be_powered
		Game.s_set_finished(self, is_powered)
		
