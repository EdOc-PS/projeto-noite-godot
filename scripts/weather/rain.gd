extends GPUParticles3D
## Chuva (tipo "leve/normal"): gotas finas e alongadas caindo um pouco
## inclinadas pelo vento, numa área em volta do jogador (o emissor segue o
## jogador, então não precisa cobrir o mapa todo). Configurado todo aqui.
## Liga/desliga suave por `set_intensity()` (o WeatherCycle chama).
## Regras em .docs/plans/06-clima.md.

@export var drop_count: int = 2700                 ## gotas ao mesmo tempo na intensidade 1 (NIMBLUX: 9000 no máximo, ~5000 na chuva média)
@export var area: Vector2 = Vector2(12.0, 12.0)    ## meia-área em volta do jogador (24 × 24 m, como o NIMBLUX)
@export var spawn_height: float = 14.0             ## altura de onde caem (NIMBLUX: caixa de 14 m)
@export var fall_speed: float = 13.0               ## m/s (NIMBLUX: 13, variação 20%)
@export var wind_dir: Vector2 = Vector2(1.0, 0.3)  ## mesmo vento do wind_sway
@export var wind_lean: float = 0.25                ## inclinação leve pelo vento (fração da queda; ~14°)
@export var drop_length: float = 0.7               ## m (NIMBLUX: 0,055 s × 13 m/s)
@export var drop_width: float = 0.014
@export var drop_color: Color = Color(0.74, 0.79, 0.86, 0.55)  ## cinza-azulado, 55% opaco (NIMBLUX)

## Transparência sorteada por gota (fração do alpha da cor): umas mais fortes, outras quase somem.
@export var alpha_range: Vector2 = Vector2(0.3, 1.0)

var intensity := 0.0  ## 0 = sem chuva, 1 = chuva leve cheia
var _player: Node3D

func _ready() -> void:
	amount = drop_count
	lifetime = spawn_height / (fall_speed * 0.8) + 0.1  # a gota mais lenta ainda chega no chão
	randomness = 0.3
	local_coords = false
	visibility_aabb = AABB(Vector3(-area.x, -spawn_height - 2.0, -area.y), Vector3(area.x * 2.0, spawn_height + 4.0, area.y * 2.0))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# gota: palito fino (caixa) alinhado com a direção da queda, então inclina
	# junto com o vento e aparece de qualquer ângulo da câmera
	var stick := BoxMesh.new()
	stick.size = Vector3(drop_width, drop_length, drop_width)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = drop_color
	mat.vertex_color_use_as_albedo = true  # recebe a transparência sorteada da partícula
	stick.material = mat
	draw_pass_1 = stick

	var lean := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * wind_lean
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x, 0.5, area.y)
	pm.direction = (Vector3.DOWN + lean).normalized()
	pm.spread = 2.0
	pm.initial_velocity_min = fall_speed * 0.8
	pm.initial_velocity_max = fall_speed * 1.2
	pm.gravity = Vector3.ZERO
	pm.particle_flag_align_y = true  # eixo Y da gota = direção da queda (inclinada)
	# cada gota nasce com uma transparência diferente
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, alpha_range.x), Color(1, 1, 1, alpha_range.y)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	pm.color_initial_ramp = ramp
	process_material = pm

	position.y = spawn_height
	set_intensity(intensity)

## 0..1: quantas gotas. Em 0 o emissor para (as que estão no ar terminam de cair).
func set_intensity(v: float) -> void:
	intensity = clampf(v, 0.0, 1.0)
	amount_ratio = intensity
	emitting = intensity > 0.01

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	# segue o jogador, um pouco contra o vento pra cobrir a tela com a inclinação
	var back := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized() * -wind_lean * spawn_height
	global_position = Vector3(_player.global_position.x + back.x, spawn_height, _player.global_position.z + back.z)
