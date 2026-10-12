extends Node3D
## Fogo reutilizável (scenes/effects/fire.tscn): chamas cartunescas
## (`flame.gdshader`), fagulhas e, opcional, a própria luz piscando.
## Tamanho pela escala do node. Lareira e tochas já têm luz própria e
## desligam a daqui (`with_light = false`).

@export var with_light: bool = true
@export var light_energy: float = 2.0
@export var light_range: float = 5.0

func _ready() -> void:
	# cada fogo dessincronizado dos outros
	var off := randf() * 50.0
	for f in [$Flame, $FlameBack]:
		var mesh := f as MeshInstance3D
		var mat := mesh.material_override as ShaderMaterial
		if mat != null:
			mat = mat.duplicate()
			mat.set_shader_parameter(&"time_offset", off + (0.0 if mesh.name == &"Flame" else 13.0))
			mesh.material_override = mat

	var light := get_node_or_null(^"FireLight") as OmniLight3D
	if light == null:
		return
	if not with_light:
		light.queue_free()
		return
	light.omni_range = light_range
	light.set(&"base_energy", light_energy)
