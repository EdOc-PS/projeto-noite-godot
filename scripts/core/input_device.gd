extends Node
## Autoload `InputDevice`: sabe qual dispositivo o jogador está usando agora
## (teclado/mouse ou controle) olhando o último input recebido, e avisa quando
## muda. A UI usa isso pra trocar os ícones de botão.

signal device_changed(device: Device)

enum Device { KEYBOARD, CONTROLLER }

const STICK_DEADZONE := 0.4  ## analógico parado/drift não conta como "usando o controle"

var current: Device = Device.KEYBOARD

func is_controller() -> bool:
	return current == Device.CONTROLLER

func _input(event: InputEvent) -> void:
	var device := current
	if event is InputEventKey or event is InputEventMouseButton:
		device = Device.KEYBOARD
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() > 2.0:
			device = Device.KEYBOARD
	elif event is InputEventJoypadButton:
		device = Device.CONTROLLER
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE:
			device = Device.CONTROLLER

	if device != current:
		current = device
		device_changed.emit(current)
