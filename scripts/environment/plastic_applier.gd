extends Node
## Material plástico/vinil (estilo Link's Awakening): ao iniciar, troca os
## materiais dos glTF por cópias com brilho especular suave e um verniz
## (clearcoat) leve, mais uma borda clara (rim light). É o que dá a cara de brinquedo: o kit vem fosco.
## Materiais iguais compartilham a mesma cópia. Materiais com emissão (vidro
## aceso, lanternas) ficam como estão. Regras em .docs/plans/11-estilo-visual.md.

@export var root_path: NodePath = NodePath("..")
@export_range(0.0, 1.0) var roughness: float = 0.3    ## menor = mais brilhante
@export_range(0.0, 1.0) var specular: float = 0.7
@export_range(0.0, 1.0) var clearcoat: float = 0.6   ## verniz por cima
@export_range(0.0, 1.0) var clearcoat_roughness: float = 0.3
@export_range(0.0, 1.0) var rim: float = 0.3          ## borda clara (fresnel) nos objetos
@export_range(0.0, 1.0) var rim_tint: float = 0.6     ## 0 = borda branca, 1 = cor da luz/objeto
@export var skip_names: PackedStringArray = ["glass", "glow", "light"]  ## nomes de material ignorados

var _cache := {}

func _ready() -> void:
	_scan(get_node(root_path))

func _scan(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat != null:
				mi.set_surface_override_material(i, _plastic(mat))
	for child in node.get_children():
		_scan(child)

func _plastic(mat: StandardMaterial3D) -> StandardMaterial3D:
	if _cache.has(mat):
		return _cache[mat]
	var result := mat
	var mat_name := mat.resource_name.to_lower()
	var skip := mat.emission_enabled
	for s in skip_names:
		if mat_name.contains(s):
			skip = true
	if not skip:
		result = mat.duplicate()
		result.roughness = minf(mat.roughness, roughness)
		result.roughness_texture = null
		result.metallic_specular = specular
		result.clearcoat_enabled = true
		result.clearcoat = clearcoat
		result.clearcoat_roughness = clearcoat_roughness
		result.rim_enabled = true
		result.rim = rim
		result.rim_tint = rim_tint
	_cache[mat] = result
	return result
