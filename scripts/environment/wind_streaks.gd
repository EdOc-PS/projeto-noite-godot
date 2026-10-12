extends GPUParticles3D
## Riscos de vento (estilo Death's Door / Zelda): linhas brancas finas que
## passam rápido na direção do vento, com uma leve ondulação, e somem.
## Cada risco é o rastro (trail) de uma partícula, com malha em cruz pra ser
## visível de qualquer ângulo. O emissor acompanha o jogador, então sempre há
## riscos na área da câmera, sem precisar cobrir o mapa inteiro.
## Configurado todo aqui; ajuste pelos exports.

@export var wind_dir: Vector2 = Vector2(1.0, 0.3)  ## mesmo vento do wind_sway
@export var streak_count: int = 4                  ## riscos ao mesmo tempo (poucos = sutil)
@export var speed: float = 6.0
@export var area: Vector2 = Vector2(14.0, 10.0)    ## área em volta do jogador onde nascem
@export var height_range: Vector2 = Vector2(0.4, 2.2)
@export var streak_color: Color = Color(0.85, 0.9, 1.0, 0.35)
@export var width: float = 0.035

var _player: Node3D

func _ready() -> void:
	amount = streak_count
	lifetime = 2.2
	randomness = 1.0
	local_coords = false
	trail_enabled = true
	trail_lifetime = 1.0
	visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 8, 40))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# malha do rastro: fita em cruz, afinando nas pontas
	var ribbon := RibbonTrailMesh.new()
	ribbon.shape = RibbonTrailMesh.SHAPE_CROSS
	ribbon.size = width
	ribbon.sections = 8
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.0))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.0))
	ribbon.curve = taper
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.use_particle_trails = true
	mat.albedo_color = streak_color
	ribbon.material = mat
	draw_pass_1 = ribbon

	# fade in e fade out. O rastro guarda a cor dos últimos `trail_lifetime` s,
	# então a ponta precisa estar transparente bem antes da partícula morrer:
	# senão a cauda ainda visível some de uma vez quando ela morre.
	var tail := trail_lifetime / lifetime  # fração da vida que o rastro cobre
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.95 - tail - 0.15, 0.95 - tail, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = g

	var dir := wind_dir.normalized()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x * 0.5, (height_range.y - height_range.x) * 0.5, area.y * 0.5)
	pm.direction = Vector3(dir.x, 0.0, dir.y)
	pm.spread = 6.0
	pm.flatness = 1.0
	pm.initial_velocity_min = speed * 0.8
	pm.initial_velocity_max = speed * 1.2
	pm.gravity = Vector3.ZERO
	pm.color_ramp = ramp
	# ondulação: o rastro desenha uma curva suave, não uma reta
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.2
	pm.turbulence_noise_scale = 4.0
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.12
	process_material = pm

	position.y = (height_range.x + height_range.y) * 0.5

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	# emissor segue o jogador, um pouco "contra o vento" pra os riscos cruzarem a tela
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -3.0
	global_position = Vector3(_player.global_position.x + back.x, global_position.y, _player.global_position.z + back.z)
