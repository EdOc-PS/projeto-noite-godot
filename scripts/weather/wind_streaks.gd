extends GPUParticles3D
## Riscos de vento (estilo Death's Door / Zelda): linhas brancas finas que
## passam na direção do vento, com um leve vai-e-volta (nado de tubarão), e somem.
## Cada risco é o rastro (trail) de uma partícula, com malha em cruz pra ser
## visível de qualquer ângulo. O emissor acompanha o jogador, então sempre há
## riscos na área da câmera, sem precisar cobrir o mapa inteiro.
## Configurado todo aqui; ajuste pelos exports.

const SWIM_SHADER := preload("res://shaders/weather/wind_streak_particles.gdshader")

@export var wind_dir: Vector2 = Vector2(1.0, 0.3)  ## mesmo vento do wind_sway
@export var streak_count: int = 4                  ## riscos ao mesmo tempo (poucos = sutil)
@export var speed: float = 6.0
@export var area: Vector2 = Vector2(14.0, 10.0)    ## área em volta do jogador onde nascem
@export var height_range: Vector2 = Vector2(0.4, 2.2)
@export var streak_color: Color = Color(0.85, 0.9, 1.0, 0.35)
## Cor à noite (o WeatherCycle mistura pela hora). Alfa 0 = usa `streak_color` sempre.
@export var night_color: Color = Color(0, 0, 0, 0)
@export var width: float = 0.035
## Velocidade sorteada por risco (multiplicador): como o rastro dura o mesmo
## tempo, risco mais rápido = mais COMPRIDO. Faixa larga = comprimentos variados.
@export var speed_range: Vector2 = Vector2(0.8, 1.2)
## "Nado de tubarão": vai e volta pros lados enquanto passa (m/s; 0 = reto).
## Opacidade sorteada por risco (multiplica o alfa de `streak_color`).
@export var alpha_range: Vector2 = Vector2(0.3, 0.7)
@export var swim_amp: float = 0.7
@export var swim_freq: float = 0.6        ## vai-e-volta por segundo
## (antigos, sem uso: a ondulação por turbulência dava trancos e laços)
@export var curl: float = 0.0
@export var curl_size: float = 4.0
## Duração do rastro (s): comprimento do risco = velocidade × isso.
@export var trail_length: float = 1.0
## Largura sorteada por risco (multiplicador da `width`): uns finos, outros grossos.
@export var width_range: Vector2 = Vector2(1.0, 1.0)

var _player: Node3D

func _ready() -> void:
	add_to_group("wind_fx")  # o WeatherCycle desliga na chuva
	amount = streak_count
	lifetime = trail_length + 4.0  # sobra tempo pra aparecer e sumir antes do rastro acabar
	randomness = 1.0
	local_coords = false
	trail_enabled = true
	trail_lifetime = trail_length
	visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 8, 40))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# malha do rastro: fita em cruz, afinando nas pontas
	var ribbon := RibbonTrailMesh.new()
	ribbon.shape = RibbonTrailMesh.SHAPE_CROSS
	ribbon.size = width
	ribbon.sections = 8
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.0))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.0))
	ribbon.curve = taper
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.use_particle_trails = true
	# some perto da câmera (como o Wind VFX da Vefects: "camera depth fade"),
	# pra risco nunca passar colado na tela
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 4.0
	mat.distance_fade_max_distance = 9.0
	mat.albedo_color = streak_color
	_mat = mat
	ribbon.material = mat
	draw_pass_1 = ribbon

	# fade in e fade out ficam no shader de partículas: o rastro guarda a cor dos
	# últimos `trail_lifetime` s, então a ponta some antes da partícula morrer
	# (`fade_end`), senão a cauda ainda visível sumia de uma vez.

	# movimento num shader de partículas próprio: anda reto no vento e faz o
	# "nado de tubarão" (vai e volta leve pros lados num seno), sem turbulência
	var dir := wind_dir.normalized()
	var pm := ShaderMaterial.new()
	pm.shader = SWIM_SHADER
	pm.set_shader_parameter(&"emission_extents", Vector3(area.x * 0.5, (height_range.y - height_range.x) * 0.5, area.y * 0.5))
	pm.set_shader_parameter(&"wind_dir", Vector3(dir.x, 0.0, dir.y))
	pm.set_shader_parameter(&"speed_range", speed_range * speed)
	pm.set_shader_parameter(&"width_range", width_range)
	pm.set_shader_parameter(&"alpha_range", alpha_range)
	pm.set_shader_parameter(&"swim_amp", swim_amp)
	pm.set_shader_parameter(&"swim_freq", swim_freq)
	pm.set_shader_parameter(&"fade_end", clampf(0.95 - trail_lifetime / lifetime, 0.5, 0.95))
	process_material = pm

	position.y = (height_range.x + height_range.y) * 0.5

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	# emissor segue o jogador, um pouco "contra o vento" pra os riscos cruzarem a tela
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -3.0
	global_position = Vector3(_player.global_position.x + back.x, global_position.y, _player.global_position.z + back.z)

var _mat: StandardMaterial3D

## Chamado pelo WeatherCycle: 0 = dia (streak_color), 1 = noite (night_color).
func set_night(w: float) -> void:
	if _mat != null and night_color.a > 0.0:
		_mat.albedo_color = streak_color.lerp(night_color, w)
