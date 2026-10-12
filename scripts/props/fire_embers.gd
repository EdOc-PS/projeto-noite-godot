extends GPUParticles3D
## Fagulhas do fogo: pontinhos brilhantes que sobem dançando (turbulência),
## esfriam de amarelo pra vermelho e somem. Usado junto das chamas
## (`scenes/effects/fire.tscn`) na lareira e nas tochas.

@export var ember_amount: int = 12
@export var ember_lifetime: float = 1.6
@export var area: Vector3 = Vector3(0.3, 0.05, 0.12)   ## meia-caixa de onde nascem
@export var rise_speed: Vector2 = Vector2(0.5, 1.1)
@export var ember_size: float = 0.03
@export var glow: float = 6.0

func _ready() -> void:
	amount = ember_amount
	lifetime = ember_lifetime
	randomness = 0.6
	visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 3, 2))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mesh := SphereMesh.new()
	mesh.radius = ember_size
	mesh.height = ember_size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	draw_pass_1 = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.15)
	mat.emission_energy_multiplier = glow
	material_override = mat

	# amarelo quente -> vermelho -> some
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.15, 0.05, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 20.0
	pm.initial_velocity_min = rise_speed.x
	pm.initial_velocity_max = rise_speed.y
	pm.gravity = Vector3(0, 0.2, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.2
	pm.turbulence_noise_scale = 1.5
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.scale_curve = curve_tex
	pm.color_ramp = grad_tex
	process_material = pm
