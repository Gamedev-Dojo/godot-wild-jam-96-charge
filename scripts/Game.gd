class_name Game extends Node3D

static var s_alarms : Array[DeviceNode]
static var s_finished : Array[DeviceNode]

static var s_set_scene = "TutorialStart"
var curr_scene: Node3D

var deviceLibrary: Array[String] = [
	"res://scenes/devices/Extractor.tscn",
	"res://scenes/devices/Charger.tscn",
	"res://scenes/devices/Deflector.tscn",
	"res://scenes/devices/Splitter.tscn",
	"res://scenes/devices/Obstacle.tscn",
	"res://scenes/devices/Hazard.tscn",
]

var nodes : Dictionary[Vector2i, DeviceNode]
var currDeviceIdx : int = 0

var pressed_device: DeviceNode = null
enum MODE { IDLE, PLACING, REMOVING, DRAGGING }
var mode = MODE.IDLE
var is_dragging: bool = false
var last_vpos: Vector2i
var press_time: float

var plane:Plane
var alarm_timer: Timer
var finished_timer: Timer

# ==============================================================================
func _ready() -> void:
	curr_scene = $TutorialStart
	
	plane = Plane(Vector3.UP, Vector3.ZERO)

	alarm_timer = Timer.new()
	add_child(alarm_timer)
	alarm_timer.wait_time = 1.0
	alarm_timer.one_shot = true
	alarm_timer.timeout.connect(handle_alarm)

	finished_timer = Timer.new()
	add_child(finished_timer)
	finished_timer.wait_time = 1.0
	finished_timer.one_shot = true
	finished_timer.timeout.connect(handle_finished)

	load_state("res://gamestate.dat")


# ==============================================================================
func _process(_delta: float) -> void:
	if (curr_scene.name != s_set_scene):
		set_scene_internal()

	process_alarms()
	process_finished()

	# Determine vpos
	var camera = get_viewport().get_camera_3d()
	var world_pos = plane.intersects_ray(
		camera.project_ray_origin(get_viewport().get_mouse_position()),
		camera.project_ray_normal(get_viewport().get_mouse_position()))
	if not world_pos:
		return
	var vpos = Vector2i(round(world_pos.x), round(world_pos.z))
	
	var mouse_device: DeviceNode = nodes.get(vpos)

	# Left mouse button
	if Input.is_action_just_pressed("left_mouse"):
		if mouse_device:
			press_time = Time.get_ticks_msec()
			pressed_device = mouse_device
	
	if Input.is_action_just_released("left_mouse"):
		if mode == MODE.IDLE and pressed_device:
			mouse_device.handle_click()
			Solver.solve(nodes)
		elif mode == MODE.DRAGGING:
			pressed_device.set_dragging(false)
			nodes.set(vpos, pressed_device)
			Solver.solve(nodes)

		pressed_device = null
		mode = MODE.IDLE

	# Middle mouse button
	if Input.is_action_just_pressed("middle_mouse"):
		if not mouse_device and mode == MODE.IDLE:
			mode = MODE.PLACING
			device_place(vpos, deviceLibrary[currDeviceIdx])
			Solver.solve(nodes)

	if Input.is_action_just_released("middle_mouse"):
		if mode == MODE.PLACING:
			mode = MODE.IDLE

		pressed_device = null
		mode = MODE.IDLE

	# Right mouse button
	if Input.is_action_just_pressed("right_mouse") and mouse_device:
		if mouse_device:
			mode = MODE.REMOVING
			device_remove(vpos)
			Solver.solve(nodes)

	if Input.is_action_just_released("right_mouse"):
		mode = MODE.IDLE

	# Mouse move
	if last_vpos != vpos:
		if mode == MODE.PLACING:
			if mouse_device:
				device_remove(vpos)
			device_place(vpos, deviceLibrary[currDeviceIdx])
			Solver.solve(nodes)
		elif mode == MODE.REMOVING:
			if mouse_device:
				device_remove(vpos)
				Solver.solve(nodes)

	# Drag device
	if pressed_device and mode == MODE.IDLE and (vpos != last_vpos or (Time.get_ticks_msec() - press_time > 1000.0)):
		mode = MODE.DRAGGING
		nodes.erase(pressed_device.vpos)
		pressed_device.set_dragging(true)
		Solver.solve(nodes)

	if mode == MODE.DRAGGING and last_vpos != vpos:
		pressed_device.position = Vector3(vpos.x, 0, vpos.y)

	# Select device for placement
	var new_device_idx = -1
	for key in range(KEY_1, KEY_6 + 1):
		if Input.is_key_pressed(key):
			new_device_idx = key - KEY_1
	if new_device_idx >=0:
		currDeviceIdx = wrap(new_device_idx, 0, deviceLibrary.size())

	# Prev / Next scene
	if Input.is_action_just_pressed("camera_left"):
		next_scene(-1)
	elif Input.is_action_just_pressed("camera_right"):
		next_scene()

	# Load / Save
	if Engine.is_embedded_in_editor() and Input.is_action_just_pressed("load"):
		load_state()
	if Engine.is_embedded_in_editor() and Input.is_action_just_pressed("save"):
		save_state()
	
	# Store vpos
	last_vpos = vpos

# ==============================================================================
#  Creative mode
# ==============================================================================
func device_place(vpos : Vector2i, device_scene: String):
	var s = load(device_scene)
	var i = s.instantiate()
	add_child(i)
	i.position = Vector3(vpos.x, 0, vpos.y)
	
	nodes.set(vpos, i)

	return i

# ==============================================================================
func device_remove(vpos):
	nodes[vpos].queue_free()
	nodes.erase(vpos)

# ==============================================================================
#  Scene management
# ==============================================================================
static func set_scene(scene_name):
	if not scene_name.is_empty():
		s_set_scene = scene_name

# ------------------------------------------------------------------------------
func next_scene(offset = 1):
	var scene_order = [
		"TutorialStart", "Tutorial",
		"Level1Start", "Level1",
		"Level2Start", "Level2",
		"Level3Start", "Level3",
	]
	var curr_idx = scene_order.find(curr_scene.name)
	if (curr_idx != -1):
		s_set_scene = scene_order[curr_idx + offset]

# ------------------------------------------------------------------------------
func _on_back_pressed() -> void:
	next_scene(-1)

# ------------------------------------------------------------------------------
func set_scene_internal():
	if has_node("CanvasLayer/" + curr_scene.name):
		get_node("CanvasLayer/" + curr_scene.name).visible = false

	curr_scene = get_node("/root/Main/" + s_set_scene)

	var camera = get_viewport().get_camera_3d()
	var target_pos = curr_scene.position + Vector3.UP * camera.position.y
	var target_rot = curr_scene.rotation_degrees + Vector3(-90, 0, 0)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD)
	var trans_duration = 1.0
	tween.tween_property(camera, "position", target_pos, trans_duration)
	tween.tween_property(camera, "rotation_degrees", target_rot, trans_duration)
	tween.finished.connect(on_scene_start)

func on_scene_start():
	if has_node("CanvasLayer/" + curr_scene.name):
		get_node("CanvasLayer/" + curr_scene.name).visible = true

# ==============================================================================
#  Hazards and alert
# ==============================================================================
static func s_raise_alarm(node, is_raised):
	if is_raised:
		s_alarms.append(node)
	else:
		s_alarms.erase(node)

# ------------------------------------------------------------------------------
func process_alarms():
	var is_raised = s_alarms.size() > 0

	if is_raised and alarm_timer.is_stopped():
		alarm_timer.start()
	if not is_raised and not alarm_timer.is_stopped():
		alarm_timer.stop()

# ------------------------------------------------------------------------------
func handle_alarm():
	alarm_timer.stop()
	s_alarms.clear()
	finished_timer.stop()
	s_finished.clear()
	%AlarmUI.visible = true
	
# ------------------------------------------------------------------------------
func _on_retry_pressed() -> void:
	load_state("res://gamestate.dat")
	%AlarmUI.visible = false

# ==============================================================================
#  Finished
# ==============================================================================
static func s_set_finished(node, finished):
	if finished:
		s_finished.append(node)
	else:
		s_finished.erase(node)

# ------------------------------------------------------------------------------
func process_finished():
	var needs_finished = -1;
	match curr_scene.name:
		"Tutorial":
			needs_finished = 2
		"Level1":
			needs_finished = 1
		"Level2":
			needs_finished = 2
		"Level3":
			needs_finished = 3
	
	var is_finished = s_finished.size() == needs_finished + 3

	if is_finished and finished_timer.is_stopped():
		finished_timer.start()
	if not is_finished and not finished_timer.is_stopped():
		finished_timer.stop()

# ------------------------------------------------------------------------------
func handle_finished():
	alarm_timer.stop()
	s_alarms.clear()
	finished_timer.stop()
	s_finished.clear()
	%FinishedUI.visible = true

# ------------------------------------------------------------------------------
func _on_continue_pressed() -> void:
	load_state("res://gamestate.dat")
	%FinishedUI.visible = false
	next_scene()

# ==============================================================================
#  Load / Save
# ==============================================================================
func save_state():
	print("State saved")
	var state: Array = []
	for vpos in nodes:
		var item: Dictionary = {
			"vpos": vpos,
			"device":  nodes[vpos].scene_file_path.get_file().get_basename(),
			"direction": nodes[vpos].direction
		}
		state.append(item)
	
	var file = FileAccess.open("user://gamestate.dat", FileAccess.WRITE)
	file.store_var(state)
	file.close()
	
# ------------------------------------------------------------------------------
func load_state(fname = "user://gamestate.dat"):
	print("State loaded")

	for vpos in nodes.keys():
		device_remove(vpos)
	s_finished.clear()
	s_alarms.clear()

	var state = []
	if FileAccess.file_exists(fname):
		var file = FileAccess.open(fname, FileAccess.READ)
		state = file.get_var()
		file.close()

	for item in state:
		var device = device_place(item.vpos, "res://scenes/devices/" + item.device + ".tscn")
		device.set_direction(item.direction)
	Solver.solve(nodes)

# ==============================================================================
func _on_quit_pressed() -> void:
	get_tree().quit()
