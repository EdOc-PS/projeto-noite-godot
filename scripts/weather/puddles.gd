extends MeshInstance3D
## Poças no chão (área plana em volta deste node). Crescem com a chuva e secam
## devagar. Grupo `wet_receivers`: o WeatherCycle chama `set_wetness()`.
## Só pra chão plano (o plano fica em y deste node). Ver .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/puddles.gdshader")

@export var size: Vector2 = Vector2(24.0, 24.0)
@export_range(0.0, 1.0) var coverage: float = 0.38  ## fração do chão que vira poça na chuva cheia

var _mat: ShaderMaterial

func _ready() -> void:
	add_to_group("wet_receivers")
	var plane := PlaneMesh.new()
	plane.size = size
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.normalize = true
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter(&"mask_noise", tex)
	_mat.set_shader_parameter(&"coverage", coverage)
	material_override = _mat
	set_wetness(0.0)

func set_wetness(w: float) -> void:
	_mat.set_shader_parameter(&"wetness", w)
	visible = w > 0.01
