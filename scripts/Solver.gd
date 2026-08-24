class_name Solver

# ==============================================================================
static func _static_init():
	pass
	
# ==============================================================================
static func solve(nodes : Dictionary[Vector2i, DeviceNode]) -> void:
	# create empty solution
	var solution: Dictionary[DeviceNode, TNodeBeams]
	for node in nodes.values():
		solution[node] = TNodeBeams.new()
	
	# solve until everything is set
	var finished = false
	while not finished:
		finished = true
		for node in solution:
			var changed = node.solve(solution[node])
			if changed:
				finished = false
				for beam in solution[node].output:
					if (beam.is_new):
						beam.is_new = false
						beam.target = _find_target(beam.source.my_pos, beam.direction, nodes)
						if beam.target:
							solution[beam.target].input.append(beam)
							
	# apply solution to nodes
	for node in nodes.values():
		node.apply(solution[node])

	return

# ==============================================================================
static func _find_target(source: Vector2i, direction: Vector2i, nodes: Dictionary[Vector2i, DeviceNode]) -> DeviceNode:
	var pos := source + direction
	var dist = 1
	while dist < 21:
		if nodes.has(pos):
			return nodes[pos]
		pos += direction
		dist += 1
	return null

# ==============================================================================
