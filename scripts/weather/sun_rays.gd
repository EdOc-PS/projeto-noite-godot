extends Node3D
## Raios de sol (manhã e tarde): faixas de luz quente atravessando o ar na
## direção do sol, numa área (ex.: entre as árvores). Mais fortes e alaranjados
## à tarde, sutis de manhã, somem à noite e na chuva. Grupo `ray_fx`: o
## WeatherCycle chama `set_light(força, cor)`. Regras em .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/sun_ray.gdshader")

@export var ray_count: int = 7
@export var area: Vector2 = Vector2(5.0, 9.0)     ## meia-área onde os raios ficam
@export var ray_size: Vector2 = Vector2(1.6, 9.0) ## largura × comprimento
@export var sun: DirectionalLight3D               ## direção do sol (vazio = inclinação fixa)
@export var max_strength: float = 0.3  ## forte o bastante pra ver (era 0,12)

var _rays: Array[MeshInstance3D] = []
var _mat: ShaderMaterial

func _ready() -> void:
	add_to_group("ray_fx")
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in ray_count:
		var q := QuadMesh.new()
		q.size = Vector2(ray_size.x * rng.randf_range(0.6, 1.3), ray_size.y * rng.randf_range(0.8, 1.2))
		q.material = _mat
		var m := MeshInstance3D.new()
		m.mesh = q
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(rng.randf_range(-area.x, area.x), ray_size.y * 0.35, rng.randf_range(-area.y, area.y))
		add_child(m)
		_rays.append(m)
	set_light(0.0, Color.WHITE)

## Força 0..1 e cor da luz (a cor do sol na hora).
func set_light(s: float, c: Color) -> void:
	visible = s > 0.01
	_mat.set_shader_parameter(&"strength", s * max_strength)
	_mat.set_shader_parameter(&"color", c)

func _process(_delta: float) -> void:
	if not visible:
		return
	# cada raio fica alinhado com a direção da luz e virado pra câmera em volta dela
	var dir := Vector3(0.4, -1.0, 0.25).normalized()
	if sun != null:
		dir = -sun.global_transform.basis.z
	var cam := get_viewport().get_camera_3d()
	for r in _rays:
		var up := -dir
		var to_cam := (cam.global_position - r.global_position).normalized() if cam != null else Vector3.BACK
		var right := up.cross(to_cam).normalized()
		var fwd := right.cross(up).normalized()
		r.global_basis = Basis(right, up, fwd)
