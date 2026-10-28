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

@export_group("Relevo")
## 0 = chão plano. Maior = morros (altura máxima em metros), por ruído suave.
@export var hill_height: float = 0.0
@export var hill_frequency: float = 0.025   ## menor = morros mais largos
@export var hill_seed: int = 3
@export_group("Grama inicial")
@export var grass_area: float = 26.0                 ## lado do quadrado semeado (m)
@export var grass_spacing: float = 0.39             ## distância média entre tufos na mancha
@export_range(-1.0, 1.0) var grass_threshold: float = 0.06  ## maior = menos manchas
@export var grass_noise_frequency: float = 0.09      ## menor = manchas maiores
## Regras de tamanho: .docs/plans/10-vegetacao.md. A altura NÃO pode esticar
## muito mais que a largura (> ~1,4×): a ponta redonda vira ponta fina.
@export var grass_scale: Vector2 = Vector2(0.75, 1.1)
## Altura: o tamanho do tufo é o mínimo; onde a mancha é densa ele cresce até
## +`grass_dense_growth` (0,8 = 80% mais alto), variando por ondas.
@export var grass_dense_growth: float = 0.8
@export var grass_mesh_ids: PackedInt32Array = [0]
## Tufos da BORDA das manchas (vista de cima, um tufo cheio na borda fica
## recortado e feio): [0] onde a mancha já está rala, [1] na beiradinha.
## Vazio = só `grass_mesh_ids` em todo lugar.
@export var edge_mesh_ids: PackedInt32Array = []
@export_range(0.0, 1.0) var edge_density: float = 0.5  ## abaixo dessa densidade usa os tufos de borda
## Raminhos de folhinhas brancas (mesh 1), espalhados pouco por toda a grama.
@export var sprig_mesh_ids: PackedInt32Array = [1]
@export_range(0.0, 1.0) var sprig_chance: float = 0.01  ## fração dos pontos de grama que viram raminho
@export var sprig_min_distance: float = 3.0  ## distância mínima entre raminhos (m)
@export_range(0.0, 1.0) var sprig_min_density: float = 0.7  ## raminho só no meio da mancha (grama densa em volta), nunca na beirada
@export var sprig_over: Vector2 = Vector2(1.45, 1.65)  ## escala do raminho (×altura da grama no lugar)
@export_group("Arbustos")
## Arbusto (mesh 7: Bush_Common do Stylized Nature) espalhado pelo campo,
## cada um longe dos outros, na borda/fora das manchas de grama.
@export var bush_mesh_ids: PackedInt32Array = [7]
@export var bush_flower_mesh_ids: PackedInt32Array = [8]   ## arbusto com flores (Bush_Common_Flowers)
@export_range(0.0, 1.0) var bush_flower_chance: float = 0.4
@export var bush_count: int = 14
@export var bush_min_distance: float = 3.5
@export var bush_scale: Vector2 = Vector2(0.45, 1.5)  ## tamanhos bem diferentes
@export_group("Pedras")
## Pedras do Stylized Nature (sem as de caminho), só no chão SEM grama.
@export var rock_mesh_ids: PackedInt32Array = [9, 10, 11]           ## pedras médias
@export var rock_count: int = 8
@export var rock_min_distance: float = 5.0
@export var rock_scale: Vector2 = Vector2(0.3, 0.65)
@export var pebble_mesh_ids: PackedInt32Array = [12, 13, 14, 15, 16, 17]  ## pedrinhas: 3 redondas + 3 quadradas
@export var pebble_count: int = 36
@export var pebble_min_distance: float = 1.0
@export var pebble_scale: Vector2 = Vector2(0.3, 1.6)  ## do tamanho atual até bem menor
@export_group("Flores")
## Flores no pincel do Terrain3D (aparecem no editor e no jogo). Cada tipo:
## carta deitada das flores (`flower_head_ids`) + caules (`flower_stem_ids`,
## -1 = sem caule, rente ao chão). Montes de um tipo só (10-vegetacao.md).
@export var flower_head_ids: PackedInt32Array = [3, 4, 6]   ## branca, azul, vermelha
@export var flower_stem_ids: PackedInt32Array = [-1, 5, 5]   ## 5 = caule universal
@export var flower_scales: PackedFloat32Array = [1.3, 1.15, 1.3]
@export var flower_weights: PackedFloat32Array = [2.0, 1.0, 1.0]  ## chance de cada tipo por monte
## true = só BEM dentro da grama (densidade >= `flower_in_grass_density`); false = só fora dela
@export var flower_in_grass: Array[bool] = [false, true, true]
@export_range(0.0, 1.0) var flower_in_grass_density: float = 0.8
@export var flower_clumps: int = 40
@export var flower_clump_size: Vector2i = Vector2i(4, 10)
@export var flower_clump_radius: float = 0.9
## Tamanho do monte por tipo (mesma ordem): × flores no monte; o raio acompanha (√). Branca 0,2: 1–2 cartas soltas (cada carta já é um grupinho de 4–6 flores).
@export var flower_clump_mult: PackedFloat32Array = [0.2, 1.0, 1.0]
@export var flower_size: Vector2 = Vector2(0.8, 1.25)
## Raio do desenho das flores na carta (fração da escala): duas cartas nunca
## ficam mais perto que a soma dos raios (flor nunca dentro de outra flor).
@export var flower_spread: float = 0.34
@export_group("")
## Manchas de TERRA (textura 1) pintadas sozinhas no chão: formas irregulares
## (não círculos perfeitos), com degradê largo pra grama na borda. Dentro
## delas não nasce grama, raminho nem grama caída.
@export var dirt_patches: int = 0   ## 0 = sem manchas (tiradas da cena); a textura Terra continua pra pintar à mão
@export var dirt_radius: Vector2 = Vector2(1.5, 3.0)   ## raio de cada mancha (m)
@export var dirt_edge: float = 1.5                     ## largura do degradê terra → grama (m)
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
		var images: Array[Image] = []
		images.resize(Terrain3DRegion.TYPE_MAX)
		_make_dirt_patches()
		for rx in [-1, 0]:
			for rz in [-1, 0]:
				images[Terrain3DRegion.TYPE_HEIGHT] = _height_image(Vector2(rx * rs, rz * rs))
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

## Altura de uma região: plana, ou morros suaves (`hill_height` > 0).
func _height_image(origin: Vector2) -> Image:
	var n := get_region_size()
	var img := Image.create_empty(n, n, false, Image.FORMAT_RF)
	if hill_height <= 0.0:
		img.fill(Color(0, 0, 0))
		return img
	var noise := FastNoiseLite.new()
	noise.seed = hill_seed
	noise.frequency = hill_frequency
	noise.fractal_octaves = 3
	var sp := get_vertex_spacing()
	for y in n:
		for x in n:
			var h := (noise.get_noise_2d(origin.x + x * sp, origin.y + y * sp) + 1.0) * 0.5
			img.set_pixel(x, y, Color(h * h * hill_height, 0, 0))  # h²: vales largos, morros redondos
	return img

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
	if dirt_patches <= 0:
		return 0.0
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
	for id in grass_mesh_ids + edge_mesh_ids + sprig_mesh_ids + flower_head_ids + flower_stem_ids + bush_mesh_ids + bush_flower_mesh_ids + rock_mesh_ids + pebble_mesh_ids:
		if id >= 0:
			per_mesh[id] = [] as Array[Transform3D]
	var sprigs: Array[Vector3] = []
	var half := grass_area / 2.0
	_seed_area(Rect2(-half, -half, grass_area, grass_area), grass_mesh_ids, edge_mesh_ids, grass_spacing, rng, noise, height_noise, per_mesh, sprigs)
	_seed_flowers(half, rng, noise, per_mesh)
	_seed_bushes(half, rng, noise, per_mesh)
	_seed_rocks(half, rng, noise, per_mesh, rock_mesh_ids, rock_count, rock_min_distance, rock_scale)
	_seed_rocks(half, rng, noise, per_mesh, pebble_mesh_ids, pebble_count, pebble_min_distance, pebble_scale)
	for id in per_mesh:
		if not (per_mesh[id] as Array).is_empty():
			instancer.add_transforms(id, per_mesh[id])

## Semeia o retângulo `area` (x, z) com os tufos `ids` (e `edge_ids` na borda das manchas).
func _seed_area(area: Rect2, ids: PackedInt32Array, edge_ids: PackedInt32Array, spacing: float, rng: RandomNumberGenerator,
		noise: FastNoiseLite, height_noise: FastNoiseLite, per_mesh: Dictionary, sprigs: Array[Vector3]) -> void:
	var x := area.position.x
	while x <= area.end.x:
		var z := area.position.y
		while z <= area.end.y:
			var p := Vector3(x + rng.randf_range(-0.4, 0.4) * spacing, 0.0, z + rng.randf_range(-0.4, 0.4) * spacing)
			# densidade cresce do limite pro centro da mancha
			var density := clampf((noise.get_noise_2d(p.x, p.z) - grass_threshold) / 0.25, 0.0, 1.0)
			# na terra não nasce nada; no degradê a grama vai rareando
			var dirt := _dirt_amount(p.x, p.z)
			if dirt > 0.0 and rng.randf() < dirt * 1.6:
				z += spacing
				continue
			if density > 0.0 and rng.randf() < density:
				p.y = data.get_height(p)
				var wave := (height_noise.get_noise_2d(p.x, p.z) + 1.0) * 0.5
				# densa (meio da mancha) cresce até +grass_dense_growth; a onda só varia
				# entre 70% e 100% desse crescimento, pra não ficarem todos iguais
				var h := 1.0 + grass_dense_growth * smoothstep(0.2, 0.9, density) * lerpf(0.7, 1.0, wave)
				var s := rng.randf_range(grass_scale.x, grass_scale.y)
				var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * h, s))
				var id: int = ids[rng.randi() % ids.size()]
				if not edge_ids.is_empty() and density < edge_density:
					# beiradinha (metade de baixo) = último tufo de borda; rala = o primeiro
					var k := 0 if density > edge_density * 0.5 else edge_ids.size() - 1
					id = edge_ids[k]
				if not sprig_mesh_ids.is_empty() and density >= sprig_min_density and rng.randf() < sprig_chance and _far_from(sprigs, p, sprig_min_distance):
					sprigs.append(p)
					id = sprig_mesh_ids[rng.randi() % sprig_mesh_ids.size()]
					# sempre acima da grama em volta: cresce junto com os tufos (h) e
					# ainda fica `sprig_over` mais alto
					b = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * h * rng.randf_range(sprig_over.x, sprig_over.y))
				(per_mesh[id] as Array[Transform3D]).append(Transform3D(b, p))
			z += spacing
		x += spacing

## Montes de flores de um tipo só. Com caule: cada flor tem que estar BEM dentro
## da grama (mesma mancha de ruído da semeadura); a branca: só fora da grama.
func _seed_flowers(half: float, rng: RandomNumberGenerator, noise: FastNoiseLite, per_mesh: Dictionary) -> void:
	if flower_head_ids.is_empty():
		return
	var placed: Array[Vector3] = []  # (x, z, raio) de todas as flores já postas
	var total := 0.0
	for w in flower_weights:
		total += w
	for c in flower_clumps:
		var k := 0
		var pick := rng.randf() * total
		for i in flower_weights.size():
			pick -= flower_weights[i]
			if pick <= 0.0:
				k = i
				break
		var center := Vector2.ZERO
		var ok := false
		for _try in 30:
			center = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
			if _flower_spot_ok(k, center, noise):
				ok = true
				break
		if not ok:
			continue
		var mult := flower_clump_mult[k] if k < flower_clump_mult.size() else 1.0
		var cr := flower_clump_radius * sqrt(mult)
		# monte REDONDO e cheio: tenta várias vezes até pôr as `want` flores dentro do
		# círculo (antes desistia na 1ª batida e o monte virava risquinhos soltos)
		var want := roundi(rng.randi_range(flower_clump_size.x, flower_clump_size.y) * mult)
		var got := 0
		for j in want * 8:
			if got >= want:
				break
			var r := sqrt(rng.randf()) * cr
			var a := rng.randf() * TAU
			var q := center + Vector2(cos(a), sin(a)) * r
			if not _flower_spot_ok(k, q, noise):
				continue
			var sc := rng.randf_range(flower_size.x, flower_size.y) * lerpf(1.0, 0.75, r / cr) * flower_scales[k]
			var rad := sc * flower_spread
			var free := true
			for o in placed:
				if Vector2(q.x - o.x, q.y - o.y).length() < rad + o.z:
					free = false
					break
			if not free:
				continue
			placed.append(Vector3(q.x, q.y, rad))
			got += 1
			var p := Vector3(q.x, 0.0, q.y)
			p.y = data.get_height(p)
			var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), p)
			(per_mesh[flower_head_ids[k]] as Array[Transform3D]).append(t)
			if flower_stem_ids[k] >= 0:
				(per_mesh[flower_stem_ids[k]] as Array[Transform3D]).append(t)

func _seed_bushes(half: float, rng: RandomNumberGenerator, noise: FastNoiseLite, per_mesh: Dictionary) -> void:
	if bush_mesh_ids.is_empty():
		return
	var spots: Array[Vector3] = []
	for _try in bush_count * 40:
		if spots.size() >= bush_count:
			break
		var p := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		# fora do meio denso da grama (na borda ou no chão limpo)
		if noise.get_noise_2d(p.x, p.z) > grass_threshold + 0.15:
			continue
		if not _far_from(spots, p, bush_min_distance):
			continue
		spots.append(p)
		p.y = data.get_height(p)
		var s := rng.randf_range(bush_scale.x, bush_scale.y)
		var id: int = bush_mesh_ids[rng.randi() % bush_mesh_ids.size()]
		if not bush_flower_mesh_ids.is_empty() and rng.randf() < bush_flower_chance:
			id = bush_flower_mesh_ids[rng.randi() % bush_flower_mesh_ids.size()]
		(per_mesh[id] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), p))

## Pedras no chão limpo (fora das manchas de grama), longe umas das outras.
func _seed_rocks(half: float, rng: RandomNumberGenerator, noise: FastNoiseLite, per_mesh: Dictionary,
		ids: PackedInt32Array, count: int, min_dist: float, scale: Vector2) -> void:
	if ids.is_empty():
		return
	var spots: Array[Vector3] = []
	for _try in count * 40:
		if spots.size() >= count:
			break
		var p := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		if noise.get_noise_2d(p.x, p.z) > grass_threshold - 0.04:
			continue
		if not _far_from(spots, p, min_dist):
			continue
		spots.append(p)
		p.y = data.get_height(p)
		var sc := rng.randf_range(scale.x, scale.y)
		var id: int = ids[rng.randi() % ids.size()]
		(per_mesh[id] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), p))

func _flower_spot_ok(k: int, q: Vector2, noise: FastNoiseLite) -> bool:
	var density := clampf((noise.get_noise_2d(q.x, q.y) - grass_threshold) / 0.25, 0.0, 1.0)
	if flower_in_grass[k]:
		return density >= flower_in_grass_density
	return noise.get_noise_2d(q.x, q.y) < grass_threshold - 0.02

func _far_from(points: Array[Vector3], p: Vector3, dist: float) -> bool:
	for q in points:
		if Vector2(p.x - q.x, p.z - q.z).length() < dist:
			return false
	return true
