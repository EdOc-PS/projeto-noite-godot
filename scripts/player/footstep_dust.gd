extends GPUParticles3D
## Poeirinha nos pés enquanto o personagem anda: nuvenzinhas (mesmo mesh da
## fumaça da chaminé) que nascem no chão, sobem um pouco e somem encolhendo.
## Configurada toda aqui pra ficar autocontida; ajuste pelos exports.

@export var min_speed: float = 1.0       ## velocidade horizontal mínima pra soltar poeira
@export var puff_size: float = 0.22
@export var puff_color: Color = Color(0.78, 0.8, 0.9)  ## lavanda clara, combina com a noite
@export var puff_scene: PackedScene = preload("res://assets/models/custom/smoke/smoke_puff.gltf")

@onready var _body := get_parent() as CharacterBody3D

func _ready() -> void:
	amount = 10
	lifetime = 0.6
	local_coords = false  # a poeira fica no lugar, o personagem segue andando
	emitting = false
	visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 3, 6))

	var inst := puff_scene.instantiate()
	var found := inst.find_children("*", "MeshInstance3D", true, false)
	if not found.is_empty():
		draw_pass_1 = (found[0] as MeshInstance3D).mesh
	inst.free()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = puff_color
	mat.roughness = 1.0
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.12
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, -0.4, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.particle_flag_rotate_y = true
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = puff_size * 0.7
	pm.scale_max = puff_size
	pm.scale_curve = curve_tex
	process_material = pm

func _process(_delta: float) -> void:
	if _body == null:
		return
	var v := _body.velocity
	emitting = _body.is_on_floor() and Vector2(v.x, v.z).length() > min_speed
