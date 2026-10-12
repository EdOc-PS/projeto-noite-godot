extends Node
## Ciclo de dia e noite: a cena sempre começa de dia e vai passando por
## manhã → tarde (laranja) → noite ao longo de `cycle_duration` segundos.
## Ao chegar na noite, para. Regras em .docs/plans/06-clima.md.
##
## Controla: pesos do céu (shaders/day_night_sky.gdshader), cor/força/ângulo
## da luz principal, luz ambiente, névoa e postes (street_lamp.gd).

@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var cloud_shadows: Decal  ## opcional: sombra das nuvens (cor muda com a hora)
@export var cycle_duration: float = 60.0  ## segundos do dia até a noite
@export_range(0.0, 1.0) var start_phase: float = 0.0  ## 0 = dia, 1 = noite

## Fases-chave do ciclo (phase 0..1). Entre duas, os valores são interpolados.
## Padrão visual: cores vivas de brinquedo (Link's Awakening), nunca lavado.
## Ver tabela em .docs/plans/06-clima.md.
const KEYS := [
	{ "phase": 0.0, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 1.0, "sun_pitch": -60.0,
	  "ambient": Color(0.78, 0.74, 0.66), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.82, 0.86, 0.8), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.2, "saturation": 1.2, "contrast": 1.12, "lamps": 0.0, "cloud": Color(0.1, 0.16, 0.12, 0.35) },
	{ "phase": 0.35, "dusk": 0.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.95, 0.85), "sun_energy": 0.95, "sun_pitch": -45.0,
	  "ambient": Color(0.78, 0.74, 0.66), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.82, 0.86, 0.8), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.2, "saturation": 1.2, "contrast": 1.12, "lamps": 0.0, "cloud": Color(0.1, 0.16, 0.12, 0.35) },
	{ "phase": 0.55, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.74, 0.45), "sun_energy": 1.05, "sun_pitch": -25.0,
	  "ambient": Color(0.9, 0.68, 0.5), "ambient_energy": 0.55, "sky_contrib": 0.25,
	  "fog": Color(0.9, 0.75, 0.65), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.3, "saturation": 1.3, "contrast": 1.15, "lamps": 0.2, "cloud": Color(0.15, 0.1, 0.12, 0.35) },
	{ "phase": 0.7, "dusk": 1.0, "night": 0.0,
	  "sun_color": Color(1.0, 0.62, 0.4), "sun_energy": 0.9, "sun_pitch": -12.0,
	  "ambient": Color(0.85, 0.58, 0.55), "ambient_energy": 0.5, "sky_contrib": 0.3,
	  "fog": Color(0.75, 0.55, 0.55), "fog_density": 0.0, "fog_height_density": 0.0,
	  "glow": 0.4, "saturation": 1.28, "contrast": 1.15, "lamps": 0.5, "cloud": Color(0.12, 0.08, 0.14, 0.4) },
	{ "phase": 0.9, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 0.8, "sun_pitch": -37.0,
	  "ambient": Color(0.4, 0.44, 0.65), "ambient_energy": 0.45, "sky_contrib": 1.0,
	  "fog": Color(0.106, 0.137, 0.251), "fog_density": 0.008, "fog_height_density": 0.45,
	  "glow": 0.7, "saturation": 1.15, "contrast": 1.12, "lamps": 1.0, "cloud": Color(0.04, 0.05, 0.14, 0.6) },
	{ "phase": 1.0, "dusk": 1.0, "night": 1.0,
	  "sun_color": Color(0.62, 0.71, 1.0), "sun_energy": 0.8, "sun_pitch": -37.0,
	  "ambient": Color(0.4, 0.44, 0.65), "ambient_energy": 0.45, "sky_contrib": 1.0,
	  "fog": Color(0.106, 0.137, 0.251), "fog_density": 0.008, "fog_height_density": 0.45,
	  "glow": 0.7, "saturation": 1.15, "contrast": 1.12, "lamps": 1.0, "cloud": Color(0.04, 0.05, 0.14, 0.6) },
]

var phase := 0.0
var _sky_mat: ShaderMaterial
var _sun_rotation: Vector3

func _ready() -> void:
	phase = start_phase
	if world_environment != null and world_environment.environment.sky != null:
		_sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
	if sun != null:
		_sun_rotation = sun.rotation
	_apply()

func _process(delta: float) -> void:
	if phase >= 1.0:
		return
	phase = minf(phase + delta / cycle_duration, 1.0)
	_apply()

func _apply() -> void:
	var a: Dictionary = KEYS[0]
	var b: Dictionary = KEYS[0]
	for i in KEYS.size() - 1:
		if phase <= KEYS[i + 1].phase:
			a = KEYS[i]
			b = KEYS[i + 1]
			break
	var span: float = b.phase - a.phase
	var t: float = 0.0 if span <= 0.0 else smoothstep(0.0, 1.0, (phase - a.phase) / span)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("dusk_weight", lerpf(a.dusk, b.dusk, t))
		_sky_mat.set_shader_parameter("night_weight", lerpf(a.night, b.night, t))
	if sun != null:
		sun.light_color = a.sun_color.lerp(b.sun_color, t)
		sun.light_energy = lerpf(a.sun_energy, b.sun_energy, t)
		sun.rotation = Vector3(deg_to_rad(lerpf(a.sun_pitch, b.sun_pitch, t)), _sun_rotation.y, _sun_rotation.z)
	if world_environment != null:
		var env := world_environment.environment
		env.ambient_light_color = a.ambient.lerp(b.ambient, t)
		env.ambient_light_energy = lerpf(a.ambient_energy, b.ambient_energy, t)
		env.ambient_light_sky_contribution = lerpf(a.sky_contrib, b.sky_contrib, t)
		env.fog_height_density = lerpf(a.fog_height_density, b.fog_height_density, t)
		env.glow_intensity = lerpf(a.glow, b.glow, t)
		env.adjustment_saturation = lerpf(a.saturation, b.saturation, t)
		env.adjustment_contrast = lerpf(a.contrast, b.contrast, t)
		env.fog_light_color = a.fog.lerp(b.fog, t)
		env.fog_density = lerpf(a.fog_density, b.fog_density, t)
	if cloud_shadows != null:
		cloud_shadows.modulate = a.cloud.lerp(b.cloud, t)
	var lamps := lerpf(a.lamps, b.lamps, t)
	for lamp in get_tree().get_nodes_in_group("street_lamps"):
		lamp.intensity = lamps
