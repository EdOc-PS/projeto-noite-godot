extends OmniLight3D
## Lanterna viva: a chama tremula (energia) e a cor "respira" devagar entre a
## cor original e um vermelho-brasa, como fogo dentro do vidro. Se o pai for o
## mesh do vidro aceso (LanternGlow), ele acompanha a mesma cor e brilho.
## Cada lanterna fica dessincronizada das outras.

@export var base_energy: float = 2.5
@export var flicker_amount: float = 0.35     ## tremulação rápida da energia
@export var flicker_speed: float = 3.0
@export var ember_color: Color = Color(1.0, 0.22, 0.06)  ## cor pra onde a chama puxa
@export_range(0.0, 1.0) var pulse_amount: float = 0.55  ## quanto chega no vermelho (1 = todo)
@export var pulse_speed: float = 0.35        ## velocidade do "respirar" da cor
@export var glow_energy: float = 5.0         ## emissão do vidro aceso

var _noise := FastNoiseLite.new()
var _t := 0.0
var _base_color: Color
var _glow_mat: StandardMaterial3D

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5
	_t = randf() * 100.0
	_base_color = light_color
	var glow := get_parent() as MeshInstance3D
	if glow != null and glow.mesh != null:
		var mat := glow.get_active_material(0) as StandardMaterial3D
		if mat != null:
			_glow_mat = mat.duplicate()  # cada lanterna com a própria cor
			glow.material_override = _glow_mat

func _process(delta: float) -> void:
	_t += delta
	var flick := _noise.get_noise_1d(_t * flicker_speed)
	var pulse := (_noise.get_noise_1d(_t * pulse_speed + 500.0) + 1.0) * 0.5  # 0..1, lento
	var color := _base_color.lerp(ember_color, pulse * pulse_amount)
	light_color = color
	light_energy = base_energy + flick * flicker_amount - pulse * 0.4
	if _glow_mat != null:
		_glow_mat.emission = color
		_glow_mat.emission_energy_multiplier = glow_energy * (1.0 + flick * 0.25)
