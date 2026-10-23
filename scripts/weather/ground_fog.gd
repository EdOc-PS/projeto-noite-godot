extends FogVolume
## Névoa rasteira do cenário todo (shaders/weather/ground_fog.gdshader): uma
## caixa larga e baixa que acompanha o jogador (a névoa volumétrica só é
## calculada até `volumetric_fog_length` da câmera, então não precisa cobrir o
## mapa inteiro). O ruído 3D é ancorado no MUNDO, então a névoa não "anda junto"
## com o jogador: só a caixa se move. Precisa de `volumetric_fog_enabled` no
## Environment. Regras em .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/ground_fog.gdshader")

@export var area: float = 80.0                     ## lado da caixa (m)
@export var fog_color: Color = Color(1, 1, 1)      ## branca por enquanto
@export var fog_density: float = 1.6
@export var fog_height: float = 1.6                ## m acima do chão
@export var wind_speed: float = 0.6                ## m/s
@export var wind_dir: Vector2 = Vector2(1.0, -0.02)

var _player: Node3D
var _mat: ShaderMaterial

func _ready() -> void:
	shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	size = Vector3(area, fog_height * 2.5, area)
	# ruído 3D repetível (seamless): um tile serve pro mundo todo
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	var tex := NoiseTexture3D.new()
	tex.noise = noise
	tex.width = 64
	tex.height = 64
	tex.depth = 64
	tex.seamless = true
	tex.normalize = true
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter(&"noise_tex", tex)
	_mat.set_shader_parameter(&"fog_color", fog_color)
	_mat.set_shader_parameter(&"density", fog_density)
	_mat.set_shader_parameter(&"fog_height", fog_height)
	var d := wind_dir.normalized() * wind_speed
	_mat.set_shader_parameter(&"wind", Vector3(d.x, 0.0, d.y))
	material = _mat

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, size.y * 0.5, _player.global_position.z)
