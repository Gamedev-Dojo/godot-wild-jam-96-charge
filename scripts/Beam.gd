class_name Beam extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func setup(info: TBeamInfo):
	var dist := 22.0
	if (info.target):
		dist = info.source.position.distance_to(info.target.position)
	$GPUParticles3D.lifetime = dist
	$GPUParticles3D.preprocess = dist
	$GPUParticles3D.amount = 2 * dist
	$GPUParticles3D.look_at(global_position + Vector3(info.direction.x, $GPUParticles3D.global_position.y, info.direction.y))
