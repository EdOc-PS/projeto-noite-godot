extends GPUParticles3D
## Nuvens de poeira no chão: de vez em quando (`interval`), perto do jogador,
## aparece um bolinho de nuvenzinhas rente ao chão que cresce, é levado pelo
## vento e se desfaz (mesmo esfarelar da poeira dos passos,
## `shaders/dust_dissolve.gdshader`). Nasce em volta da área da câmera, nunca
## em cima do jogador.

const DISSOLVE_SHADER := preload("res://shaders/dust_dissolve.gdshader")

@export var wind_dir: Vector2 = Vector2(1.0, 0.3)   ## mesmo vento do wind_sway / WindStreaks
@export var interval: Vector2 = Vector2(3.0, 6.0)   ## espera entre nuvens (mín, máx), em s
@export var distance: Vector2 = Vector2(2.5, 7.0)   ## distância do jogador onde nasce (mín, máx)
@export var puffs: int = 9                          ## nuvenzinhas por nuvem
@export var cloud_size: float = 0.9                 ## raio do bolinho
@export var drift_speed: float = 0.7
@export var dust_color: Color = Color(0.78, 0.8, 0.9, 0.22)
@export var puff_scene: PackedScene = preload("res://assets/models/custom/smoke/smoke_puff.gltf")

var _player: Node3D
var _wait := 1.0

func _ready() -> void:
	amount = puffs
	lifetime = 3.5
	one_shot = true
	explosiveness = 0.85
	randomness = 0.5
	local_coords = false
	emitting = false
	visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 4, 12))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var inst := puff_scene.instantiate()
	var found := inst.find_children("*", "MeshInstance3D", true, false)
	if not found.is_empty():
		draw_pass_1 = (found[0] as MeshInstance3D).mesh
	inst.free()
	var mat := ShaderMaterial.new()
	mat.shader = DISSOLVE_SHADER
	mat.set_shader_parameter(&"color", dust_color)
	mat.set_shader_parameter(&"dissolve_start", 0.55)
	material_override = mat

	# cresce rápido, segura e encolhe um pouco no fim (o esfarelar some com ela)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.7))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve

	var dir := wind_dir.normalized()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(cloud_size, 0.05, cloud_size * 0.6)
	pm.direction = Vector3(dir.x, 0.15, dir.y)
	pm.spread = 25.0
	pm.initial_velocity_min = drift_speed * 0.6
	pm.initial_velocity_max = drift_speed
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.1
	pm.damping_max = 0.2
	pm.scale_min = 0.9
	pm.scale_max = 1.6
	pm.scale_curve = curve_tex
	pm.particle_flag_rotate_y = true
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	process_material = pm

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = randf_range(interval.x, interval.y) + lifetime
	var ang := randf() * TAU
	var r := randf_range(distance.x, distance.y)
	global_position = _player.global_position + Vector3(cos(ang) * r, 0.15, sin(ang) * r)
	restart()
