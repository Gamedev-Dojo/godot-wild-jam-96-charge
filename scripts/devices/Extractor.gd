class_name Extractor extends DeviceNode

func solve(beams: TNodeBeams) -> bool:
	if (beams.output.size()):
		return false
	
	var beam: TBeamInfo = TBeamInfo.new()
	beam.direction = direction

	beam.source = self
	
	beams.output.append(beam)
	return true
