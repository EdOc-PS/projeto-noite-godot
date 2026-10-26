@tool
extends Node3D
## Arbusto: troca o material de todas as malhas do modelo filho por `material`
## (shader da grama: degradê, borda, vento e jogador). Roda também no editor.

@export var material: Material:
	set(v):
		material = v
		if is_inside_tree():
			_apply(self)

func _ready() -> void:
	_apply(self)

func _apply(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = material
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c in n.get_children():
		_apply(c)
