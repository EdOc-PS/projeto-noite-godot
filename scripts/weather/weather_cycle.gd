extends Node
## Clima da cena: ciclo de dia e noite + chuva.
## Ciclo: a cena sempre começa de dia e vai passando por
## manhã → tarde (laranja) → noite ao longo de `cycle_duration` segundos.
## Ao chegar na noite, para. Regras em .docs/plans/06-clima.md.
##
## Controla: pesos do céu (shaders/weather/day_night_sky.gdshader), cor/força/ângulo
## da luz principal, luz ambiente e névoa.

@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var color_grade: Node  ## opcional: ColorGrade (LUT só de dia, some à noite)
@export var reflection_probe: ReflectionProbe  ## re-captura enquanto a hora muda (senão reflete o céu de dia a noite toda)
## Segundos entre re-capturas do reflexo durante o ciclo. 0 = todo frame (suave, mas
## pesado: renderiza a cena 6x por frame). Com intervalo o reflexo muda em saltos (pisca).
@export var probe_interval: float = 0.0
## Céu da noite: o MESMO material do outside (PanoramaSkyMaterial, nebulosa 0,6).
## Quando a noite chega, troca o shader de mistura por ele.
@export var night_sky_material: Material  ## (não usado: a troca de material piscava; o shader na noite já é igual ao céu do outside)
@export var rain: Node  ## opcional: Rain (scripts/weather/rain.gd)
@export var rain_fade_time: float = 3.0  ## segundos pra chuva entrar/sair
## Quanto a chuva escurece/acinzenta a cena (na intensidade 1)
@export_range(0.0, 1.0) var rain_sun_dim: float = 0.45
@export_range(0.0, 1.0) var rain_desaturate: float = 0.2
## Tom de dia chuvoso (estilo Stardew): a cena puxa pra azul-acinzentado.
@export var rain_tint: Color = Color(0.55, 0.64, 0.82)
@export_range(0.0, 1.0) var rain_tint_amount: float = 0.6
@export_range(0.0, 1.0) var rain_shadow_opacity: float = 0.35  ## sombras quase somem (céu nublado)
@export var rain_fog_density: float = 0.006                   ## névoa leve de chuva (também de dia)
## Molhado: quanto tempo pra encharcar e pra secar
@export var wet_time: float = 8.0
@export var dry_time: float = 30.0
## À noite os riscos de vento ficam nessa fração (menos vento).
@export_range(0.0, 1.0) var night_wind: float = 0.35
@export var cycle_duration: float = 60.0  ## segundos do dia até a noite
@export_range(0.0, 1.0) var start_phase: float = 0.0  ## 0 = dia, 1 = noite
## Paleta das fases: VINIL (padrão, Link's Awakening) ou BOTW (campo, plano 16-estilo-botw.md).
enum Palette { VINIL, BOTW }
@export var palette: Palette = Palette.VINIL

## Fases-chave do ciclo (phase 0..1). Entre duas, os valores são interpolados.
## Padrão visual: cores vivas de brinquedo (Link's Awakening), nunca lavado.
## Ver tabela em .docs/plans/06-clima.md.
const KEYS := [
	{ "phase": 0.0, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 1.0, "sun_pitch": -52.0,
	  "ambient": Color(0.78, 0.74, 0.66), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.82, 0.86, 0.8), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.2, "saturation": 1.5, "contrast": 1.12, "shadow_soft": 0.3, "grade": 0.0 },
	{ "phase": 0.35, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 0.95, "sun_pitch": -46.0,
	  "ambient": Color(0.78, 0.74, 0.66), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.82, 0.86, 0.8), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.2, "saturation": 1.5, "contrast": 1.12, "shadow_soft": 0.3, "grade": 0.0 },
	{ "phase": 0.55, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.66, 0.42), "sun_energy": 1.05, "sun_pitch": -38.0,
	  "ambient": Color(0.78, 0.56, 0.72), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.9, 0.75, 0.65), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.3, "saturation": 1.45, "contrast": 1.12, "shadow_soft": 0.4, "grade": 0.0 },
	{ "phase": 0.7, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.55, 0.42), "sun_energy": 0.9, "sun_pitch": -32.0,
	  "ambient": Color(0.62, 0.44, 0.74), "ambient_energy": 0.5, "sky_contrib": 0.3,
	  "fog": Color(0.6, 0.42, 0.62), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.4, "saturation": 1.4, "contrast": 1.12, "shadow_soft": 0.6, "grade": 0.0 },
	{ "phase": 0.9, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 0.8, "sun_pitch": -37.0,
	  "ambient": Color(0.4, 0.44, 0.65), "ambient_energy": 0.45, "sky_contrib": 1.0,
	  "fog": Color(0.106, 0.137, 0.251), "fog_density": 0.008, "fog_height_density": 0.45,
	  "glow": 0.7, "saturation": 1.3, "contrast": 1.12, "shadow_soft": 1.5, "grade": 0.0 },
	{ "phase": 1.0, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 0.8, "sun_pitch": -37.0,
	  "ambient": Color(0.4, 0.44, 0.65), "ambient_energy": 0.45, "sky_contrib": 1.0,
	  "fog": Color(0.106, 0.137, 0.251), "fog_density": 0.008, "fog_height_density": 0.45,
	  "glow": 0.7, "saturation": 1.3, "contrast": 1.12, "shadow_soft": 1.5, "grade": 0.0 },
]

## Paleta BotW: tudo mais claro e vivo, sombra clara (céu forte na luz
## ambiente), noite azul e legível em vez de escura. Plano 16-estilo-botw.md.
const KEYS_BOTW := [
	{ "phase": 0.0, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.96, 0.86), "sun_energy": 1.45, "sun_pitch": -52.0,
	  "ambient": Color(0.78, 0.88, 1.0), "ambient_energy": 1.15, "sky_contrib": 0.55,
	  "fog": Color(0.75, 0.84, 0.93), "fog_density": 0.005, "fog_height_density": 0.0, "fog_max": 0.45, "fog_begin": 34.0, "fog_end": 80.0,
	  "glow": 0.15, "saturation": 1.5, "contrast": 0.92, "shadow_soft": 0.6, "shadow_op": 0.55, "grade": 0.0 },
	{ "phase": 0.35, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.94, 0.8), "sun_energy": 1.4, "sun_pitch": -46.0,
	  "ambient": Color(0.8, 0.88, 1.0), "ambient_energy": 1.1, "sky_contrib": 0.55,
	  "fog": Color(0.8, 0.86, 0.9), "fog_density": 0.005, "fog_height_density": 0.0, "fog_max": 0.45, "fog_begin": 34.0, "fog_end": 80.0,
	  "glow": 0.15, "saturation": 1.5, "contrast": 0.92, "shadow_soft": 0.6, "shadow_op": 0.55, "grade": 0.0 },
	{ "phase": 0.55, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.74, 0.46), "sun_energy": 1.35, "sun_pitch": -38.0,
	  "ambient": Color(0.98, 0.76, 0.78), "ambient_energy": 1.0, "sky_contrib": 0.5,
	  "fog": Color(1.0, 0.8, 0.62), "fog_density": 0.005, "fog_height_density": 0.0, "fog_max": 0.55, "fog_begin": 30.0, "fog_end": 68.0,
	  "glow": 0.25, "saturation": 1.4, "contrast": 0.92, "shadow_soft": 0.7, "shadow_op": 0.5, "grade": 0.0 },
	{ "phase": 0.7, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.6, 0.45), "sun_energy": 1.15, "sun_pitch": -32.0,
	  "ambient": Color(0.85, 0.66, 0.95), "ambient_energy": 0.95, "sky_contrib": 0.5,
	  "fog": Color(0.9, 0.66, 0.78), "fog_density": 0.005, "fog_height_density": 0.0, "fog_max": 0.6, "fog_begin": 28.0, "fog_end": 60.0,
	  "glow": 0.3, "saturation": 1.4, "contrast": 0.92, "shadow_soft": 0.8, "shadow_op": 0.5, "grade": 0.0 },
	{ "phase": 0.9, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 1.0, "sun_pitch": -37.0,
	  "ambient": Color(0.42, 0.48, 0.72), "ambient_energy": 0.65, "sky_contrib": 1.0,
	  "fog": Color(0.2, 0.26, 0.4), "fog_density": 0.006, "fog_height_density": 0.0, "fog_max": 0.7, "fog_begin": 16.0, "fog_end": 36.0,
	  "glow": 0.2, "saturation": 1.45, "contrast": 0.92, "shadow_soft": 0.6, "shadow_op": 0.4, "grade": 0.0 },
	{ "phase": 1.0, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 1.0, "sun_pitch": -37.0,
	  "ambient": Color(0.42, 0.48, 0.72), "ambient_energy": 0.65, "sky_contrib": 1.0,
	  "fog": Color(0.2, 0.26, 0.4), "fog_density": 0.006, "fog_height_density": 0.0, "fog_max": 0.7, "fog_begin": 16.0, "fog_end": 36.0,
	  "glow": 0.2, "saturation": 1.45, "contrast": 0.92, "shadow_soft": 0.6, "shadow_op": 0.4, "grade": 0.0 },
]

var phase := 0.0
var paused := false
var raining := false    ## chuva ligada (alvo); a intensidade chega aos poucos
var rain_amount := 0.0  ## 0..1 atual
var wetness := 0.0      ## 0..1: cenário molhado (sobe chovendo, seca devagar)
var _sun_shadow_opacity := 1.0
var _shadow_base := 1.0  ## opacidade da sombra pela hora (chave `shadow_op`, se houver)
var _probe_timer := 0.0
var _probe_frames := 0  ## parado na hora atual (painel de debug)
var _sky_mat: ShaderMaterial
var _sun_rotation: Vector3
var _keys: Array = []

func _ready() -> void:
	phase = start_phase
	if world_environment != null and world_environment.environment.sky != null:
		_sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
	_keys = (KEYS_BOTW if palette == Palette.BOTW else KEYS).duplicate(true)
	if sun != null:
		_sun_rotation = sun.rotation
		_sun_shadow_opacity = sun.shadow_opacity
		# noite = exatamente a lua da cena (mesmo ângulo do outside)
		# (a paleta BOTW tem a lua própria, mais de cima)
		if palette != Palette.BOTW:
			for k in _keys:
				if k.night >= 1.0:
					k.sun_pitch = rad_to_deg(_sun_rotation.x)
	_apply()

func _process(delta: float) -> void:
	_update_rain(delta)
	if _probe_frames > 0:
		_probe_frames -= 1
		if _probe_frames == 0 and reflection_probe != null:
			reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	# chuva é um clima à parte: enquanto chove, a hora não anda
	if paused or raining or phase >= 1.0:
		return
	phase = minf(phase + delta / cycle_duration, 1.0)
	_apply()
	if reflection_probe != null:
		# re-captura de tempos em tempos durante o ciclo (UPDATE_ALWAYS renderizava
		# a cena 6 vezes por frame: derrubava o FPS de dia e na troca de hora)
		_probe_timer -= delta
		if probe_interval <= 0.0:
			# todo frame durante o ciclo; ao chegar na noite, fixa
			var mode := ReflectionProbe.UPDATE_ONCE if phase >= 1.0 else ReflectionProbe.UPDATE_ALWAYS
			if reflection_probe.update_mode != mode:  # só quando muda: reatribuir todo frame reiniciava a captura (piscava)
				reflection_probe.update_mode = mode
		elif _probe_timer <= 0.0 or phase >= 1.0:
			# captura por 2 frames e fixa (ver o começo do _process)
			_probe_timer = probe_interval
			reflection_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
			_probe_frames = 2

## Pula pra uma hora (0 = dia, ~0,62 = tarde, 1 = noite). Usado pelo painel de debug.
func set_phase(p: float) -> void:
	if raining:
		return  # chuva é um clima à parte: não troca a hora enquanto chove
	phase = clampf(p, 0.0, 1.0)
	_apply()
	if reflection_probe != null:
		# captura de novo por alguns frames e fixa (ver _process)
		reflection_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
		_probe_frames = 3

## Liga/desliga a chuva (entra e sai aos poucos, em `rain_fade_time`).
func set_raining(on: bool) -> void:
	raining = on

func _update_rain(delta: float) -> void:
	# molhado: sobe enquanto chove, seca devagar depois
	var wet_target := rain_amount
	if not is_equal_approx(wetness, wet_target):
		var t := wet_time if wet_target > wetness else dry_time
		wetness = move_toward(wetness, wet_target, delta / maxf(t, 0.01))
		RenderingServer.global_shader_parameter_set(&"weather_wetness", wetness)  # toon e água escorrendo
		for n in get_tree().get_nodes_in_group("wet_receivers"):
			n.set_wetness(wetness)
	var target := 1.0 if raining else 0.0
	if is_equal_approx(rain_amount, target):
		return
	rain_amount = move_toward(rain_amount, target, delta / maxf(rain_fade_time, 0.01))
	if rain != null:
		rain.set_intensity(rain_amount)
	for n in get_tree().get_nodes_in_group("rain_fx"):
		n.set_intensity(rain_amount)
	_apply()

## Volta pro começo do dia e continua andando.
func restart() -> void:
	if raining:
		return
	paused = false
	set_phase(0.0)

func _apply() -> void:
	var a: Dictionary = _keys[0]
	var b: Dictionary = _keys[0]
	for i in _keys.size() - 1:
		if phase <= _keys[i + 1].phase:
			a = _keys[i]
			b = _keys[i + 1]
			break
	var span: float = b.phase - a.phase
	var t: float = 0.0 if span <= 0.0 else smoothstep(0.0, 1.0, (phase - a.phase) / span)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("dusk_weight", lerpf(a.dusk, b.dusk, t))
		_sky_mat.set_shader_parameter("night_weight", lerpf(a.night, b.night, t))
	if sun != null:
		sun.light_color = a.sun_color.lerp(b.sun_color, t)
		sun.light_energy = lerpf(a.sun_energy, b.sun_energy, t) * (1.0 - rain_dim())
		sun.light_angular_distance = lerpf(a.shadow_soft, b.shadow_soft, t)
		_shadow_base = lerpf(a.get("shadow_op", _sun_shadow_opacity), b.get("shadow_op", _sun_shadow_opacity), t)
		sun.shadow_opacity = _shadow_base
		sun.rotation = Vector3(deg_to_rad(lerpf(a.sun_pitch, b.sun_pitch, t)), _sun_rotation.y, _sun_rotation.z)
	if world_environment != null:
		var env := world_environment.environment
		env.ambient_light_color = a.ambient.lerp(b.ambient, t)
		env.ambient_light_energy = lerpf(a.ambient_energy, b.ambient_energy, t)
		env.ambient_light_sky_contribution = lerpf(a.sky_contrib, b.sky_contrib, t)
		env.fog_height_density = lerpf(a.fog_height_density, b.fog_height_density, t)
		env.glow_intensity = lerpf(a.glow, b.glow, t)
		env.adjustment_saturation = lerpf(a.saturation, b.saturation, t) * (1.0 - rain_desaturate * rain_amount)
		env.adjustment_contrast = lerpf(a.contrast, b.contrast, t)
		env.fog_light_color = a.fog.lerp(b.fog, t)
		env.fog_density = lerpf(a.fog_density, b.fog_density, t)
		if a.has("fog_begin"):
			# névoa de DISTÂNCIA (não chapada): começa depois do jogador e esconde
			# a borda do mapa; mais perto e densa à noite
			env.fog_mode = Environment.FOG_MODE_DEPTH
			env.fog_depth_begin = lerpf(a.fog_begin, b.fog_begin, t)
			env.fog_depth_end = lerpf(a.fog_end, b.fog_end, t)
			# no modo distância, fog_density é a força MÁXIMA lá longe (0..1)
			env.fog_density = lerpf(a.fog_max, b.fog_max, t)
	_apply_rain_tone()
	if color_grade != null:
		color_grade.set_strength(lerpf(a.grade, b.grade, t))
	var night_w := lerpf(a.night, b.night, t)
	_apply_night_fx(night_w)
	# vagalumes: vão surgindo aos poucos desde o fim da tarde (grupo `firefly_fx`)
	var ff := smoothstep(0.62, 0.97, phase) * (1.0 - rain_amount)
	for n in get_tree().get_nodes_in_group("firefly_fx"):
		n.visible = ff > 0.005
		n.emitting = ff > 0.005
		n.amount_ratio = ff
	_apply_day_fx(night_w)

## Tom de dia chuvoso por cima da hora atual (Stardew): azul-acinzentado,
## céu fechado, sombras fracas, névoa leve. Proporcional a `rain_amount`.
func _apply_rain_tone() -> void:
	var r := rain_amount
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("rain_weight", r)  # céu nublado cinza (day_night_sky)
	if sun != null:
		sun.light_color = sun.light_color.lerp(rain_tint, rain_tint_amount * r)
		sun.shadow_opacity = lerpf(_shadow_base, rain_shadow_opacity, r)
	if world_environment != null:
		var env := world_environment.environment
		env.ambient_light_color = env.ambient_light_color.lerp(rain_tint, rain_tint_amount * r)
		env.fog_light_color = env.fog_light_color.lerp(rain_tint * 0.6, r * 0.5)
		env.fog_density = maxf(env.fog_density, rain_fog_density * r)

## Chuva escurece o sol (céu fechado)
func rain_dim() -> float:
	return rain_sun_dim * rain_amount

## Efeitos que só existem à noite (grupo `night_fx`): vagalumes e névoa de
## borda. Vão surgindo no anoitecer junto com o céu (0 = some, 1 = como no outside).
var _fx_density := {}  # ShaderMaterial -> densidade original
func _apply_night_fx(w: float) -> void:
	for n in get_tree().get_nodes_in_group("night_fx"):
		n.visible = w > 0.01
		if n is GPUParticles3D:
			n.amount_ratio = w
		elif n is MeshInstance3D and n.mesh != null:
			var mat := n.mesh.surface_get_material(0) as ShaderMaterial
			if mat != null:
				if not _fx_density.has(mat):
					_fx_density[mat] = mat.get_shader_parameter("density")
				mat.set_shader_parameter("density", _fx_density[mat] * w)

func _exit_tree() -> void:
	# o calor é global (tilt-shift de toda cena): não deixar ligado na próxima
	RenderingServer.global_shader_parameter_set(&"heat_haze", 0.0)

## Efeitos de dia (manhã/tarde), o contrário dos noturnos:
## - nuvens com sombra passando (grupo `cloud_fx`): somem à noite;
## - folhas voando (grupo `day_fx`): somem à noite e na chuva;
## - riscos de vento (grupo `wind_fx`): à noite ficam em `night_wind` e somem na chuva.
func _apply_day_fx(night_w: float) -> void:
	var day := 1.0 - night_w
	for n in get_tree().get_nodes_in_group("cloud_fx"):
		n.set_strength(day)
	var leaves := day * (1.0 - rain_amount)
	for n in get_tree().get_nodes_in_group("day_fx"):
		n.amount_ratio = leaves
		n.emitting = leaves > 0.01
	var dry := 1.0 - rain_amount
	# partículas de luz: cheias de manhã, somem até a tarde
	var morning := day * dry * (1.0 - smoothstep(0.25, 0.5, phase))
	for n in get_tree().get_nodes_in_group("morning_fx"):
		n.amount_ratio = morning
		n.emitting = morning > 0.01
	# orvalho: a manhã toda (até ~35%), some na passagem pra tarde
	var dew := day * dry * (1.0 - smoothstep(0.3, 0.45, phase))
	for n in get_tree().get_nodes_in_group("dew_fx"):
		n.amount_ratio = dew
		n.emitting = dew > 0.01
	# raios de sol: sutis de manhã, fortes à tarde, na cor do sol
	var rays := day * dry * lerpf(0.5, 1.0, smoothstep(0.35, 0.6, phase))
	for n in get_tree().get_nodes_in_group("ray_fx"):
		n.set_light(rays, sun.light_color if sun != null else Color.WHITE)
	# ar tremendo de calor: só perto do meio-dia (no tilt-shift, global)
	var heat := smoothstep(0.1, 0.22, phase) * (1.0 - smoothstep(0.38, 0.52, phase)) * dry
	RenderingServer.global_shader_parameter_set(&"heat_haze", heat)
	var wind := lerpf(1.0, night_wind, night_w) * (1.0 - rain_amount)
	# com um Wind na cena (scripts/weather/wind.gd), a quantidade de riscos é dele
	var wind_system := get_tree().get_first_node_in_group("wind_system")
	for n in get_tree().get_nodes_in_group("wind_fx"):
		if wind_system == null:
			n.amount_ratio = wind
		if n.has_method(&"set_night"):
			n.set_night(night_w)
		if wind_system == null:
			n.emitting = wind > 0.01
