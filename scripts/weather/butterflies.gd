extends GPUParticles3D
## Borboletas (manhã e tarde), o par dos vagalumes da noite: poucas, voando em
## zigue-zague devagar perto do chão/grama, batendo as asas. Cada borboleta é
## uma partícula com um quad de duas asas que dobram no meio (shader
## `butterfly.gdshader`); a cor sorteia entre algumas. Ficam na área deste node.
## Grupo `day_fx`: o WeatherCycle controla `amount_ratio` (some à noite e na chuva).
## Regras em .docs/plans/05-clima.md.

const SHADER := preload("res://shaders/weather/butterfly.gdshader")

@export var butterfly_count: int = 8
@export var area: Vector3 = Vector3(7.0, 0.6, 11.0)   ## meia-caixa onde voam (local)
@export var height: float = 0.9                        ## altura média do voo
@export var size: float = 0.14
@export var colors: PackedColorArray = [Color(1.0, 0.95, 0.85), Color(1.0, 0.8, 0.25), Color(1.0, 0.55, 0.2), Color(0.55, 0.75, 1.0)]

func _ready() -> void:
	add_to_group("day_fx")
	amount = butterfly_count
	lifetime = 9.0
	randomness = 0.5
	local_coords = false
	visibility_aabb = AABB(-area - Vector3(2, 2, 2), area * 2.0 + Vector3(4, 4, 4))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	position.y = height

	var quad := PlaneMesh.new()   # deitada: asas abertas pra cima/baixo pelo shader
	quad.size = Vector2(size, size * 0.8)
	quad.subdivide_width = 2
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"wing_tex", _wing_texture())
	quad.material = mat
	draw_pass_1 = quad

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area
	pm.direction = Vector3(1, 0.2, 0.3)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true            # zigue-zague
	pm.turbulence_noise_strength = 2.5
	pm.turbulence_noise_scale = 1.2
	pm.turbulence_noise_speed = Vector3(0.3, 0.3, 0.3)
	pm.particle_flag_align_y = false
	pm.particle_flag_rotate_y = true
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.collision_mode = ParticleProcessMaterial.COLLISION_RIGID  # não entra no chão
	pm.collision_bounce = 0.6
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	g.colors = colors
	var cr := GradientTexture1D.new()
	cr.gradient = g
	pm.color_initial_ramp = cr
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.9, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var fr := GradientTexture1D.new()
	fr.gradient = fade
	pm.color_ramp = fr
	process_material = pm

## Duas asas (um par de lóbulos de cada lado), branco (a cor vem da partícula),
## com uma borda/pinta mais escura e o corpinho no meio.
func _wing_texture() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0   # -1..1 (asa esquerda/direita)
			var v := (y + 0.5) / n * 2.0 - 1.0
			var ax := absf(u)
			# asa de cima (maior) e de baixo (menor)
			var top := Vector2((ax - 0.5) / 0.48, (v + 0.3) / 0.42).length()
			var bot := Vector2((ax - 0.4) / 0.34, (v - 0.42) / 0.32).length()
			var body := ax < 0.06 and absf(v) < 0.7
			var inside := top < 1.0 or bot < 1.0
			var c := Color.WHITE
			if body:
				c = Color(0.18, 0.14, 0.12, 1.0)
			elif inside:
				var edge := minf(top, bot)
				c = Color(1, 1, 1, 1) if edge < 0.75 else Color(0.35, 0.3, 0.3, 1)  # borda escura
			img.set_pixel(x, y, Color(c, 1.0 if (inside or body) else 0.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
