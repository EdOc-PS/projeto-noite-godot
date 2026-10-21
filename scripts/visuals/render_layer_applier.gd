extends Node
## Põe todas as malhas abaixo de `root_path` também nas camadas `add_layers`.
## Usado no campo pra só o piso receber a mancha de terra (Decal com
## cull_mask nessa camada), sem pintar caule de árvore, flor ou personagem.

@export var root_path: NodePath = NodePath("..")
@export_flags_3d_render var add_layers: int = 4  ## camada 3

func _ready() -> void:
	_apply(get_node(root_path))

func _apply(n: Node) -> void:
	if n is VisualInstance3D:
		n.layers |= add_layers
	for c in n.get_children():
		_apply(c)
