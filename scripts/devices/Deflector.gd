class_name Deflector extends DeviceNode

func solve(beams: TNodeBeams) -> bool:
	if (beams.input.size() == 0):
		return false
	if (beams.output.size()):
		return false
	
	var beam: TBeamInfo = TBeamInfo.new()
	beam.direction = direction
	beam.source = self	
	beams.output.append(beam)

	return true
