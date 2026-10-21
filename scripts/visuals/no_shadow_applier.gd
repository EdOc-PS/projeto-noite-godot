extends Node
## Tira a sombra projetada das malhas abaixo de `root_path` (vegetação pequena).

@export var root_path: NodePath = NodePath("..")
## Só tira a sombra de malhas mais baixas que isso (m). Regra de vegetação:
## vegetação pequena não tem sombra; arbusto grande e árvore têm. 0 = todas.
@export var max_height: float = 0.0

func _ready() -> void:
	_apply(get_node(root_path))

func _apply(n: Node) -> void:
	if n is GeometryInstance3D:
		var small := true
		if max_height > 0.0 and n is VisualInstance3D:
			var a: AABB = (n as VisualInstance3D).global_transform * (n as VisualInstance3D).get_aabb()
			small = a.size.y < max_height
		if small:
			n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_apply(c)
