extends Node3D
## Rig da câmera: fica na posição do jogador (sem rotação) e o Camera3D filho
## é recuado ao longo do próprio eixo de visão. Assim o jogador fica sempre no
## centro da tela, qualquer que seja a inclinação que você der ao Camera3D.
## Perto do foco (a casa), o zoom ortogonal abre de size_near_player até size_near_focus.

@export var target_path: NodePath
@export var camera_path: NodePath = NodePath("Camera3D")
@export var follow_speed: float = 8.0
@export var pivot_height: float = 0.5        ## altura (no jogador) que fica no centro da tela
@export var camera_distance: float = 20.0    ## recuo do Camera3D ao longo do eixo de visão (só evita cortar objetos)
@export_range(10.0, 90.0) var pitch_degrees: float = 55.0  ## inclinação pra baixo (90 = totalmente de cima)

@export_group("Zoom perto da casa")
@export var focus_path: NodePath
@export var focus_radius: float = 10.0       ## distância em que o zoom começa a abrir
@export var size_near_player: float = 6.0
@export var size_near_focus: float = 10.0
@export var zoom_speed: float = 3.0

var target: Node3D
var camera: Camera3D
var focus: Node3D

func _ready() -> void:
	if target_path != NodePath():
		target = get_node(target_path)
	if camera_path != NodePath():
		camera = get_node(camera_path)
	if focus_path != NodePath():
		focus = get_node(focus_path)

	if camera != null:
		# inclinação definida aqui (não pela rotação do Camera3D no editor),
		# pra não correr o risco de ficar olhando pro céu
		camera.rotation = Vector3(deg_to_rad(-pitch_degrees), 0.0, 0.0)
		camera.position = camera.transform.basis.z * camera_distance
		camera.size = size_near_player
	if target != null:
		global_position = target.global_position + Vector3.UP * pivot_height

func _process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + Vector3.UP * pivot_height
	global_position = global_position.lerp(desired, follow_speed * delta)

	if camera != null and focus != null:
		var to_focus := focus.global_position - target.global_position
		to_focus.y = 0.0
		var t := 1.0 - clampf(to_focus.length() / focus_radius, 0.0, 1.0)
		var desired_size := lerpf(size_near_player, size_near_focus, t)
		camera.size = lerpf(camera.size, desired_size, zoom_speed * delta)
