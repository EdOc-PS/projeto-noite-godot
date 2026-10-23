extends Node
## Cenário molhado: enquanto chove, os materiais normais (chão, pedra,
## madeira, paredes, telhados) ficam mais escuros e brilhantes, e as faces
## verticais ganham água escorrendo (`rain_streaks.gdshader` como next_pass).
## Secam devagar quando para. Folhagem fica de fora (molhada fica com cara de
## plástico). Grupo `wet_receivers`: o WeatherCycle chama `set_wetness()`.
## Regras em .docs/plans/05-clima.md.

const STREAKS := preload("res://shaders/weather/rain_streaks.gdshader")

@export var root_path: NodePath  ## vazio = a cena inteira
@export_range(0.0, 1.0) var darken: float = 0.3      ## quanto escurece a cor na chuva cheia
@export_range(0.0, 1.0) var wet_roughness: float = 0.15  ## roughness molhado (menor = mais brilho)
@export var skip_names: PackedStringArray = ["leaf", "leaves", "tree", "bush", "grass", "flower", "plant", "foliage", "glass", "glow", "light"]

var _mats := {}   # StandardMaterial3D -> [cor original, roughness original]
var _streaks: ShaderMaterial

func _ready() -> void:
	add_to_group("wet_receivers")
	_streaks = ShaderMaterial.new()
	_streaks.shader = STREAKS
	# espera os outros appliers (plástico etc.) trocarem os materiais primeiro
	_setup.call_deferred()

func _setup() -> void:
	var root: Node = get_tree().current_scene if root_path.is_empty() else get_node(root_path)
	_scan(root)

func _exit_tree() -> void:
	# os materiais do kit são compartilhados: devolver secos pra próxima cena
	set_wetness(0.0)
	RenderingServer.global_shader_parameter_set(&"weather_wetness", 0.0)

func set_wetness(w: float) -> void:
	for mat: StandardMaterial3D in _mats:
		var base: Array = _mats[mat]
		var c: Color = base[0]
		mat.albedo_color = Color(c.r * (1.0 - darken * w), c.g * (1.0 - darken * w), c.b * (1.0 - darken * w), c.a)
		mat.roughness = lerpf(base[1], wet_roughness, w)
		mat.next_pass = _streaks if w > 0.01 else null

func _scan(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null and mi.material_override == null and not _skip(mi.name):
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat != null and not _mats.has(mat) and not mat.emission_enabled and not _skip(mat.resource_name) and not _skip(_scene_name(mi)):
				_mats[mat] = [mat.albedo_color, mat.roughness]
	for child in node.get_children():
		_scan(child)

func _skip(n: String) -> bool:
	var l := n.to_lower()
	for s in skip_names:
		if l.contains(s):
			return true
	return false

## Nome do glTF de onde o mesh veio (as árvores do kit têm meshes com nome genérico).
func _scene_name(node: Node) -> String:
	var n := node
	while n != null:
		if n.scene_file_path != "":
			return n.scene_file_path.get_file()
		n = n.get_parent()
	return ""
