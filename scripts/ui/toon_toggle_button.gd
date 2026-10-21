extends CanvasLayer
## TESTE: botão no canto superior esquerdo que liga/desliga o ToonApplier,
## pra comparar ao vivo. Tirar quando o teste do toon acabar.

@export var toon_path: NodePath

var _toon: Node
var _btn: Button

func _ready() -> void:
	_toon = get_node_or_null(toon_path)
	_btn = Button.new()
	_btn.position = Vector2(12, 12)
	_btn.focus_mode = Control.FOCUS_NONE  # não rouba o teclado do jogador
	_btn.pressed.connect(_on_pressed)
	add_child(_btn)
	_refresh()

func _on_pressed() -> void:
	if _toon != null:
		_toon.set_style((_toon.style + 1) % 3)  # vinil → toon → natural
	_refresh()

func _refresh() -> void:
	_btn.text = "Estilo: " + (_toon.style_name() if _toon != null else "Vinil")
