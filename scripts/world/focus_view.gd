extends Node
## Visão de interação frontal: ao completar o `InteractionPrompt` apontado
## (segurar `interact`), a câmera do jogo sai de cima do jogador e vai suave
## até o enquadramento (`shot_path`): de frente pro objeto (balcão, fogão...),
## aproximando o zoom. O personagem some e para de andar.
## Sai ao apertar `interact` de novo, `ui_cancel` ou mexer o personagem.
##
## É sempre a mesma câmera (ortogonal) se movendo e girando: sem troca de
## câmera, então não pisca nem distorce na entrada/saída.
## Padrão do jogo pra pontos de "uso" (plano 05).

signal opened
signal closed

@export var prompt_path: NodePath
@export var shot_path: NodePath          ## Marker3D: posição e direção da câmera (de frente pro objeto)
@export var shot_size: float = 3.0       ## zoom (size da câmera ortogonal) no enquadramento
@export var blend_time: float = 0.7

var active := false
var _busy := false
var _camera: Camera3D
var _prompt: Node3D
var _rig: Node
var _player: Node3D
var _back_transform: Transform3D
var _back_size: float
var _armed := false  ## só sai depois que o botão foi solto uma vez

func _ready() -> void:
	_prompt = get_node_or_null(prompt_path) as InteractionPrompt
	if _prompt != null:
		_prompt.interacted.connect(_open)

func _open() -> void:
	if active or _busy:
		return
	var shot := get_node_or_null(shot_path) as Node3D
	_camera = get_viewport().get_camera_3d()
	if shot == null or _camera == null:
		return
	_busy = true
	_rig = _camera.get_parent()
	_rig.set_process(false)  # o rig da câmera para de seguir o jogador
	_player = get_tree().get_first_node_in_group(&"player") as Node3D
	if _player != null:
		_player.set_physics_process(false)
		_player.visible = false
	if _prompt != null:  # o ícone some durante a visão
		_prompt.visible = false
		_prompt.set_process(false)
	# feixes de luz das luminárias atrapalham a visão de perto: somem (a luz continua)
	for n in get_tree().get_nodes_in_group(&"light_shaft"):
		(n as Node3D).visible = false
	_back_transform = _camera.global_transform
	_back_size = _camera.size
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_camera, "global_transform", shot.global_transform, blend_time)
	tw.tween_property(_camera, "size", shot_size, blend_time)
	await tw.finished
	active = true
	_armed = false
	_busy = false
	opened.emit()

func _close() -> void:
	if not active or _busy:
		return
	_busy = true
	active = false
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_camera, "global_transform", _back_transform, blend_time)
	tw.tween_property(_camera, "size", _back_size, blend_time)
	await tw.finished
	_rig.set_process(true)
	for n in get_tree().get_nodes_in_group(&"light_shaft"):
		(n as Node3D).visible = true
	if _player != null:
		_player.visible = true
		_player.set_physics_process(true)
	# só volta a aceitar o prompt depois de soltar o botão (senão reabre na hora)
	while Input.is_action_pressed(&"interact"):
		await get_tree().process_frame
	if _prompt != null:
		_prompt.visible = true
		_prompt.set_process(true)
	_busy = false
	closed.emit()

func _process(_delta: float) -> void:
	if not active:
		return
	if not Input.is_action_pressed(&"interact"):
		_armed = true
	var moving := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").length() > 0.5
	if Input.is_action_just_pressed(&"ui_cancel") or moving or (_armed and Input.is_action_just_pressed(&"interact")):
		_close()
