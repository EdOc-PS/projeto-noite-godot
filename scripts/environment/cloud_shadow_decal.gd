extends Decal
## Sombra das nuvens: um Decal gigante com manchas macias
## (`assets/textures/effects/cloud_shadows.png`) deslizando na direção do vento.
## A textura repete a cada `period` metros (3x3 períodos no Decal), então ao
## andar um período inteiro o Decal volta pro início sem emenda visível.

@export var period: float = 40.0                   ## metros de um período da textura
@export var wind_dir: Vector2 = Vector2(1.0, 0.3)  ## mesmo vento do wind_sway
@export var speed: float = 0.8                     ## metros por segundo

var _origin: Vector3
var _offset := Vector2.ZERO

func _ready() -> void:
	_origin = position
	size = Vector3(period * 3.0, size.y, period * 3.0)

func _process(delta: float) -> void:
	_offset += wind_dir.normalized() * speed * delta
	_offset.x = fposmod(_offset.x, period)
	_offset.y = fposmod(_offset.y, period)
	position = _origin + Vector3(_offset.x, 0.0, _offset.y)
