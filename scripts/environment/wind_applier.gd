extends Node
## Aplica o shader de vento (`wind_sway.gdshader`) na vegetação do cenário ao
## iniciar. Classifica cada modelo pelo nome do glTF instanciado:
## grama/flores/plantinhas, folhagem, arbustos (leve) e árvores.
## Vegetação a mais de `far_radius` da casa fica parada (fora da área de jogo),
## menos árvores, que aparecem de longe.
## Feito por script porque o material precisa ir no MeshInstance3D de dentro do
## glTF, e marcar centenas de instâncias à mão no editor não escala.

const WIND_SHADER := preload("res://shaders/wind_sway.gdshader")

@export var root_path: NodePath = NodePath("..")
@export_range(0.0, 1.0) var grass_chance: float = 1.0  ## fração da grama/flores que balança
@export var center_path: NodePath = NodePath("../house")  ## referência pra distância
@export var far_radius: float = 20.0  ## além disso (exceto árvores) fica parado

@export_group("Grama e flores")
@export var grass_strength: float = 0.05
@export var grass_speed: float = 1.5
@export var grass_height: float = 0.4
@export var grass_push: float = 0.08  ## quanto abre quando o player passa

@export_group("Arbustos")
@export var bush_strength: float = 0.025
@export var bush_speed: float = 0.9
@export var bush_height: float = 1.0
@export var bush_push: float = 0.04

@export_group("Folhagem")
@export var foliage_strength: float = 0.06
@export var foliage_speed: float = 1.2
@export var foliage_height: float = 0.8
@export var foliage_push: float = 0.06

@export_group("Árvores")
@export var tree_strength: float = 0.08
@export var tree_speed: float = 0.8
@export var tree_start: float = 1.0   ## tronco parado até essa altura
@export var tree_height: float = 3.0

enum Kind { NONE, GRASS, FOLIAGE, BUSH, TREE }

var _materials := {}  ## "kind|textura" -> ShaderMaterial (compartilhado)
var _center := Vector3.ZERO

func _ready() -> void:
	var root := get_node(root_path)
	var center := get_node_or_null(center_path) as Node3D
	if center != null:
		_center = center.global_position
	for child in root.get_children():
		_scan(child)

func _scan(node: Node) -> void:
	var path := node.scene_file_path
	if path.ends_with(".gltf"):
		var kind := _kind_for(path.get_file().to_lower())
		if kind != Kind.NONE:
			if kind == Kind.GRASS and _hash01(node) > grass_chance:
				return
			if kind != Kind.TREE and _far(node):
				return
			var mat := _material_for(kind, path.get_base_dir())
			if mat != null:
				_apply(node, mat)
		return  # dentro de um glTF não há outros glTF
	for child in node.get_children():
		_scan(child)

func _kind_for(file: String) -> Kind:
	if file.begins_with("grass") or file.begins_with("flower") \
			or file.begins_with("succulent") or file.contains("_leaf_"):
		return Kind.GRASS
	if file.begins_with("foliage"):
		return Kind.FOLIAGE
	if file.begins_with("bush"):
		return Kind.BUSH
	if file.begins_with("tree"):
		return Kind.TREE
	return Kind.NONE

func _far(node: Node) -> bool:
	var p := (node as Node3D).global_position - _center
	return Vector2(p.x, p.z).length() > far_radius

## Número fixo (0..1) por posição: a mesma planta sempre balança ou não.
func _hash01(node: Node) -> float:
	var p := (node as Node3D).global_position
	return fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0)

func _material_for(kind: Kind, dir: String) -> ShaderMaterial:
	# cada kit usa uma textura atlas só
	var tex_path := dir.path_join("forest_texture.png" if dir.ends_with("forest_nature") else "tiny_treats_texture_1.png")
	var key := "%d|%s" % [kind, tex_path]
	if _materials.has(key):
		return _materials[key]
	if not ResourceLoader.exists(tex_path):
		push_warning("WindApplier: textura não encontrada: %s" % tex_path)
		return null
	var mat := ShaderMaterial.new()
	mat.shader = WIND_SHADER
	mat.set_shader_parameter(&"albedo_tex", load(tex_path))
	match kind:
		Kind.GRASS:
			_params(mat, grass_strength, grass_speed, 0.0, grass_height, 0.5, grass_push)
		Kind.FOLIAGE:
			_params(mat, foliage_strength, foliage_speed, 0.0, foliage_height, 0.5, foliage_push)
		Kind.BUSH:
			_params(mat, bush_strength, bush_speed, 0.2, bush_height, 0.5, bush_push)
			mat.set_shader_parameter(&"push_radius", 1.2)
		Kind.TREE:
			_params(mat, tree_strength, tree_speed, tree_start, tree_height, 0.42, 0.0)
	_materials[key] = mat
	return mat

func _params(mat: ShaderMaterial, strength: float, speed: float, start: float, height: float, rough: float, push: float) -> void:
	mat.set_shader_parameter(&"push_strength", push)
	mat.set_shader_parameter(&"sway_strength", strength)
	mat.set_shader_parameter(&"sway_speed", speed)
	mat.set_shader_parameter(&"sway_start", start)
	mat.set_shader_parameter(&"sway_height", height)
	mat.set_shader_parameter(&"roughness_value", rough)

func _apply(node: Node, mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply(child, mat)
