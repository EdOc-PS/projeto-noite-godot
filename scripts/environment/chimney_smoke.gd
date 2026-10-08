extends GPUParticles3D
## Fumaça da chaminé: usa o mesh do `smoke_puff.gltf` como partícula.
## (O glTF importa como cena; aqui pegamos o Mesh de dentro pra usar no draw pass.)

@export var puff_scene: PackedScene = preload("res://assets/models/custom/smoke/smoke_puff.gltf")

func _ready() -> void:
	var inst := puff_scene.instantiate()
	var mi := inst.find_children("*", "MeshInstance3D", true, false)
	if not mi.is_empty():
		draw_pass_1 = (mi[0] as MeshInstance3D).mesh
	inst.free()
