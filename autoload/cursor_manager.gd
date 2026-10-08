extends Node
## Autoload `CursorManager`: cursor do mouse do jogo. Com teclado/mouse usa o
## cursor customizado (`hand_point`); com controle esconde o ponteiro.

const CURSOR_DEFAULT := preload("res://assets/ui/cursors/hand_point.png")
const HOTSPOT_DEFAULT := Vector2(9, 4)  ## ponta do dedo no PNG de 32x32

func _ready() -> void:
	InputDevice.device_changed.connect(_on_device_changed)
	_apply(InputDevice.current)

func _on_device_changed(device: InputDevice.Device) -> void:
	_apply(device)

func _apply(device: InputDevice.Device) -> void:
	if device == InputDevice.Device.CONTROLLER:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		return
	Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW, HOTSPOT_DEFAULT)
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
