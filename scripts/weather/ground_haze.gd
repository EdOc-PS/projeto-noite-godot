extends GPUParticles3D
## Poeira levantada pelo vento: nuvenzinhas fofas de poeira (textura
## assets/textures/effects/dust_puff.png) que nascem rente ao chão, vão crescendo
## e andando na direção do vento (oeste → leste na tela) e somem devagar.
## Cor do vento, bem transparente. O emissor segue o jogador, um pouco contra o
## vento, pra elas atravessarem a tela. Quantidade e velocidade seguem o vento
## (grupo `wind_fx`, controlado pelo wind.gd).

const TEX := preload("res://assets/textures/effects/dust_puff.png")

@export var puff_count: int = 8
@export var area: Vector2 = Vector2(30.0, 30.0)      ## onde nascem, em volta do jogador
@export var size_range: Vector2 = Vector2(2.5, 5.0)  ## tamanho da nuvem (m)
@export var color: Color = Color(0.9, 0.95, 0.86, 0.3)  ## cor do vento, opacidade ~0,3
@export var speed: Vector2 = Vector2(1.2, 2.2)       ## m/s na direção do vento
@export var life: float = 8.0                        ## aparece, anda e some
@export var wind_dir: Vector2 = Vector2(1.0, -0.02)

var _player: Node3D

func _ready() -> void:
	add_to_group("wind_fx")  # mais poeira com mais vento
	amount = puff_count
	lifetime = life
	randomness = 1.0
	local_coords = false
	preprocess = life  # já começa com poeira na tela
	visibility_aabb = AABB(Vector3(-30, -2, -30), Vector3(60, 10, 60))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 0.6)
	quad.center_offset = Vector3(0.0, 0.3, 0.0)  # base da nuvem no chão
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y  # de frente pra câmera, em pé
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = TEX
	mat.albedo_color = color
	mat.proximity_fade_enabled = true  # sem corte duro onde encosta no chão/grama
	mat.proximity_fade_distance = 0.6
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 3.0
	mat.distance_fade_max_distance = 7.0
	quad.material = mat
	draw_pass_1 = quad

	var dir := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x * 0.5, 0.05, area.y * 0.5)
	pm.direction = dir
	pm.spread = 10.0
	pm.initial_velocity_min = speed.x
	pm.initial_velocity_max = speed.y
	pm.gravity = Vector3(0.0, 0.05, 0.0)  # sobe bem pouco enquanto anda
	pm.scale_min = size_range.x
	pm.scale_max = size_range.y
	# cresce enquanto anda (a poeira se espalha)
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.55))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	# aparece e some devagar
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	process_material = pm

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -8.0
	global_position = Vector3(_player.global_position.x + back.x, 0.0, _player.global_position.z + back.z)
