extends FogVolume
## Névoa rasteira do cenário todo (shaders/weather/ground_fog.gdshader): uma
## caixa larga e baixa que acompanha o jogador (a névoa volumétrica só é
## calculada até `volumetric_fog_length` da câmera). O ruído é preso ao MUNDO,
## então a névoa não anda junto com o jogador: só a caixa se move.
## Texturas: se `noise_texture` / `detail_texture` ficarem vazias, gera ruído
## por código. As texturas próprias ficam em assets/textures/effects/fog/
## (PNG em tons de cinza, seamless, só o vermelho é lido).
## Precisa de `volumetric_fog_enabled` no Environment. Regras em .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/ground_fog.gdshader")

@export var area: float = 120.0                    ## lado da caixa (m)
@export var fog_height: float = 0.6                ## altura da caixa (m): baixa (fina demais faz faixas)
@export var fog_color: Color = Color(1, 1, 1)      ## branca por enquanto
@export var fog_density: float = 2.411             ## valor do vídeo
@export var move: Vector2 = Vector2.ZERO           ## m/s (0 = parada)
@export_group("Texturas")
@export var noise_texture: Texture2D = preload("res://assets/textures/effects/fog/fog_noise.png")  ## vazio = gera
@export var detail_texture: Texture2D = preload("res://assets/textures/effects/fog/fog_noise.png") ## no vídeo: a mesma textura
@export var color_ramp: Texture2D                  ## cor pela densidade (opcional)

var _player: Node3D

func _ready() -> void:
	shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	size = Vector3(area, fog_height, area)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"noise_tex", noise_texture if noise_texture else _make_noise(0.012, 5, 7))
	mat.set_shader_parameter(&"detail_tex", detail_texture if detail_texture else _make_noise(0.03, 3, 19))
	if color_ramp:
		mat.set_shader_parameter(&"color_ramp", color_ramp)
		mat.set_shader_parameter(&"use_color_ramp", true)
	mat.set_shader_parameter(&"fog_color", fog_color)
	mat.set_shader_parameter(&"density", fog_density)
	mat.set_shader_parameter(&"move", move)
	material = mat

func _make_noise(freq: float, octaves: int, seed_value: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = freq
	n.fractal_octaves = octaves
	n.seed = seed_value
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 512
	t.height = 512
	t.seamless = true
	t.normalize = true
	t.generate_mipmaps = true
	return t

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, size.y * 0.5, _player.global_position.z)
