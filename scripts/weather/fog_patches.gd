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

@export var count: int = 5
@export var area: Vector2 = Vector2(36.0, 36.0)        ## onde nascem, em volta do jogador
@export var size_min: Vector3 = Vector3(5.0, 1.2, 3.0) ## tamanho da mancha (m)
@export var size_max: Vector3 = Vector3(9.0, 2.2, 6.0)
@export var color: Color = Color(0.86, 0.78, 0.6)      ## poeira: terroso claro
@export var density: float = 0.6                       ## densidade no auge
@export var speed: Vector2 = Vector2(1.5, 2.6)         ## m/s na direção do vento
@export var life: Vector2 = Vector2(6.0, 10.0)         ## segundos de cada mancha
@export var noise_scale: float = 0.35                  ## frequência do ruído (maior = mais fofo/picado)
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
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = noise_scale
	noise.fractal_octaves = 3
	_noise_tex = NoiseTexture3D.new()
	_noise_tex.noise = noise
	_noise_tex.width = 48
	_noise_tex.height = 24
	_noise_tex.depth = 48
	_noise_tex.seamless = true
	for i in count:
		var p := Patch.new()
		p.vol = FogVolume.new()
		p.vol.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		p.mat = FogMaterial.new()
		p.mat.albedo = color
		p.mat.density_texture = _noise_tex
		p.mat.edge_fade = 0.35
		p.mat.height_falloff = 0.4  # mais densa embaixo (levantando do chão)
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
			amount = clampf(0.35 + s * 1.2, 0.35, 1.0)
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
