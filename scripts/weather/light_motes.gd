extends GPUParticles3D
## Poeira no ar (manhã): grãozinhos claros flutuando devagar onde bate sol,
## com transparências diferentes (uns bem visíveis, outros quase somem). O emissor segue o jogador. Grupo
## `morning_fx`: o WeatherCycle controla `amount_ratio` (cheio de manhã, some
## até a tarde, nada à noite/chuva). Regras em .docs/plans/05-clima.md.

## Grupo que controla a quantidade: `morning_fx` (poeira da manhã) ou
## `night_fx` (poeira da noite, junto dos vagalumes).
@export var fx_group: StringName = &"morning_fx"
@export var mote_count: int = 130
@export var area: Vector3 = Vector3(8.0, 1.4, 6.0)  ## meia-caixa em volta do jogador
@export var height: float = 1.5
@export var mote_size: float = 0.045
@export var color: Color = Color(1.0, 0.95, 0.82, 1.0)  ## bege claro de poeira, opaca
@export var glow: float = 0.8                  ## sem brilho forte (era 2,5: parecia vagalume)
@export var alpha_range: Vector2 = Vector2(0.5, 1.0)   ## transparência sorteada por grão

var _player: Node3D

func _ready() -> void:
	add_to_group(fx_group)
	amount = mote_count
	lifetime = 6.0
	randomness = 0.7
	local_coords = false
	visibility_aabb = AABB(Vector3(-20, -3, -20), Vector3(40, 8, 40))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	var dot := GradientTexture2D.new()
	dot.gradient = g
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(mote_size, mote_size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# mistura normal (não aditiva): poeira não acende, só aparece
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(color.r * glow, color.g * glow, color.b * glow, color.a)
	mat.albedo_texture = dot
	quad.material = mat
	draw_pass_1 = quad

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.gravity = Vector3(0.05, 0.02, 0.02)
	pm.turbulence_enabled = true          # flutua sem direção
	pm.turbulence_noise_strength = 0.4
	pm.turbulence_noise_scale = 2.0
	pm.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT  # não entra no chão
	pm.scale_min = 0.3   # tamanhos bem variados: uns grãos maiores, outros mínimos
	pm.scale_max = 2.6
	# cada grão com uma transparência diferente
	var ag := Gradient.new()
	ag.offsets = PackedFloat32Array([0.0, 1.0])
	ag.colors = PackedColorArray([Color(1, 1, 1, alpha_range.x), Color(1, 1, 1, alpha_range.y)])
	var aramp := GradientTexture1D.new()
	aramp.gradient = ag
	pm.color_initial_ramp = aramp
	# acende e apaga devagar (cintila)
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	process_material = pm

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, height, _player.global_position.z)
