extends Node3D
## Respingos da chuva no chão (valores do NIMBLUX Lite): **ondas** (anéis que
## se abrem no chão) e **coroas** (gotinhas quicando pra cima). Num raio em
## volta do jogador. Grupo `rain_fx`: o WeatherCycle chama `set_intensity()`.
## Regras em .docs/plans/06-clima.md.

@export var radius: float = 9.0                   ## raio em volta do jogador
@export var ground_height: float = 0.02           ## altura do chão (um pouco acima, pra não brigar com ele)
@export var max_ripples: int = 700
@export var ripple_size: float = 0.45             ## diâmetro final do anel (m)
@export var max_crowns: int = 500
@export var crown_size: float = 0.22              ## altura que as gotinhas sobem (m), aproximado
@export var color: Color = Color(0.78, 0.83, 0.9, 0.4)

var intensity := 0.0
var _ripples: GPUParticles3D
var _crowns: GPUParticles3D
var _player: Node3D

func _ready() -> void:
	add_to_group("rain_fx")
	_ripples = _make_ripples()
	_crowns = _make_crowns()
	add_child(_ripples)
	add_child(_crowns)
	set_intensity(intensity)

func set_intensity(v: float) -> void:
	intensity = clampf(v, 0.0, 1.0)
	for p in [_ripples, _crowns]:
		if p != null:
			p.amount_ratio = intensity
			p.emitting = intensity > 0.01

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, ground_height, _player.global_position.z)

func _box() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(radius, 0.0, radius)
	pm.gravity = Vector3.ZERO
	return pm

## Anel deitado no chão que cresce e some.
func _make_ripples() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = max_ripples
	p.lifetime = 0.6
	p.randomness = 0.5
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-radius, -1, -radius), Vector3(radius * 2, 2, radius * 2))
	var pm := _box()
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.15))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	pm.color_ramp = _fade_ramp(0.0)
	p.process_material = pm

	# anel: degradê radial transparente → anel → transparente
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.7, 0.85, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ring := GradientTexture2D.new()
	ring.gradient = g
	ring.fill = GradientTexture2D.FILL_RADIAL
	ring.fill_from = Vector2(0.5, 0.5)
	ring.fill_to = Vector2(0.5, 0.0)
	var mat := _material(ring)
	var mesh := PlaneMesh.new()  # deitado (horizontal)
	mesh.size = Vector2(ripple_size, ripple_size)
	mesh.material = mat
	p.draw_pass_1 = mesh
	return p

## Gotinhas pulando pra cima e caindo de volta, bem rápido.
func _make_crowns() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = max_crowns
	p.lifetime = 0.28
	p.randomness = 0.4
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-radius, -1, -radius), Vector3(radius * 2, 2, radius * 2))
	var pm := _box()
	pm.direction = Vector3.UP
	pm.spread = 35.0
	var v := sqrt(2.0 * 15.0 * crown_size)  # sobe ~crown_size com gravidade 15
	pm.initial_velocity_min = v * 0.7
	pm.initial_velocity_max = v * 1.1
	pm.gravity = Vector3(0, -15, 0)
	pm.color_ramp = _fade_ramp(0.5)
	p.process_material = pm

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var dot := GradientTexture2D.new()
	dot.gradient = g
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	var mat := _material(dot)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.035, 0.035)
	mesh.material = mat
	p.draw_pass_1 = mesh
	return p

func _material(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.albedo_texture = tex
	return mat

## Some no fim da vida (`hold` = fração da vida inteira antes de começar a sumir).
func _fade_ramp(hold: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, hold, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t
