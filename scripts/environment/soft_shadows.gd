extends Node
## Sombras macias (estilo Link's Awakening): ao iniciar, dá "tamanho" a todas
## as luzes da cena, e a Godot passa a fazer sombra suave com borda esfumada
## (PCSS) em vez de borda dura. Sol/lua pelo ângulo aparente; lâmpadas, postes
## e fogo pelo tamanho da fonte. Regras em .docs/plans/11-estilo-visual.md.

@export var root_path: NodePath = NodePath("..")
@export var sun_angular_distance: float = 2.0  ## graus; maior = sombra mais borrada
@export var lamp_size: float = 0.15            ## metros, pra Omni/Spot com sombra

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
