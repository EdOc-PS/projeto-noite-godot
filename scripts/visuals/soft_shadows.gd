extends Node
## Sombras macias (estilo Link's Awakening): ao iniciar, dá "tamanho" a todas
## as luzes da cena, e a Godot passa a fazer sombra suave com borda esfumada
## (PCSS) em vez de borda dura. Sol/lua pelo ângulo aparente; lâmpadas, postes
## e fogo pelo tamanho da fonte. Regra: noite = sombra suave; dia = sombra
## nítida e arredondada (na cidade o weather_cycle.gd ajusta pela hora). Regras em .docs/plans/11-estilo-visual.md.

@export var root_path: NodePath = NodePath("..")
@export var sun_angular_distance: float = 1.5  ## graus; maior = sombra mais borrada (noite)
@export var lamp_size: float = 0.0             ## metros, pra Omni/Spot com sombra (0 = sombra dura: o ruído da sombra macia vira quadradinhos no toon)

func _ready() -> void:
	_scan(get_node(root_path))

func _scan(node: Node) -> void:
	if node is DirectionalLight3D:
		node.light_angular_distance = sun_angular_distance
	elif node is OmniLight3D or node is SpotLight3D:
		if node.shadow_enabled:
			node.light_size = lamp_size
	for child in node.get_children():
		_scan(child)
