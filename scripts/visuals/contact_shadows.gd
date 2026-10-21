extends Node
## Sombra de contato ("blob shadow") embaixo de árvores, arbustos, pedras e
## folhagem: um Decal com mancha radial escura, do tamanho da base do objeto.
## Truque comum em jogos estilizados: o SSAO de tela não pega bem a base de
## objetos vistos de cima (ainda mais com câmera ortogonal), e sem isso eles
## parecem flutuar. Feito ao iniciar, classificando pelo nome do glTF.

@export var root_path: NodePath = NodePath("..")
@export var color: Color = Color(0.03, 0.04, 0.1, 0.55)
@export var size_factor: float = 1.25  ## mancha um pouco maior que a base do objeto
@export var prefixes: PackedStringArray = ["tree", "bush", "foliage", "rock", "stepping_stumps"]

var _tex: GradientTexture2D

func _ready() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.fill = GradientTexture2D.FILL_RADIAL
	_tex.fill_from = Vector2(0.5, 0.5)
	_tex.fill_to = Vector2(0.5, 0.0)
	_tex.width = 64
	_tex.height = 64
	for child in get_node(root_path).get_children():
		_scan(child)

func _scan(node: Node) -> void:
	var path := node.scene_file_path
	if path.ends_with(".gltf"):
		var file := path.get_file().to_lower()
		for p in prefixes:
			if file.begins_with(p):
				_add_shadow(node as Node3D)
				break
		return
	for child in node.get_children():
		_scan(child)

func _add_shadow(node: Node3D) -> void:
	var aabb := _local_aabb(node)
	if aabb.size == Vector3.ZERO:
		return
	var w := maxf(aabb.size.x, aabb.size.z) * size_factor
	var d := Decal.new()
	d.texture_albedo = _tex
	d.modulate = color
	d.size = Vector3(w, 1.0, w)
	d.upper_fade = 0.3
	d.lower_fade = 0.3
	node.add_child(d)
	# centro da base, compensando a escala do objeto (o Decal herda a escala)
	d.position = Vector3(aabb.get_center().x, 0.1, aabb.get_center().z)

## AABB dos meshes do glTF no espaço do próprio node (ignora a escala do node).
func _local_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var inv := node.global_transform.affine_inverse()
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var box: AABB = inv * m.global_transform * m.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
