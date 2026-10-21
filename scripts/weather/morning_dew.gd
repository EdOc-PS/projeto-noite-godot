extends GPUParticles3D
## Orvalho (só manhã cedo): pontinhos brilhantes na grama, rentes ao chão,
## cintilando (acendem e apagam rápido, como gota de água pegando o sol).
## Ficam na área deste node (a área com grama). Grupo `dew_fx`: o
## WeatherCycle controla `amount_ratio` (cheio no começo da manhã e some
## conforme o sol sobe; nada à tarde/noite/chuva). Regras em .docs/plans/06-clima.md.

@export var sparkle_count: int = 35
@export var area: Vector3 = Vector3(7.5, 0.18, 11.5)  ## meia-caixa (local)
@export var height: float = 0.22                       ## altura média (pontas da grama)
@export var size: float = 0.05
@export var glow: float = 3.0

func _ready() -> void:
	add_to_group("dew_fx")
	amount = sparkle_count
	lifetime = 1.6
	randomness = 0.8
	local_coords = false
	visibility_aabb = AABB(-area - Vector3(1, 1, 1), area * 2.0 + Vector3(2, 2, 2))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position.y = height

	# brilho em cruz (estrelinha) aditivo
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var cross := maxf(1.0 - absf(u) * 8.0, 0.0) * (1.0 - absf(v)) + maxf(1.0 - absf(v) * 8.0, 0.0) * (1.0 - absf(u))
			var core := maxf(1.0 - Vector2(u, v).length() * 2.5, 0.0)
			var a := clampf(cross + core, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(glow, glow, glow * 0.95, 1.0)
	mat.albedo_texture = tex
	quad.material = mat
	draw_pass_1 = quad

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	# acende rápido e apaga (cintilar)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	process_material = pm
