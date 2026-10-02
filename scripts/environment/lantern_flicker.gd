extends OmniLight3D
## Tremulação leve de chama de gás/lampião a óleo.
## Anexado diretamente no OmniLight3D do poste.

@export var base_energy: float = 1.5
@export var flicker_amount: float = 0.15
@export var flicker_speed: float = 2.5

var _noise := FastNoiseLite.new()
var _time_offset := 0.0

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5
	# desfasa cada poste para não tremularem em sincronia
	_time_offset = randf() * 100.0

func _process(delta: float) -> void:
	_time_offset += delta * flicker_speed
	var n := _noise.get_noise_1d(_time_offset)
	light_energy = base_energy + n * flicker_amount
