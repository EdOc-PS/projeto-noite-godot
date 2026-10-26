extends Node3D
## Tufos de florzinhas em PNG (estilo BotW) espalhados pelo campo em montes
## de um tipo só. Cada tufo é uma carta cruzada (2 planos) com o shader
## flower_card; um MultiMesh por tipo.
## Regras: .docs/plans/10-vegetacao.md.

const SHADER := preload("res://shaders/nature/flower_card.gdshader")

@export var textures: Array[Texture2D] = []
@export var clump_count: int = 40                  ## montes de flores
@export var clump_size: Vector2i = Vector2i(4, 10) ## tufos por monte
@export var clump_radius: float = 0.9              ## raio do monte (m)
@export var area_half_size: float = 12.0
@export var size_range: Vector2 = Vector2(0.8, 1.25)  ## altura do tufo (m)
## Escala por textura (mesma ordem de `textures`): flor baixinha < 1. Vazio = 1.
@export var size_scales: PackedFloat32Array = []
@export var clump_seed: int = 7
## Nós cujo contorno (malhas, visto de cima) as flores evitam: casa, caminho,
## cerca, banco... (cenas montadas à mão, como o outside).
@export var avoid_paths: Array[NodePath] = []
@export var avoid_margin: float = 0.4
@export var max_avoid_size: float = 12.0  ## malhas maiores que isso não contam (chão)

## Onde cada tipo nasce (mesma ordem de `textures`): 0 = qualquer lugar,
## 1 = só no chão (fora da grama), 2 = só no meio da grama. A grama é a mesma
## mancha de ruído da semeadura do Terrain3D (terrain_flat_start.gd): manter
## `grass_seed`, `grass_frequency` e `grass_threshold` iguais aos de lá.
@export var placement: PackedInt32Array = []
@export var grass_seed: int = 11
@export var grass_frequency: float = 0.09
@export var grass_threshold: float = 0.06

var _avoid: Array[Rect2] = []
var _grass_noise := FastNoiseLite.new()

## Regra de vegetação (10-vegetacao.md): flores ficam em MONTES de um tipo só
## (um monte vermelho, um monte roxo...), nunca misturadas no mesmo monte.
## Cada tipo pode ficar só no chão, só na grama ou em qualquer lugar (`placement`).
func _ready() -> void:
	if textures.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = clump_seed
	for path in avoid_paths:
		var n := get_node_or_null(path)
		if n:
			_collect_rects(n)
	var per_tex: Array = []
	for t in textures:
		per_tex.append([])
	_grass_noise.seed = grass_seed
	_grass_noise.frequency = grass_frequency
	for c in clump_count:
		var k := rng.randi() % textures.size()  # um tipo por monte
		var mode := placement[k] if k < placement.size() else 0
		var center := Vector3.ZERO
		var found := false
		for _try in 30:  # sorteia até cair no lugar certo (chão ou grama)
			center = Vector3(rng.randf_range(-area_half_size, area_half_size), 0.0, rng.randf_range(-area_half_size, area_half_size))
			var g := _in_grass(global_position + center)
			if mode == 0 or (mode == 1 and not g) or (mode == 2 and g):
				found = true
				break
		if not found:
			continue
		var n := rng.randi_range(clump_size.x, clump_size.y)
		for j in n:
			var r := sqrt(rng.randf()) * clump_radius
			var a := rng.randf() * TAU
			var q := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if _blocked(global_position + q):
				continue
			# mais baixinhas na borda do monte, mais altas no meio
			var s := rng.randf_range(size_range.x, size_range.y) * lerpf(1.0, 0.75, r / clump_radius)
			if k < size_scales.size():
				s *= size_scales[k]
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
			per_tex[k].append(Transform3D(b, q))
	var mesh := _cross_mesh()
	for i in textures.size():
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter(&"albedo_tex", textures[i])
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = per_tex[i].size()
		for j in per_tex[i].size():
			mm.set_instance_transform(j, per_tex[i][j])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)

## Mesma conta da semeadura: tem grama onde o ruído passa do limite.
func _in_grass(p: Vector3) -> bool:
	return _grass_noise.get_noise_2d(p.x, p.z) > grass_threshold + 0.05

func _collect_rects(n: Node) -> void:
	if n is MeshInstance3D:
		var a: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		# malha gigante (chão/quintal dentro da casa) bloquearia o mapa todo: ignora
		if a.size.x < max_avoid_size and a.size.z < max_avoid_size:
			_avoid.append(Rect2(a.position.x, a.position.z, a.size.x, a.size.z).grow(avoid_margin))
	for c in n.get_children():
		_collect_rects(c)

func _blocked(p: Vector3) -> bool:
	for r in _avoid:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false

## Duas cartas 1x1 cruzadas, base em y = 0 (UV.y = 1 embaixo).
func _cross_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ang in [0.0, PI * 0.5]:
		var dx := Vector3(cos(ang), 0.0, sin(ang)) * 0.5
		var v := [-dx, dx, dx + Vector3.UP, -dx + Vector3.UP]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[idx])
			st.add_vertex(v[idx])
	return st.commit()
