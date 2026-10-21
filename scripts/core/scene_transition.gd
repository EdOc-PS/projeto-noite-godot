extends CanvasLayer
## Autoload `SceneTransition`: toda troca de cenário do jogo passa por aqui.
## Efeito "wipe de bolhas" (shaders/ui/transition_wipe.gdshader): bolhas
## pretas de tamanhos variados entram pelas laterais e fecham até o centro,
## troca a cena e abrem de novo (do centro pras laterais).
## Também descobre a tela quando o jogo inicia. Regra em .docs/plans/13-transicoes.md.

signal finished  ## íris terminou de abrir

@export var close_time: float = 0.6
@export var open_time: float = 0.6
@export var hold_black: float = 0.15   ## pausa com a tela coberta entre fechar e abrir
@export var color: Color = Color.BLACK  ## cor das bolhas
@export var tiling: float = 5.0        ## repetições da textura de bolhas na altura da tela (menor = bolhas maiores)
@export var width: float = 0.5         ## largura da faixa de bolhas

const WIPE_SHADER := preload("res://shaders/ui/transition_wipe.gdshader")

var busy := false
## Ponto de chegada pedido pra próxima cena (nome de um Marker3D do grupo
## `spawn_point`). O jogador lê isso no `_ready` e se posiciona lá.
var spawn_id: StringName = &""
var _rect: ColorRect
var _cache := {}  ## path -> PackedScene já carregada (voltar pra ela é instantâneo)
var _mat: ShaderMaterial

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mat = ShaderMaterial.new()
	_mat.shader = WIPE_SHADER
	_mat.set_shader_parameter(&"base_color", color)
	_mat.set_shader_parameter(&"width", width)
	_mat.set_shader_parameter(&"shape_tiling", tiling)
	_mat.set_shader_parameter(&"gradient_fixed", true)
	_mat.set_shader_parameter(&"gradient_texture", _radial_gradient())
	_mat.set_shader_parameter(&"shape_texture", _bubble_shape())
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	_set_factor(1.0)  # começa coberto
	_open_on_start.call_deferred()

func _open_on_start() -> void:
	await get_tree().process_frame  # deixa a cena inicial posicionar câmera/jogador
	var first := get_tree().current_scene
	if first != null and first.scene_file_path != "":
		_cache[first.scene_file_path] = load(first.scene_file_path)  # já está na memória: só guarda
	await _open()

## Fecha a íris no jogador, troca para `path` e abre na cena nova.
## `spawn`: nome do ponto de chegada na cena nova (vazio = posição padrão).
func change_scene(path: String, spawn: StringName = &"") -> void:
	if busy:
		return
	busy = true
	spawn_id = spawn
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	preload_scene(path)  # se ainda não começou, começa agora (carrega enquanto a íris fecha)
	await _close()
	await get_tree().create_timer(hold_black, true, false, true).timeout
	var packed := await _wait_loaded(path)  # se demorar mais que a íris, segura na tela preta
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame  # cena nova pronta + câmera atualizada
	get_tree().paused = false
	await _open()

## Começa a carregar `path` em outra thread (não trava o jogo). Pode chamar à vontade.
func preload_scene(path: String) -> void:
	if _cache.has(path):
		return
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path, "PackedScene")

func _wait_loaded(path: String) -> PackedScene:
	if not _cache.has(path):
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		_cache[path] = ResourceLoader.load_threaded_get(path)
	return _cache[path]

func _close() -> void:
	_update_size()
	var tw := _tween()
	tw.tween_method(_set_factor, 0.0, 1.0, close_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func _open() -> void:
	busy = true
	_update_size()
	var tw := _tween()
	tw.tween_method(_set_factor, 1.0, 0.0, open_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	busy = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()

func _tween() -> Tween:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tw

## Marker3D do grupo `spawn_point` com nome `spawn_id` (null se não houver).
func get_spawn_point() -> Node3D:
	if spawn_id == &"":
		return null
	for n in get_tree().get_nodes_in_group(&"spawn_point"):
		if n.name == spawn_id:
			return n as Node3D
	return null

func _update_size() -> void:
	_mat.set_shader_parameter(&"node_resolution", get_viewport().get_visible_rect().size)

## 0 = tela livre, 1 = tela coberta.
func _set_factor(f: float) -> void:
	_mat.set_shader_parameter(&"factor", f)

## Degradê das laterais pro centro (laterais = 0, cobrem primeiro; centro = 1).
## Ordem do wipe: RADIAL. Borda da tela (preto) fecha primeiro e o centro
## (branco) por último: as bolhas vêm de fora pro meio num círculo.
func _radial_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, -0.21)  # raio ~0,71: os cantos da tela também ficam na borda
	t.width = 512
	t.height = 512
	return t

## Forma das bolhas: ruído celular (distância até o ponto mais próximo).
## Cortado pelo shader, cada célula vira um círculo que cresce; como as células
## têm tamanhos diferentes, as bolhas saem de tamanhos variados e se fundem.
func _bubble_shape() -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	n.cellular_jitter = 0.9
	n.frequency = 0.02
	n.seed = 7
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	t.normalize = true
	t.invert = true  # centro da célula claro: a bolha cresce do centro pra fora
	return t
