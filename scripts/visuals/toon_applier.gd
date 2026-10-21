extends Node
## TESTE: estilo toon (tutorial "Godot Toon Shading", Binbun3D).
## - Troca os materiais normais dos glTF pelo `toon_tutorial.gdshader`
##   (mesma cor/textura), e volta pros de antes ao desligar (os do
##   PlasticApplier, se houver). Fica depois do PlasticApplier na árvore.
## - Liga o global `toon_enabled`, que deixa toon também os shaders próprios
##   (grama/árvores com vento), via `includes/toon_light.gdshaderinc`.
## Regras em .docs/plans/11-estilo-visual.md.

const TOON := preload("res://shaders/toon/toon_tutorial.gdshader")
const NATURAL := preload("res://shaders/toon/natural.gdshader")  ## luz dos tufos de grama, sem vinil

## TESTE: três estilos pra comparar. VINIL = materiais de sempre (PlasticApplier),
## TOON = toon_tutorial, NATURAL = mesma luz dos tufos de grama no cenário todo.
enum Style { VINIL, TOON, NATURAL }
var style: int = Style.VINIL

@export var root_path: NodePath  ## vazio = a cena inteira (inclui o jogador, que fica na cena pai)
@export var enabled: bool = false
@export var bands: float = 4.0                          ## degraus de luz
@export_range(0.0, 1.0) var secondary_amount: float = 0.35  ## degraus nas lâmpadas/lareira (0 = luz comum, 1 = degrau cheio, escuro demais)
@export_range(0.0, 0.5) var band_smoothness: float = 0.0  ## degradê entre os degraus (0 = seco; o charme é o degrau seco)
@export_range(0.0, 1.0) var rim_threshold: float = 0.7  ## menor = borda clara mais larga
@export_range(0.0, 2.0) var rim_strength: float = 1.0
@export_range(0.0, 2.0) var vinyl_strength: float = 0.35  ## brilho suave de vinil (0 = sem)
@export var vinyl_shininess: float = 20.0                 ## maior = brilho menor e concentrado

var _slots: Array = []     # [MeshInstance3D, surface, material de antes]
var _cache := {}           # material de antes -> ShaderMaterial toon

func _ready() -> void:
	# espera os outros appliers (plástico, silhueta) terminarem, pra não
	# sobrescrever a silhueta e guardar os materiais finais
	_setup.call_deferred()

func _setup() -> void:
	var root: Node = get_tree().current_scene if root_path.is_empty() else get_node(root_path)
	_scan(root)
	set_style(Style.TOON if enabled else Style.VINIL)

func set_enabled(on: bool) -> void:
	set_style(Style.TOON if on else Style.VINIL)

func set_style(s: int) -> void:
	style = s
	enabled = s == Style.TOON
	var on := enabled
	RenderingServer.global_shader_parameter_set(&"toon_enabled", 1.0 if on else 0.0)
	RenderingServer.global_shader_parameter_set(&"toon_bands", bands)
	RenderingServer.global_shader_parameter_set(&"toon_band_smoothness", band_smoothness)
	RenderingServer.global_shader_parameter_set(&"toon_secondary_amount", secondary_amount)
	RenderingServer.global_shader_parameter_set(&"toon_rim_threshold", rim_threshold)
	RenderingServer.global_shader_parameter_set(&"toon_rim_strength", rim_strength)
	RenderingServer.global_shader_parameter_set(&"toon_vinyl_strength", vinyl_strength)
	RenderingServer.global_shader_parameter_set(&"toon_vinyl_shininess", vinyl_shininess)
	for slot in _slots:
		var mi: MeshInstance3D = slot[0]
		if is_instance_valid(mi):
			var m: Material = slot[2]
			if s == Style.TOON:
				m = _toon(slot[2])
			elif s == Style.NATURAL:
				m = _natural(slot[2])
			mi.set_surface_override_material(slot[1], m)

func _exit_tree() -> void:
	# o global vale pro projeto todo: não deixar ligado na próxima cena
	RenderingServer.global_shader_parameter_set(&"toon_enabled", 0.0)

func _scan(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null and mi.material_override == null:
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat != null and not mat.emission_enabled:
				_slots.append([mi, i, mat])
	for child in node.get_children():
		_scan(child)

func _toon(mat: StandardMaterial3D) -> ShaderMaterial:
	if _cache.has(mat):
		return _cache[mat]
	var t := ShaderMaterial.new()
	t.shader = TOON
	var c := mat.albedo_color
	# Color (não Vector3): o uniform é source_color, e com Vector3 a Godot não
	# converte de sRGB pra linear: a cor ficava lavada (chão verde virava cinza)
	t.set_shader_parameter(&"albedo", Color(c.r, c.g, c.b))
	if mat.albedo_texture != null:
		t.set_shader_parameter(&"albedo_texture", mat.albedo_texture)
	_cache[mat] = t
	return t

var _natural_cache := {}

func _natural(mat: StandardMaterial3D) -> ShaderMaterial:
	if _natural_cache.has(mat):
		return _natural_cache[mat]
	var t := ShaderMaterial.new()
	t.shader = NATURAL
	var c := mat.albedo_color
	t.set_shader_parameter(&"albedo", Color(c.r, c.g, c.b))  # Color: ver _toon()
	if mat.albedo_texture != null:
		t.set_shader_parameter(&"albedo_texture", mat.albedo_texture)
	_natural_cache[mat] = t
	return t

func style_name() -> String:
	return ["Vinil", "Toon", "Natural"][style]
