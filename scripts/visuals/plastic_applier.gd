extends Node
## Material plástico/vinil (estilo Link's Awakening): ao iniciar, troca os
## materiais dos glTF por cópias com brilho especular suave (fosco-acetinado,
## nunca "molhado") e um verniz (clearcoat) bem leve, mais uma borda clara (rim light). É o que dá a cara de brinquedo: o kit vem fosco.
## Materiais iguais compartilham a mesma cópia. Materiais com emissão (vidro
## aceso, lanternas) ficam como estão. Regras em .docs/plans/11-estilo-visual.md.

@export var root_path: NodePath = NodePath("..")
@export_range(0.0, 1.0) var roughness: float = 0.55   ## menor = mais brilhante
@export_range(0.0, 1.0) var specular: float = 0.5
@export_range(0.0, 1.0) var clearcoat: float = 0.1   ## verniz por cima
@export_range(0.0, 1.0) var clearcoat_roughness: float = 0.6
@export_range(0.0, 1.0) var rim: float = 0.5          ## borda clara (fresnel) nos objetos
@export_range(0.0, 1.0) var rim_tint: float = 0.6     ## 0 = borda branca, 1 = cor da luz/objeto
## Sombra própria em degrau suave, como no toon: a passagem luz → sombra no
## objeto fica marcada em vez do degradê comprido (diffuse "toon" da Godot;
## a suavidade do degrau vem da roughness).
@export var toon_shading: bool = true
## Halo de borda (o mesmo brilho azulado em volta das árvores, que vem do
## shader de vento): camada extra somada por cima (`rim_overlay.gdshader`),
## sem balançar. Pros objetos parados (caixas, barris, bonecos, madeira).
@export var rim_overlay: bool = true
## Caixas e barris têm faces retas: com o expoente das árvores (3) a borda só
## aparecia num fio no contorno. Mais largo e forte aqui pra ficar visível.
@export var overlay_power: float = 1.6
@export var overlay_strength: float = 0.5
@export var skip_names: PackedStringArray = ["glass", "glow", "light"]  ## nomes de material ignorados

var _cache := {}
var _overlay: ShaderMaterial

func _ready() -> void:
	if rim_overlay:
		_overlay = ShaderMaterial.new()
		_overlay.shader = preload("res://shaders/effects/rim_overlay.gdshader")
		_overlay.set_shader_parameter(&"rim_power", overlay_power)
		_overlay.set_shader_parameter(&"rim_strength", overlay_strength)
	_scan(get_node(root_path))

func _scan(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat != null:
				mi.set_surface_override_material(i, _plastic(mat))
				if _overlay != null and mi.material_overlay == null and _plastic(mat) != mat and not _is_plant(mi):
					mi.material_overlay = _overlay
	for child in node.get_children():
		_scan(child)

## Vegetação recebe o shader de vento depois (WindApplier), que já tem a borda
## clara própria e BALANÇA. O halo por cima ficava parado enquanto a árvore
## balançava: a "parte branca" parecia girar. Por isso planta não ganha o halo.
const PLANT_PREFIXES := ["tree", "bush", "grass", "flower", "foliage", "plant", "leaf", "leaves"]
func _is_plant(node: Node) -> bool:
	var n := node
	while n != null:
		if n.scene_file_path.ends_with(".gltf"):
			var f := n.scene_file_path.get_file().to_lower()
			for p in PLANT_PREFIXES:
				if f.begins_with(p) or f.contains("_" + p):
					return true
			return false
		n = n.get_parent()
	return false

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
		result.roughness = roughness  # mesmo acabamento em tudo (o kit da cidade vem com 0,4)
		result.roughness_texture = null
		result.metallic_specular = specular
		result.clearcoat_enabled = true
		result.clearcoat = clearcoat
		result.clearcoat_roughness = clearcoat_roughness
		result.rim_enabled = true
		result.rim = rim
		result.rim_tint = rim_tint
		if toon_shading:
			result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_cache[mat] = result
	return result
