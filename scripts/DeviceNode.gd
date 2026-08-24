class_name DeviceNode extends Node3D

var direction := Vector2i.UP


var my_pos: Vector2i:
	get:
		return Vector2i(round(position.x), round(position.z))
var vpos: Vector2i:
	get:
		return Vector2i(round(position.x), round(position.z))
	
func solve(_beams: TNodeBeams) -> bool:
	return false
	
func apply(beams: TNodeBeams):
	# remove current beams
	for child in get_children():
		if child is Beam:
			child.queue_free()
	
	# create new beams
	for beam_info in beams.output:		
		var beam_node = load("res://scenes/Beam.tscn").instantiate()
		add_child(beam_node)
		beam_node.setup(beam_info)
		
func set_dragging(is_dragging: bool):
	if is_dragging:
		apply(TNodeBeams.new())
	scale =  (0.8 if is_dragging else 1.0) * Vector3.ONE
	pass

func get_beams(in_beams: Array[TBeamInfo]) -> Array[TBeamInfo]:
	return []

func handle_click() -> void:
	set_direction(Vector2i(Vector2(direction).rotated(-PI / 4).round()))

func set_direction(new_direction: Vector2i) -> void:
	direction = new_direction
	look_at(global_position + Vector3(direction.x, 0, direction.y))


# @export var delay = 1000.0
# @export var ChargeTemplate : PackedScene = null

# var last_spawn_time = 0
# # Called when the node enters the scene tree for the first time.
# # func _ready() -> void:
# # 	spawn()

# # func _process(_delta: float) -> void:
# # 	var curr_time = Time.get_ticks_msec()
# # 	if (curr_time - last_spawn_time > delay):
# # 		spawn()

# # func spawn() -> void:
# # 	return
# # 	last_spawn_time = Time.get_ticks_msec()
# # 	var instance = ChargeTemplate.instantiate()
# # 	instance.position = self.position
# # 	get_parent().add_child.call_deferred(instance)
