extends CanvasLayer
## Contador de FPS (autoload, aparece em todas as cenas), no canto inferior
## esquerdo. F3 mostra/esconde.

var _label: Label
var _timer := 0.0

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = 8
	_label.offset_top = -30
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.25
		_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible
