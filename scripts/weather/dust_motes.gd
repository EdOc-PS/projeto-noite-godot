extends GPUParticles3D
## Poeira no ar: bolinhas redondas e pequenas flutuando devagar (como os
## vagalumes do projeto antigo, mas de dia e sem brilho), levadas pelo vento.
## O emissor segue o jogador. Fora do grupo `wind_fx` de propósito: lá a
## quantidade cai quase a zero no vento calmo, e a poeira tem que estar sempre. Regras em .docs/plans/05-clima.md.

@export var mote_count: int = 40
@export var area: Vector3 = Vector3(14.0, 1.2, 14.0)   ## meia-caixa em volta do jogador
@export var height: float = 1.4                         ## altura média
@export var size: float = 0.045                         ## diâmetro da bolinha (m)
@export var color: Color = Color(1.0, 0.97, 0.86, 0.75)
@export var wind_dir: Vector2 = Vector2(1.0, -0.02)
@export var drift_speed: Vector2 = Vector2(0.25, 0.6)   ## m/s na direção do vento

var _player: Node3D

func _ready() -> void:
	amount = mote_count
	lifetime = 10.0
	randomness = 1.0
	local_coords = false
	preprocess = 10.0
	visibility_aabb = AABB(-area - Vector3(4, 4, 4), area * 2.0 + Vector3(8, 8, 8))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# bolinha: disco macio, sempre de frente pra câmera
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var dot := GradientTexture2D.new()
	dot.gradient = g
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	dot.width = 32
	dot.height = 32
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = dot
	mat.albedo_color = color
	quad.material = mat
	draw_pass_1 = quad

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area
	pm.direction = Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	pm.spread = 25.0
	pm.initial_velocity_min = drift_speed.x
	pm.initial_velocity_max = drift_speed.y
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true          # flutua, sobe e desce de leve
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	pm.turbulence_noise_speed = Vector3(0.1, 0.1, 0.1)
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var fr := GradientTexture1D.new()
	fr.gradient = fade
	pm.color_ramp = fr
	process_material = pm

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, height, _player.global_position.z)
