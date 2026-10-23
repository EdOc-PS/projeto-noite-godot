extends Node
## Vento da cena (parte do clima, ver "Vento (sistema)" em .docs/plans/05-clima.md).
##
## - Direção FIXA: `wind_dir` (noroeste → sudeste na tela), a mesma dos riscos
##   de vento e das folhas.
## - Estados: CALMO, BRISA, VENTANIA. Cada um dura um tempo sorteado e a troca
##   entre eles é lenta (`transition_time`). Manhã e tarde se comportam igual;
##   à noite puxa pro calmo; na chuva puxa pra ventania.
## - Força varia sozinha (ruído lento por cima do estado): rajadas sem tempo fixo.
## Escreve os globais do shader de vento (wind_sway_body.gdshaderinc):
##   wind_direction, wind_strength (balanço), wind_gust (dobra da grama),
##   wind_gust_slow (dobra das árvores).
## Também comanda os riscos de vento (`wind_fx`), folhas voando e a poeira.

enum State { CALM, BREEZE, GALE }

const STATES := {
	# mais suave que no projeto antigo (a ventania parecia forte demais)
	State.CALM:   { "bend": 0.06, "sway": 0.8, "gustiness": 0.08, "streaks": 0.03, "speed": 0.5 },
	State.BREEZE: { "bend": 0.22, "sway": 0.9, "gustiness": 0.25, "streaks": 0.14, "speed": 0.75 },
	State.GALE:   { "bend": 0.45, "sway": 1.15, "gustiness": 0.4, "streaks": 0.45, "speed": 1.15 },
}

@export var wind_dir: Vector2 = Vector2(1.0, 0.3)            ## direção fixa (mundo)
@export var weather_path: NodePath                           ## WeatherCycle (hora e chuva)
## Cena sem ciclo (outside: só noite): fase fixa. -1 = lê do Weather.
@export_range(-1.0, 1.0) var fixed_phase: float = -1.0
@export var leaves_path: NodePath                            ## WindLeaves (folhas e grama voando)
@export var state_duration: Vector2 = Vector2(20.0, 50.0)    ## segundos em cada estado (sorteado)
@export var transition_time: float = 18.0                    ## segundos pra trocar de estado
@export var start_state: State = State.BREEZE
@export_group("Poeira")
@export var dust_push: float = 0.35        ## quanto a poeira é levada pelo vento

var state: State
var strength := 0.0  ## força atual (0..~1.5), outros sistemas podem ler

var _cur := {}       ## valores atuais (interpolando pro estado alvo)
var _time_left := 0.0
var _t := 0.0
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _weather: Node
var _leaves: Node

func _ready() -> void:
	add_to_group("wind_system")
	_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.frequency = 0.08
	_weather = get_node_or_null(weather_path)
	_leaves = get_node_or_null(leaves_path)
	state = start_state
	_cur = STATES[state].duplicate()
	_time_left = _rng.randf_range(state_duration.x, state_duration.y)
	var d := wind_dir.normalized()
	RenderingServer.global_shader_parameter_set(&"wind_direction", d)

func _process(delta: float) -> void:
	_t += delta
	_time_left -= delta
	if _time_left <= 0.0:
		state = _pick_state()
		_time_left = _rng.randf_range(state_duration.x, state_duration.y)
	# troca lenta: cada valor anda até o do estado alvo
	var target: Dictionary = STATES[state]
	var k := clampf(delta / maxf(transition_time, 0.01) * 3.0, 0.0, 1.0)
	for key in _cur:
		_cur[key] = lerpf(_cur[key], target[key], k)

	# força: estado + ruído lento; as rajadas são os picos do ruído
	var n1 := _noise.get_noise_1d(_t)              # oscilação
	var n2 := maxf(_noise.get_noise_1d(_t * 0.5 + 100.0), 0.0)  # rajadas
	strength = maxf(_cur.bend * (1.0 + 0.4 * n1) + _cur.gustiness * n2 * 1.6, 0.0)

	RenderingServer.global_shader_parameter_set(&"wind_gust", strength)
	RenderingServer.global_shader_parameter_set(&"wind_gust_slow", strength)
	RenderingServer.global_shader_parameter_set(&"wind_strength", _cur.sway * (1.0 + 0.5 * strength))

	_apply_particles()

## Próximo estado: manhã e tarde iguais; noite calma; chuva = ventania.
## 0 = dia/tarde, 1 = noite (pela fase fixa ou do Weather).
func _night() -> float:
	var p := fixed_phase
	if p < 0.0:
		p = _weather.phase if _weather else 0.0
	return smoothstep(0.7, 0.9, p)

func _pick_state() -> State:
	var night := _night()
	var rain: float = _weather.rain_amount if _weather else 0.0
	var w_calm := lerpf(0.25, 0.65, night) * (1.0 - rain)
	var w_breeze := lerpf(0.5, 0.35, night)
	var w_gale := lerpf(0.25, 0.0, night) * (1.0 - rain) + rain * 1.5
	var r := _rng.randf() * (w_calm + w_breeze + w_gale)
	if r < w_calm:
		return State.CALM
	if r < w_calm + w_breeze:
		return State.BREEZE
	return State.GALE

func _apply_particles() -> void:
	var night := _night()
	var rain: float = _weather.rain_amount if _weather else 0.0
	var speed: float = _cur.speed * (1.0 + 0.6 * strength)
	# riscos de vento: mais e mais rápidos quanto mais venta (somem na chuva, como antes)
	var amount: float = clampf(_cur.streaks * (0.6 + 0.6 * strength), 0.0, 1.0) * lerpf(1.0, 0.5, night) * (1.0 - rain)
	for n in get_tree().get_nodes_in_group("wind_fx"):
		var p := n as GPUParticles3D
		p.amount_ratio = amount
		p.emitting = amount > 0.01
		p.speed_scale = speed
	if _leaves:
		for c in _leaves.get_children():
			if c is GPUParticles3D:
				c.speed_scale = speed
	# poeira (de dia e da noite) é levada na direção do vento
	var d := wind_dir.normalized()
	var push := Vector3(d.x, 0.0, d.y) * dust_push * strength
	for group in [&"morning_fx", &"night_fx"]:
		for n in get_tree().get_nodes_in_group(group):
			if n is GPUParticles3D and n.process_material is ParticleProcessMaterial:
				var pm := n.process_material as ParticleProcessMaterial
				if not n.has_meta(&"base_gravity"):
					n.set_meta(&"base_gravity", pm.gravity)
				pm.gravity = (n.get_meta(&"base_gravity") as Vector3) + push

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(&"wind_strength", 1.0)
	RenderingServer.global_shader_parameter_set(&"wind_gust", 0.0)
	RenderingServer.global_shader_parameter_set(&"wind_gust_slow", 0.0)
	RenderingServer.global_shader_parameter_set(&"wind_direction", Vector2.ZERO)
