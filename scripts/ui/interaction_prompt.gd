class_name InteractionPrompt
extends Node3D
## Interaction prompt (context-sensitive action prompt).
## - Longe: invisível.
## - Perto: ícone genérico (quadrado no teclado, círculo no controle).
## - Bem perto: ícone da ação em outline (tecla E / botão A do Xbox).
## Os ícones seguem o dispositivo em uso (autoload `InputDevice`).
## No estado de ação, segurar `interact` vai preenchendo o ícone de baixo pra
## cima (outline -> preenchido); ao completar, emite `interacted`.

signal interacted
signal player_near  ## jogador entrou no show_radius (bom momento pra pré-carregar algo)

@export var show_radius: float = 5.0    ## distância em que o ícone genérico aparece
@export var action_radius: float = 2.0  ## distância em que vira o ícone da ação
@export var interact_action: StringName = &"interact"
@export var hold_time: float = 0.5     ## segundos segurando pra completar
@export var drain_time: float = 0.25   ## segundos pra esvaziar ao soltar antes

@export_group("Ícones — teclado")
@export var keyboard_generic: Texture2D
@export var keyboard_action_outline: Texture2D
@export var keyboard_action_filled: Texture2D  ## aparece ao segurar

@export_group("Ícones — controle")
@export var controller_generic: Texture2D
@export var controller_action_outline: Texture2D
@export var controller_action_filled: Texture2D  ## aparece ao segurar

@export_group("Visual")
@export var generic_size: float = 0.25  ## tamanho do ícone genérico (metros)
@export var action_size: float = 0.42   ## tamanho do ícone da ação (metros)
@export var bob_height: float = 0.06    ## flutuação pra cima/baixo
@export var bob_speed: float = 2.5
@export var glow_intensity: float = 2.5 ## >1 passa do branco puro: fica branco de verdade depois do tonemap e o glow faz brilhar

enum State { HIDDEN, GENERIC, ACTION }

var _state := State.HIDDEN
var _player: Node3D
var _tween: Tween
var _time := 0.0
var _fill := 0.0
var _completed := false  ## completou e o botão ainda não foi solto

@onready var _icon: MeshInstance3D = $Icon
var _mat: ShaderMaterial

func _ready() -> void:
	_mat = (_icon.mesh as QuadMesh).material as ShaderMaterial
	_mat.set_shader_parameter("glow", glow_intensity)
	_mat.set_shader_parameter("alpha", 0.0)
	_icon.scale = Vector3.ONE * 0.01
	_apply_texture()
	InputDevice.device_changed.connect(_on_device_changed)

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	var new_state := State.HIDDEN
	if dist <= action_radius:
		new_state = State.ACTION
	elif dist <= show_radius:
		new_state = State.GENERIC
	if new_state != _state:
		if _state == State.HIDDEN:
			player_near.emit()
		_set_state(new_state)

	_time += delta
	_icon.position.y = sin(_time * bob_speed) * bob_height

	_update_hold(delta)

func _update_hold(delta: float) -> void:
	var holding := _state == State.ACTION and Input.is_action_pressed(interact_action)
	if _completed:
		# já confirmou: fica cheio até soltar, depois esvazia
		if not holding:
			_completed = false
	elif holding:
		_fill = minf(_fill + delta / hold_time, 1.0)
		if _fill >= 1.0:
			_completed = true
			_complete()
	if not holding and not _completed:
		_fill = move_toward(_fill, 0.0, delta / drain_time)
	_mat.set_shader_parameter("fill", _fill)

func _complete() -> void:
	_pulse(action_size)
	interacted.emit()

func _texture_for(state: State) -> Texture2D:
	var pad := InputDevice.is_controller()
	if state == State.ACTION:
		return controller_action_outline if pad else keyboard_action_outline
	return controller_generic if pad else keyboard_generic

func _size_for(state: State) -> float:
	return action_size if state == State.ACTION else generic_size

func _apply_texture() -> void:
	var shown := State.ACTION if _state == State.ACTION else State.GENERIC
	_mat.set_shader_parameter("tex", _texture_for(shown))
	var pad := InputDevice.is_controller()
	_mat.set_shader_parameter("tex_fill", controller_action_filled if pad else keyboard_action_filled)

func _on_device_changed(_device: int) -> void:
	_apply_texture()
	if _state != State.HIDDEN:
		_pulse(_size_for(_state))

func _set_state(state: State) -> void:
	_state = state
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)

	if state != State.ACTION:
		_fill = 0.0
		_completed = false
	if state == State.HIDDEN:
		_tween.tween_property(_icon, "scale", Vector3.ONE * 0.01, 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.tween_property(_mat, "shader_parameter/alpha", 0.0, 0.2)
		return

	# troca o ícone e cresce/encolhe a partir do tamanho atual: lê como
	# "o ícone genérico se transformou na tecla/botão"
	_apply_texture()
	_tween.tween_property(_icon, "scale", Vector3.ONE * _size_for(state), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_mat, "shader_parameter/alpha", 1.0, 0.2)

func _pulse(size: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_icon, "scale", Vector3.ONE * size * 0.8, 0.06)
	_tween.tween_property(_icon, "scale", Vector3.ONE * size, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
