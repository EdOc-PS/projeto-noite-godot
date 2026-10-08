extends CanvasLayer
## Autoload `SceneTransition`: toda troca de cenário do jogo passa por aqui.
## Efeito "iris wipe" (estilo Looney Tunes): um círculo preto fecha até o
## jogador, troca a cena e abre de novo a partir do jogador na cena nova.
## Também abre a íris quando o jogo inicia. Regra em .docs/TRANSICOES.md.

signal finished  ## íris terminou de abrir

@export var close_time: float = 0.7
@export var open_time: float = 0.8
@export var hold_black: float = 0.15   ## pausa na tela preta entre fechar e abrir
@export var focus_radius: float = 40.0 ## raio (px) em que a íris "segura" em volta do jogador antes do último fechamento

const IRIS_SHADER := preload("res://shaders/iris_wipe.gdshader")

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
	_mat.shader = IRIS_SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	_set_radius(0.0)  # começa preto
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
	_update_center()
	var full := _max_radius()
	var tw := _tween()
	tw.tween_method(_set_radius, full, focus_radius, close_time * 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_interval(close_time * 0.1)
	tw.tween_method(_set_radius, focus_radius, 0.0, close_time * 0.1) \
		.set_ease(Tween.EASE_IN)
	await tw.finished

func _open() -> void:
	busy = true
	_update_center()
	var tw := _tween()
	tw.tween_method(_set_radius, 0.0, _max_radius(), open_time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
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

## Centro da íris: jogador (grupo "player") projetado na tela; sem jogador, centro da tela.
func _update_center() -> void:
	var size := get_viewport().get_visible_rect().size
	var center := size * 0.5
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var cam := get_viewport().get_camera_3d()
	if player != null and cam != null and not cam.is_position_behind(player.global_position):
		center = cam.unproject_position(player.global_position + Vector3.UP * 0.8)
	_mat.set_shader_parameter(&"rect_size", size)
	_mat.set_shader_parameter(&"center", center)

func _max_radius() -> float:
	var size := get_viewport().get_visible_rect().size
	var c: Vector2 = _mat.get_shader_parameter(&"center")
	var r := 0.0
	for corner in [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]:
		r = maxf(r, c.distance_to(corner))
	return r + 2.0

func _set_radius(r: float) -> void:
	_mat.set_shader_parameter(&"radius", r)
