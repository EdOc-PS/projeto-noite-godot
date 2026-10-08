extends Node3D
## Gira devagar no eixo Y. Usado nos vagalumes dos postes (partículas com
## `local_coords`): girar o emissor faz eles rodearem o poste.

@export var speed_degrees: float = 25.0  ## graus por segundo (negativo = sentido contrário)

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(speed_degrees) * delta)
