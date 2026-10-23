extends Node3D
## Manchas de névoa VOLUMÉTRICA que andam com o vento (FogVolume + FogMaterial).
## Serve pra poeira levantada do chão (cor terrosa, pequena, rápida) e, no
## futuro, pra neblina (cor clara, grande, lenta): é o mesmo script com outros
## valores. Precisa de `volumetric_fog_enabled` no Environment da cena.
##
## Cada mancha é um FogVolume elipsoide achatado, rente ao chão, com densidade
## irregular por dentro (ruído 3D). Nasce rala, fica densa (aparece), anda na
## direção do vento, rareia e some; depois renasce contra o vento, em volta do
## jogador. Regras em .docs/plans/05-clima.md.

@export var count: int = 8
@export var area: Vector2 = Vector2(36.0, 36.0)        ## onde nascem, em volta do jogador
@export var size_min: Vector3 = Vector3(5.0, 2.0, 3.5) ## tamanho da mancha (m)
@export var size_max: Vector3 = Vector3(9.0, 3.5, 6.5)
@export var color: Color = Color(0.95, 0.85, 0.45)      ## poeira: amarela
@export var density: float = 2.5                       ## densidade no auge
@export var speed: Vector2 = Vector2(1.5, 2.6)         ## m/s na direção do vento
@export var life: Vector2 = Vector2(10.0, 16.0)         ## segundos de cada mancha
@export var noise_scale: float = 0.06                  ## frequência do ruído (maior = gomos menores)
@export var wind_dir: Vector2 = Vector2(1.0, -0.02)
## Segue o estado do vento (wind.gd): menos manchas e mais lentas no calmo.
@export var follow_wind: bool = true

class Patch:
	var vol: FogVolume
	var mat: FogMaterial
	var age := 0.0
	var life := 1.0
	var speed := 1.0

var _patches: Array[Patch] = []
var _player: Node3D
var _rng := RandomNumberGenerator.new()
var _noise_tex: NoiseTexture3D

func _ready() -> void:
	_rng.randomize()
	# ruído "couve-flor" (nuvem fofa): Perlin com várias oitavas, poucas bolhas
	# grandes por volume e muito detalhe na borda
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.55
	_noise_tex = NoiseTexture3D.new()
	_noise_tex.noise = noise
	_noise_tex.width = 64
	_noise_tex.height = 32
	_noise_tex.depth = 64
	_noise_tex.seamless = true
	_noise_tex.normalize = true
	# contraste: abaixo de ~40% vira vazio, acima de ~70% fica cheio. É o que
	# dá os "gomos" e buracos da nuvem, em vez de um véu uniforme
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 0.72, 1.0])
	ramp.colors = PackedColorArray([Color.BLACK, Color.BLACK, Color.WHITE, Color.WHITE])
	_noise_tex.color_ramp = ramp
	for i in count:
		var p := Patch.new()
		p.vol = FogVolume.new()
		p.vol.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		p.mat = FogMaterial.new()
		p.mat.albedo = color
		p.mat.density_texture = _noise_tex
		p.mat.edge_fade = 0.15  # borda curta: os gomos do ruído é que fazem o contorno fofo
		p.mat.height_falloff = 0.8  # densa embaixo, topo em gomos (como camada de nuvem)
		p.vol.material = p.mat
		add_child(p.vol)
		_patches.append(p)
		_respawn(p, true)

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	var wind_k := 1.0
	var amount := 1.0
	if follow_wind:
		var w := get_tree().get_first_node_in_group(&"wind_system")
		if w != null:
			var s: float = w.strength
			wind_k = clampf(0.6 + s, 0.6, 1.6)
			amount = clampf(0.6 + s * 1.0, 0.6, 1.0)
	var dir := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	for p in _patches:
		p.age += delta
		if p.age >= p.life:
			_respawn(p, false)
			continue
		var t := p.age / p.life
		# aparece, fica, some (densidade é o que "acende" a névoa)
		var fade := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.6, 1.0, t))
		p.mat.density = density * fade * amount
		p.vol.global_position += dir * p.speed * wind_k * delta
		# cresce um pouco enquanto anda (a poeira se espalha)
		p.vol.scale = Vector3.ONE * lerpf(0.75, 1.15, t)

func _respawn(p: Patch, first: bool) -> void:
	p.age = _rng.randf_range(0.0, p.life) if first else 0.0
	p.life = _rng.randf_range(life.x, life.y)
	p.speed = _rng.randf_range(speed.x, speed.y)
	p.vol.size = Vector3(
		_rng.randf_range(size_min.x, size_max.x),
		_rng.randf_range(size_min.y, size_max.y),
		_rng.randf_range(size_min.z, size_max.z))
	p.vol.rotation.y = atan2(-wind_dir.y, wind_dir.x) + _rng.randf_range(-0.3, 0.3)  # alongada no vento
	var center := _player.global_position if _player else Vector3.ZERO
	# nasce do lado de onde o vento vem, pra atravessar a área do jogador
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -area.x * 0.3
	p.vol.global_position = Vector3(
		center.x + back.x + _rng.randf_range(-area.x, area.x) * 0.5,
		p.vol.size.y * 0.35,
		center.z + back.z + _rng.randf_range(-area.y, area.y) * 0.5)
	p.mat.density = 0.0
