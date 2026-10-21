extends CanvasLayer
## Painel de debug da área de teste (só nela): controla o clima (ciclo de dia
## e noite e chuva).
## Montado por código, canto superior esquerdo.

@export var cycle_path: NodePath
@export var toon_path: NodePath  ## opcional: ToonApplier (teste)
@export var camera_rig_path: NodePath  ## opcional: CameraRig, pra alternar câmera nova/antiga

var _cycle: Node
var _toon: Node
var _toon_btn: Button
var _cam_btn: Button
var _rig: Node3D
var _new_cam := true
## câmera nova (isométrica em perspectiva) e antiga (ortogonal, igual ao outside)
const CAM_NEW := {"pitch": 50.0, "yaw": 40.5, "dist": 18.0, "ortho": false, "fov": 28.0, "size": 6.0}
const CAM_OLD := {"pitch": 45.0, "yaw": -17.0, "dist": 40.0, "ortho": true, "fov": 75.0, "size": 6.0}
var _pause_btn: Button
var _rain_btn: Button
var _time_btns: Array[Button] = []  ## desligados enquanto chove
var _label: Label

func _ready() -> void:
	_cycle = get_node_or_null(cycle_path)
	_toon = get_node_or_null(toon_path)
	_rig = get_node_or_null(camera_rig_path) as Node3D
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_label = Label.new()
	box.add_child(_label)
	_pause_btn = _button(box, "Pausar", _on_pause)
	_time_btns.append(_button(box, "Reiniciar dia", func(): _cycle.restart()))
	_time_btns.append(_button(box, "Manhã", func(): _cycle.set_phase(0.0)))
	_time_btns.append(_button(box, "Tarde", func(): _cycle.set_phase(0.62)))
	_time_btns.append(_button(box, "Noite", func(): _cycle.set_phase(1.0)))
	_rain_btn = _button(box, "", func(): _cycle.set_raining(not _cycle.raining))
	if _rig != null:
		# canto superior direito, fora do painel
		var corner := MarginContainer.new()
		corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		corner.add_theme_constant_override(&"margin_top", 12)
		corner.add_theme_constant_override(&"margin_right", 12)
		add_child(corner)
		_cam_btn = _button(corner, "Câmera: nova", _on_camera)
	if _toon != null:
		_toon_btn = _button(box, "", _on_toon)
		_refresh_toon()

func _process(_delta: float) -> void:
	if _cycle != null:
		_label.text = "Hora: %d%%%s" % [roundi(_cycle.phase * 100.0), " (pausado)" if _cycle.paused else (" (chovendo: hora parada)" if _cycle.raining else "")]
		_pause_btn.text = "Retomar" if _cycle.paused else "Pausar"
		_rain_btn.text = "Chuva: ligada" if _cycle.raining else "Chuva: desligada"
		for b in _time_btns:
			b.disabled = _cycle.raining

func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE  # não rouba o teclado do jogador
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _on_pause() -> void:
	_cycle.paused = not _cycle.paused

func _on_toon() -> void:
	_toon.set_style((_toon.style + 1) % 3)  # vinil → toon → natural
	_refresh_toon()

func _refresh_toon() -> void:
	_toon_btn.text = "Estilo: " + _toon.style_name()

func _on_camera() -> void:
	_new_cam = not _new_cam
	var c: Dictionary = CAM_NEW if _new_cam else CAM_OLD
	_rig.pitch_degrees = c.pitch
	_rig.yaw_degrees = c.yaw
	_rig.camera_distance = c.dist
	_rig.size_near_player = c.size
	var cam: Camera3D = _rig.camera
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL if c.ortho else Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = c.fov
	cam.size = c.size
	# mesma conta do isometric_camera._ready
	cam.rotation = Vector3(deg_to_rad(-c.pitch), deg_to_rad(c.yaw), 0.0)
	cam.position = cam.transform.basis.z * c.dist
	_cam_btn.text = "Câmera: nova" if _new_cam else "Câmera: antiga"
