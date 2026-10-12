extends Node3D
## Aplica a silhueta (preto + contorno cinza + vento) em toda vegetação filha
## deste node. Usado no vazio em volta dos interiores: a natureza lá fora
## aparece como sombra viva. Força do vento por tipo, pelo nome do glTF.

const SILHOUETTE := preload("res://shaders/silhouette.gdshader")
const OUTLINE := preload("res://shaders/silhouette_outline.gdshader")

@export var outline_color: Color = Color(0.42, 0.44, 0.5, 0.25)  ## alpha = força do contorno (1 = sólido)
@export var outline_width: float = 0.035

var _materials := {}  ## tipo -> ShaderMaterial

func _ready() -> void:
	for child in get_children():
		var file := child.scene_file_path.get_file().to_lower()
		var mat := _material_for(_kind(file))
		_apply(child, mat)

func _kind(file: String) -> String:
	if file.begins_with("tree"):
		return "tree"
	if file.begins_with("bush"):
		return "bush"
	if file.begins_with("mailbox") or file.begins_with("package"):
		return "prop"  # objetos (não balançam)
	return "grass"

func _material_for(kind: String) -> ShaderMaterial:
	if _materials.has(kind):
		return _materials[kind]
	# (força, velocidade, início, altura) do balanço, como no WindApplier
	var p: Array = {"grass": [0.06, 1.5, 0.0, 0.4], "bush": [0.03, 0.9, 0.2, 1.0], "tree": [0.08, 0.8, 1.0, 3.0], "prop": [0.0, 1.0, 0.0, 1.0]}[kind]
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE
	outline.set_shader_parameter(&"outline_color", outline_color)
	outline.set_shader_parameter(&"outline_width", outline_width * (2.0 if kind == "tree" else 1.0))
	var mat := ShaderMaterial.new()
	mat.shader = SILHOUETTE
	mat.next_pass = outline
	for m in [mat, outline]:
		m.set_shader_parameter(&"sway_strength", p[0])
		m.set_shader_parameter(&"sway_speed", p[1])
		m.set_shader_parameter(&"sway_start", p[2])
		m.set_shader_parameter(&"sway_height", p[3])
	_materials[kind] = mat
	return mat

func _apply(node: Node, mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_apply(child, mat)
