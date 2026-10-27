extends Node3D
## Folhas e lâminas de grama voando com o vento (manhã e tarde). Uma camada
## de partículas por tipo (cada partícula é UMA folha, nunca as imagens
## juntas): as folhas são sprites Shaded do Kenney Foliage (0081 gota, 0086
## bordo, 0084 recortada), cada folha numa das 3 cores de `leaf_colors`
## (`assets/textures/effects/leaves/`)
## e lâminas de grama no estilo da grama fina. Cada uma nasce com fade in,
## flutua deitada (ondula, sem girar no próprio eixo) e some com fade out. Tamanho
## sorteado. O emissor segue o jogador. Grupo `day_fx`: o WeatherCycle
## controla `amount_ratio` (some à noite e na chuva).
## Regras em .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/wind_leaf.gdshader")

@export var leaf_textures: Array[Texture2D] = [
	preload("res://assets/textures/effects/leaves/leaf_drop.png"),
	preload("res://assets/textures/effects/leaves/leaf_maple.png"),
	preload("res://assets/textures/effects/leaves/leaf_lobed.png"),
]
## Cores das folhas (cada folha sorteia UMA destas, sem tons no meio): verde
## claro da grama, verde do pé/caule da grama, verde amarelado e branco (o dos raminhos).
@export var leaf_colors: PackedColorArray = [Color(0.380, 0.796, 0.545), Color(0.102, 0.518, 0.412), Color(1.000, 0.753, 0.267), Color(1.000, 0.494, 0.267), Color(0.812, 0.325, 0.310), Color(1.0, 1.0, 1.0)]  ## paleta Kenney: verde, verde escuro, amarelo, laranja, vermelho, branco
@export_range(0.0, 1.0) var leaf_alpha: float = 0.9  ## opacidade das folhas
@export var leaves_per_texture: int = 6
@export var area: Vector2 = Vector2(12.0, 10.0)   ## área em volta do jogador onde nascem
@export var height_range: Vector2 = Vector2(0.4, 3.0)
@export var wind_dir: Vector2 = Vector2(1.0, 0.3) ## mesmo vento do resto
@export var speed: Vector2 = Vector2(1.6, 3.0)
@export var leaf_size: float = 0.25               ## tamanho base (m)
@export var size_range: Vector2 = Vector2(0.5, 1.0) ## multiplicador sorteado por folha (nunca grande)

var amount_ratio := 1.0:
	set(v):
		amount_ratio = v
		for p in _emitters:
			p.amount_ratio = v
var emitting := true:
	set(v):
		emitting = v
		for p in _emitters:
			p.emitting = v

var _emitters: Array[GPUParticles3D] = []
var _player: Node3D
var _ground: GPUParticlesCollisionBox3D

func _ready() -> void:
	add_to_group("day_fx")
	# um emissor por folha × cor: cada folha tem UMA das cores, bem definida
	var per_color := maxi(1, roundi(float(leaves_per_texture) / maxi(leaf_colors.size(), 1)))
	for tex in leaf_textures:
		for c in leaf_colors:
			_emitters.append(_make(tex, Vector2(leaf_size, leaf_size), per_color, Color(c, leaf_alpha), true))
	# chão pras folhas pousarem (as partículas só colidem com nós de colisão de partícula)
	_ground = GPUParticlesCollisionBox3D.new()
	_ground.size = Vector3(area.x * 4.0, 1.0, area.y * 4.0)
	add_child(_ground)

func _make(tex: Texture2D, quad_size: Vector2, count: int, tint: Color, palette := false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = 9.0  # voa, pousa, fica um pouco no chão e some devagar
	p.randomness = 0.6
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 8, 40))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# plano DEITADO (horizontal): folha voando de barriga pra baixo, não em pé
	var quad := PlaneMesh.new()
	quad.size = quad_size
	quad.subdivide_width = 8   # pra ondular/curvar macio
	quad.subdivide_depth = 8
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"albedo_tex", tex)
	mat.set_shader_parameter(&"tint", tint)
	mat.set_shader_parameter(&"plane_size", quad_size)  # dobra/onda proporcionais ao tamanho
	if palette:
		# cor vem do tint (uma das `leaf_colors`); o cinza do sprite sombreia
		mat.set_shader_parameter(&"grass_style", 0.0)
		mat.set_shader_parameter(&"rim_strength", 0.08)
	quad.material = mat
	p.draw_pass_1 = quad

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x, (height_range.y - height_range.x) * 0.5, area.y)
	pm.direction = Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	pm.spread = 15.0
	pm.initial_velocity_min = speed.x
	pm.initial_velocity_max = speed.y
	pm.gravity = Vector3(0, -0.45, 0)        # vai descendo enquanto voa: muitas pousam no chão
	pm.turbulence_enabled = true             # sobe e desce no ar
	pm.turbulence_noise_strength = 0.9
	pm.turbulence_noise_scale = 3.0
	# direção sorteada (no plano do chão), sem girar no próprio eixo
	pm.particle_flag_rotate_y = true
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = 0.0
	pm.angular_velocity_max = 0.0
	# não atravessa o chão: encosta e fica (some no fade do fim da vida)
	pm.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	pm.collision_friction = 1.0
	pm.collision_bounce = 0.0
	pm.collision_use_scale = true
	pm.scale_min = size_range.x
	pm.scale_max = size_range.y
	# fade in e fade out
	var fade := Gradient.new()
	# aparece rápido; no fim (já pousada) some devagar
	fade.offsets = PackedFloat32Array([0.0, 0.08, 0.65, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var framp := GradientTexture1D.new()
	framp.gradient = fade
	pm.color_ramp = framp
	p.process_material = pm
	add_child(p)
	return p

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	# nasce "contra o vento" do jogador, pra atravessar a tela
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -6.0
	global_position = Vector3(_player.global_position.x + back.x, (height_range.x + height_range.y) * 0.5, _player.global_position.z + back.z)
	if _ground:
		# topo da caixa rente ao chão (y = 0), embaixo do jogador
		_ground.global_position = Vector3(_player.global_position.x, -0.5, _player.global_position.z)
