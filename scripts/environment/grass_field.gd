extends Node3D
## Campo de grama densa: milhares de tufos (`grass_tuft_A/B`) agrupados em
## manchas pelo cenário, desenhados com MultiMesh (um desenho por tipo de tufo,
## em vez de milhares de nós). Usa o mesmo shader de vento do resto da
## vegetação, então balança com o vento e amassa quando o jogador passa.
##
## As manchas vêm de um ruído: onde o ruído passa de `threshold`, nasce grama,
## mais densa no centro da mancha. Não nasce em cima da casa, do caminho, de
## pedras, cercas e outros objetos do cenário (raio `clearance`).

const WIND_SHADER := preload("res://shaders/wind_sway.gdshader")
const ATLAS := preload("res://assets/models/calm_place/homely_house/tiny_treats_texture_1.png")

@export var tuft_scenes: Array[PackedScene] = [
	preload("res://assets/models/custom/grass/grass_tuft_A.gltf"),
	preload("res://assets/models/custom/grass/grass_tuft_B.gltf"),
]
@export var area_half_size: float = 15.5     ## área quadrada em volta deste node
@export var spacing: float = 0.26            ## distância média entre tufos dentro da mancha
@export_range(-1.0, 1.0) var threshold: float = 0.05  ## maior = menos manchas, mais separadas
@export var noise_frequency: float = 0.09    ## menor = manchas maiores
@export var noise_seed: int = 11
@export var scale_range: Vector2 = Vector2(0.55, 0.9)
## Altura em ondas: um ruído largo faz a grama crescer e baixar pelo campo, e
## dentro da mancha ela é mais alta no centro e baixa na borda.
@export var height_range: Vector2 = Vector2(0.6, 1.7)  ## multiplicador da altura (baixa, alta)
@export var height_frequency: float = 0.16             ## menor = ondas de altura mais largas
@export var root_path: NodePath = NodePath("..")  ## onde procurar objetos pra desviar
@export var clearance: float = 0.6           ## raio livre em volta de objetos que não são planta
@export var house_path: NodePath = NodePath("../house")
@export var path_clearance: float = 0.85     ## raio livre em volta do caminho de pedras (ligando as pedras próximas)
@export var path_border_width: float = 0.8   ## faixa de grama densa acompanhando o caminho, logo depois do raio livre
@export var path_link_distance: float = 4.2  ## pedras mais próximas que isso formam um trecho contínuo
## Manchas extras (x, z, raio no mundo): grama densa garantida, além do ruído.
@export var bonus_zones: Array[Vector3] = [Vector3(7.2, -9.4, 3.0), Vector3(14.0, -1.5, 2.5), Vector3(7.7, -0.2, 1.2)]
## Faixas densas nas laterais da casa (esquerda e direita), em metros a partir da parede.
@export var house_side_width: float = 2.6
@export var house_margin: float = 0.25  ## grama não encosta na parede
const HOUSE_HALF := Vector3(2.95, 0.0, 0.0)          ## meia-largura da casa (x local)
const HOUSE_Z := Vector2(-2.22, 4.32)                 ## fundo e frente da casa (z local)

@export_group("Vento e toque")
@export var sway_strength: float = 0.06
@export var sway_speed: float = 2.3
@export var push_strength: float = 0.08
@export var push_radius: float = 0.9

var _blocked: Array[Vector3] = []
var _cobbles: Array[Vector3] = []
var _height_noise := FastNoiseLite.new()

func _ready() -> void:
	_collect_obstacles(get_node(root_path))
	var meshes: Array[Mesh] = []
	for scene in tuft_scenes:
		var inst := scene.instantiate()
		var found := inst.find_children("*", "MeshInstance3D", true, false)
		if not found.is_empty():
			meshes.append((found[0] as MeshInstance3D).mesh)
		inst.free()
	if meshes.is_empty():
		return

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	_height_noise.seed = noise_seed + 7
	_height_noise.frequency = height_frequency
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var house := get_node_or_null(house_path) as Node3D

	var transforms: Array = []
	for i in meshes.size():
		transforms.append([])
	var x := -area_half_size
	while x <= area_half_size:
		var z := -area_half_size
		while z <= area_half_size:
			var p := global_position + Vector3(x + rng.randf_range(-0.4, 0.4) * spacing, 0.0, z + rng.randf_range(-0.4, 0.4) * spacing)
			var n := noise.get_noise_2d(p.x, p.z)
			# densidade cresce do limite pro centro da mancha
			var density := clampf((n - threshold) / 0.25, 0.0, 1.0)
			if density > 0.0 and rng.randf() < density and _free(p, house):
				var s := rng.randf_range(scale_range.x, scale_range.y)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * _height(p, density), s))
				transforms[rng.randi() % meshes.size()].append(Transform3D(basis, to_local(p)))
			z += spacing
		x += spacing

	# passe extra, denso: laterais da casa e zonas bônus
	var dense := spacing * 0.8
	x = -area_half_size
	while x <= area_half_size:
		var z := -area_half_size
		while z <= area_half_size:
			var p := global_position + Vector3(x + rng.randf_range(-0.4, 0.4) * dense, 0.0, z + rng.randf_range(-0.4, 0.4) * dense)
			if (_in_house_sides(p, house) or _in_bonus(p) or _on_path_border(p)) and rng.randf() < 0.8 and _free(p, house):
				var s := rng.randf_range(scale_range.x, scale_range.y)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * _height(p, 0.7), s))
				transforms[rng.randi() % meshes.size()].append(Transform3D(basis, to_local(p)))
			z += dense
		x += dense

	var mat := _material()
	for i in meshes.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[i]
		mm.instance_count = transforms[i].size()
		for j in transforms[i].size():
			mm.set_instance_transform(j, transforms[i][j])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)

## Multiplicador da altura do tufo: onda larga pelo campo + mais alto no meio da mancha.
func _height(p: Vector3, density: float) -> float:
	var wave := (_height_noise.get_noise_2d(p.x, p.z) + 1.0) * 0.5
	return lerpf(height_range.x, height_range.y, wave) * lerpf(0.75, 1.15, density)

func _material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WIND_SHADER
	mat.set_shader_parameter(&"albedo_tex", ATLAS)
	mat.set_shader_parameter(&"sway_strength", sway_strength)
	mat.set_shader_parameter(&"sway_speed", sway_speed)
	mat.set_shader_parameter(&"sway_start", 0.0)
	mat.set_shader_parameter(&"sway_height", 0.35)
	mat.set_shader_parameter(&"push_strength", push_strength)
	mat.set_shader_parameter(&"push_radius", push_radius)
	return mat

func _in_bonus(p: Vector3) -> bool:
	for z in bonus_zones:
		if Vector2(p.x - z.x, p.z - z.y).length() < z.z:
			return true
	return false

## Distância de `p` (plano XZ) até o segmento a-b.
func _dist_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var pa := Vector2(p.x - a.x, p.z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := clampf(pa.dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (pa - ab * t).length()

## Menor distância (plano XZ) até o caminho de pedras: pedras e trechos ligando as próximas.
func _path_distance(p: Vector3) -> float:
	var best := INF
	for i in _cobbles.size():
		best = minf(best, Vector2(p.x - _cobbles[i].x, p.z - _cobbles[i].z).length())
		for j in range(i + 1, _cobbles.size()):
			if Vector2(_cobbles[i].x - _cobbles[j].x, _cobbles[i].z - _cobbles[j].z).length() < path_link_distance:
				best = minf(best, _dist_segment(p, _cobbles[i], _cobbles[j]))
	return best

func _on_path(p: Vector3) -> bool:
	return _path_distance(p) < path_clearance

## Faixa logo ao lado do caminho (sem entrar nele): grama densa acompanhando as pedras.
func _on_path_border(p: Vector3) -> bool:
	var d := _path_distance(p)
	return d >= path_clearance and d < path_clearance + path_border_width

## Dentro das faixas ao lado da casa (esquerda/direita), no espaço local dela.
func _in_house_sides(p: Vector3, house: Node3D) -> bool:
	if house == null:
		return false
	var l := house.to_local(p)
	var side := absf(l.x) - HOUSE_HALF.x
	return side > house_margin and side < house_side_width and l.z > HOUSE_Z.x and l.z < HOUSE_Z.y

## Em cima da casa (caixa da casa no espaço local, com uma folguinha).
func _on_house(p: Vector3, house: Node3D) -> bool:
	if house == null:
		return false
	var l := house.to_local(p)
	return absf(l.x) < HOUSE_HALF.x + house_margin and l.z > HOUSE_Z.x - house_margin and l.z < HOUSE_Z.y + house_margin

func _free(p: Vector3, house: Node3D) -> bool:
	if _on_house(p, house):
		return false
	if _on_path(p):
		return false
	for o in _blocked:
		if Vector2(p.x - o.x, p.z - o.z).length() < clearance:
			return false
	return true

## Guarda a posição de tudo que não é planta (caminho, pedras, cercas, banco,
## postes...) pra grama não nascer em cima.
func _collect_obstacles(node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		var path := child.scene_file_path
		if path.ends_with(".gltf"):
			var file := path.get_file().to_lower()
			var plant := file.begins_with("grass") or file.begins_with("flower") or file.begins_with("tree") \
					or file.begins_with("bush") or file.begins_with("foliage") or file.contains("_leaf_") \
					or file.begins_with("floor")
			if file.begins_with("cobblestones") and child is Node3D:
				_cobbles.append((child as Node3D).global_position)  # caminho de pedras: trecho contínuo
			elif not plant and child is Node3D:
				_blocked.append((child as Node3D).global_position)
			continue
		_collect_obstacles(child)
