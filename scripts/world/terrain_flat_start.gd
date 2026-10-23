@tool
extends Terrain3D
## Prepara o terreno na primeira vez que a cena abre no editor e salva em
## `data_directory` (senão só o editor teria o chão e o jogo abriria sem terreno):
## - sem nenhuma região: cria um chão plano de 2 × 2 regiões em volta do centro;
## - grama ainda não semeada: espalha os tufos (mesh 0 do terrain_assets,
##   assets/models/grass/) pelo pincel do Terrain3D (Instancer), em MANCHAS de um
##   ruído (densa no meio, rala na borda) com altura em ondas, como o GrassField
##   antigo. Depois é só apagar/pintar mais com o mouse (ferramenta Instancer).
## A semeadura é marcada por `grass_seeded.txt` em `data_directory`, com a
## "assinatura" dos valores usados (este script + os exports). Se algum valor
## mudar, ao abrir a cena no editor o terreno é refeito sozinho (chão e grama).
## Atenção: isso apaga o que foi pintado à mão no terreno.

const START_SIZE := 256
const GRASS_MARKER := "grass_seeded.txt"

## Botão no Inspector: apaga o terreno (chão e grama), cria de novo com os
## valores atuais e salva em `data_directory`. Use depois de mudar a grama.
@export var regenerate: bool = false:
	set(v):
		if v and Engine.is_editor_hint() and is_inside_tree():
			_regenerate()

@export_group("Grama inicial")
@export var grass_area: float = 36.0                 ## lado do quadrado semeado (m)
@export var grass_spacing: float = 0.26              ## distância média entre tufos na mancha
@export_range(-1.0, 1.0) var grass_threshold: float = 0.06  ## maior = menos manchas
@export var grass_noise_frequency: float = 0.09      ## menor = manchas maiores
## Regras de tamanho: .docs/plans/10-vegetacao.md. A altura NÃO pode esticar
## muito mais que a largura (> ~1,4×): a ponta redonda vira ponta fina.
@export var grass_scale: Vector2 = Vector2(0.75, 1.1)
## Altura: o tamanho do tufo é o mínimo; onde a mancha é densa ele cresce até
## +`grass_dense_growth` (0,8 = 80% mais alto), variando por ondas.
@export var grass_dense_growth: float = 0.8
@export var grass_mesh_ids: PackedInt32Array = [0]
## Raminhos de folhinhas brancas (mesh 1), espalhados pouco por toda a grama.
@export var sprig_mesh_ids: PackedInt32Array = [1]
@export_range(0.0, 1.0) var sprig_chance: float = 0.01  ## fração dos pontos de grama que viram raminho
@export var sprig_min_distance: float = 3.0  ## distância mínima entre raminhos (m)
@export var sprig_over: Vector2 = Vector2(1.45, 1.65)  ## escala do raminho (×altura da grama no lugar)
## Grama caída no chão (meshes 2–7: 2 sprites × verde escuro, amarela, branca):
## poucas, só onde NÃO tem grama.
@export var litter_mesh_ids: PackedInt32Array = [2, 3, 4, 5, 6, 7]
@export_range(0.0, 1.0) var litter_chance: float = 0.003  ## fração dos pontos sem grama
@export var litter_min_distance: float = 1.5
## Manchas de TERRA (textura 1) pintadas sozinhas no chão: formas irregulares
## (não círculos perfeitos), com degradê largo pra grama na borda. Dentro
## delas não nasce grama, raminho nem grama caída.
@export var dirt_patches: int = 6
@export var dirt_radius: Vector2 = Vector2(3.5, 7.0)   ## raio de cada mancha (m)
@export var dirt_edge: float = 3.0                     ## largura do degradê terra → grama (m)
@export var dirt_seed: int = 5
@export var grass_seed: int = 11

func _ready() -> void:
	if not Engine.is_editor_hint() or data == null or data_directory == "":
		return
	var changed := false
	if data.get_region_count() == 0:
		# uma região plana por quadrante em volta do centro (2 × 2 regiões): um
		# import só criava a região de um quadrante e a grama em x/z positivos
		# não tinha onde nascer
		var rs := float(get_region_size()) * get_vertex_spacing()
		var height := Image.create_empty(get_region_size(), get_region_size(), false, Image.FORMAT_RF)
		height.fill(Color(0, 0, 0))
		var images: Array[Image] = []
		images.resize(Terrain3DRegion.TYPE_MAX)
		images[Terrain3DRegion.TYPE_HEIGHT] = height
		_make_dirt_patches()
		for rx in [-1, 0]:
			for rz in [-1, 0]:
				images[Terrain3DRegion.TYPE_CONTROL] = _control_image(Vector2(rx * rs, rz * rs))
				data.import_images(images, Vector3(rx * rs, 0, rz * rs), 0.0, 1.0)
		changed = true
	var marker := data_directory.path_join(GRASS_MARKER)
	var sig := _signature()
	if FileAccess.file_exists(marker) and FileAccess.get_file_as_string(marker).strip_edges() != sig and not changed:
		_regenerate()  # valores da grama mudaram: refaz tudo
		return
	if not FileAccess.file_exists(marker):
		_seed_grass()
		FileAccess.open(marker, FileAccess.WRITE).store_string(sig)
		changed = true
	if changed:
		data.save_directory(data_directory)

## Assinatura dos valores da semeadura: o texto do script + os exports.
func _signature() -> String:
	var parts := [FileAccess.get_file_as_string(get_script().resource_path)]
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and str(prop.name) != "regenerate":
			parts.append(str(get(prop.name)))
	return str("\n".join(parts).hash())

func _regenerate() -> void:
	for region: Terrain3DRegion in data.get_regions_active():
		data.remove_region(region, false)
	data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)
	var marker := data_directory.path_join(GRASS_MARKER)
	if FileAccess.file_exists(marker):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(marker))
	_ready()
	print("Terrain3D: chão e grama gerados e salvos em ", data_directory)

# --- manchas de terra -------------------------------------------------------

var _dirt: Array[Vector3] = []   # (x, z, raio) de cada mancha
var _dirt_noise := FastNoiseLite.new()

func _make_dirt_patches() -> void:
	_dirt.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = dirt_seed
	_dirt_noise.seed = dirt_seed
	_dirt_noise.frequency = 0.18
	var half := grass_area * 0.45
	for i in dirt_patches:
		_dirt.append(Vector3(rng.randf_range(-half, half), rng.randf_range(-half, half), rng.randf_range(dirt_radius.x, dirt_radius.y)))

## Quanto de terra (0 = grama, 1 = terra) num ponto do chão. Contorno torto pelo
## ruído; o degradê ocupa `dirt_edge` metros pra fora da mancha.
func _dirt_amount(x: float, z: float) -> float:
	if _dirt.is_empty():
		_make_dirt_patches()
	var a := 0.0
	var wobble := _dirt_noise.get_noise_2d(x, z) * 0.35
	for d in _dirt:
		var dist := Vector2(x - d.x, z - d.y).length() / d.z + wobble
		# 1 dentro da mancha, cai até 0 ao longo de dirt_edge pra fora
		a = maxf(a, 1.0 - smoothstep(1.0, 1.0 + dirt_edge / d.z, dist))
	return a

## Mapa de controle do Terrain3D de uma região: textura base 0 (grama) com a
## terra (1) por cima, misturada pelo `blend` (8 bits) no degradê.
## Formato de cada pixel (uint32 guardado como float): base id << 27,
## overlay id << 22, blend << 14.
func _control_image(origin: Vector2) -> Image:
	var n := get_region_size()
	var sp := get_vertex_spacing()
	var bytes := PackedByteArray()
	bytes.resize(n * n * 4)
	for y in n:
		for x in n:
			var a := _dirt_amount(origin.x + x * sp, origin.y + y * sp)
			var v := 0
			if a >= 0.995:
				v = 1 << 27                                   # só terra
			elif a > 0.005:
				v = (1 << 22) | (int(round(a * 255.0)) << 14)  # grama + terra por cima
			bytes.encode_u32((y * n + x) * 4, v)
	return Image.create_from_data(n, n, false, Image.FORMAT_RF, bytes)

func _seed_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = grass_seed
	var noise := FastNoiseLite.new()
	noise.seed = grass_seed
	noise.frequency = grass_noise_frequency
	var height_noise := FastNoiseLite.new()
	height_noise.seed = grass_seed + 7
	height_noise.frequency = 0.35
	var per_mesh := {}
	for id in grass_mesh_ids + sprig_mesh_ids + litter_mesh_ids:
		per_mesh[id] = [] as Array[Transform3D]
	var sprigs: Array[Vector3] = []
	_litter = [] as Array[Vector3]
	_seed_area(Vector2.ZERO, grass_area, grass_mesh_ids, rng, noise, height_noise, per_mesh, sprigs)
	for id in per_mesh:
		if not (per_mesh[id] as Array).is_empty():
			instancer.add_transforms(id, per_mesh[id])

## Semeia um quadrado de `size` m centrado em `center` com os tufos `ids`.
func _seed_area(center: Vector2, size: float, ids: PackedInt32Array, rng: RandomNumberGenerator,
		noise: FastNoiseLite, height_noise: FastNoiseLite, per_mesh: Dictionary, sprigs: Array[Vector3]) -> void:
	var half := size / 2.0
	var x := -half
	while x <= half:
		var z := -half
		while z <= half:
			var p := Vector3(center.x + x + rng.randf_range(-0.4, 0.4) * grass_spacing, 0.0, center.y + z + rng.randf_range(-0.4, 0.4) * grass_spacing)
			# densidade cresce do limite pro centro da mancha
			var density := clampf((noise.get_noise_2d(p.x, p.z) - grass_threshold) / 0.25, 0.0, 1.0)
			# na terra não nasce nada; no degradê a grama vai rareando
			var dirt := _dirt_amount(p.x, p.z)
			if dirt > 0.0 and rng.randf() < dirt * 1.6:
				z += grass_spacing
				continue
			if density <= 0.0:
				# sem grama: às vezes uma grama caída no chão
				if not litter_mesh_ids.is_empty() and rng.randf() < litter_chance and _far_from(_litter, p, litter_min_distance):
					_litter.append(p)
					var lb := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3))
					var lid: int = litter_mesh_ids[rng.randi() % litter_mesh_ids.size()]
					(per_mesh[lid] as Array[Transform3D]).append(Transform3D(lb, Vector3(p.x, data.get_height(p), p.z)))
			elif rng.randf() < density:
				p.y = data.get_height(p)
				var wave := (height_noise.get_noise_2d(p.x, p.z) + 1.0) * 0.5
				# densa (meio da mancha) cresce até +grass_dense_growth; a onda só varia
				# entre 70% e 100% desse crescimento, pra não ficarem todos iguais
				var h := 1.0 + grass_dense_growth * smoothstep(0.2, 0.9, density) * lerpf(0.7, 1.0, wave)
				var s := rng.randf_range(grass_scale.x, grass_scale.y)
				var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * h, s))
				var id: int = ids[rng.randi() % ids.size()]
				if not sprig_mesh_ids.is_empty() and rng.randf() < sprig_chance and _far_from(sprigs, p, sprig_min_distance):
					sprigs.append(p)
					id = sprig_mesh_ids[rng.randi() % sprig_mesh_ids.size()]
					# sempre acima da grama em volta: cresce junto com os tufos (h) e
					# ainda fica `sprig_over` mais alto
					b = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * h * rng.randf_range(sprig_over.x, sprig_over.y))
				(per_mesh[id] as Array[Transform3D]).append(Transform3D(b, p))
			z += grass_spacing
		x += grass_spacing

var _litter: Array[Vector3] = []

func _far_from(points: Array[Vector3], p: Vector3, dist: float) -> bool:
	for q in points:
		if Vector2(p.x - q.x, p.z - q.z).length() < dist:
			return false
	return true
