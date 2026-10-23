extends CanvasLayer
## Autoload `SceneTransition`: toda troca de cenário do jogo passa por aqui.
## Efeito provisório: fade pra preto, troca a cena e volta (o efeito definitivo
## é do estilo novo, a definir).
## Também descobre a tela quando o jogo inicia. Regra em .docs/plans/08-transicoes.md.

signal finished  ## tela terminou de descobrir

@export var close_time: float = 0.6
@export var open_time: float = 0.6
@export var hold_black: float = 0.15   ## pausa com a tela coberta entre fechar e abrir
@export var color: Color = Color.BLACK  ## cor da tela coberta

var busy := false
## Ponto de chegada pedido pra próxima cena (nome de um Marker3D do grupo
## `spawn_point`). O jogador lê isso no `_ready` e se posiciona lá.
var spawn_id: StringName = &""
var _rect: ColorRect
var _cache := {}  ## path -> PackedScene já carregada (voltar pra ela é instantâneo)

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = color
	add_child(_rect)
	_set_factor(1.0)  # começa coberto
	_open_on_start.call_deferred()

func _open_on_start() -> void:
	await get_tree().process_frame  # deixa a cena inicial posicionar câmera/jogador
	# a cena inicial não entra no cache aqui: carregá-la de novo durante o
	# primeiro frame derrubava o jogo (Terrain3D); voltar pra ela carrega na hora
	await _open()

## Cobre a tela, troca para `path` e abre na cena nova.
## `spawn`: nome do ponto de chegada na cena nova (vazio = posição padrão).
func change_scene(path: String, spawn: StringName = &"") -> void:
	if busy:
		return
	busy = true
	spawn_id = spawn
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	preload_scene(path)  # se ainda não começou, começa agora (carrega enquanto a tela cobre)
	await _close()
	await get_tree().create_timer(hold_black, true, false, true).timeout
	var packed := await _wait_loaded(path)  # se demorar mais que o fade, segura na tela preta
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
	var tw := _tween()
	tw.tween_method(_set_factor, 0.0, 1.0, close_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func _open() -> void:
	busy = true
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

## 0 = tela livre, 1 = tela coberta.
func _set_factor(f: float) -> void:
	_rect.modulate.a = f
