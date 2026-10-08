extends Node
## Saída de cenário: quando o `InteractionPrompt` apontado completa (segurar
## `interact`), troca para `target_scene` com a transição padrão (SceneTransition).

@export var prompt_path: NodePath
@export_file("*.tscn") var target_scene: String
@export var spawn_id: StringName  ## Marker3D (grupo `spawn_point`) onde o jogador chega na cena nova

func _ready() -> void:
	var prompt := get_node_or_null(prompt_path) as InteractionPrompt
	if prompt != null:
		prompt.interacted.connect(_on_interacted)
		prompt.player_near.connect(_on_player_near)

func _on_player_near() -> void:
	# começa a carregar o destino em segundo plano antes do jogador confirmar
	if target_scene != "":
		SceneTransition.preload_scene(target_scene)

func _on_interacted() -> void:
	if target_scene != "":
		SceneTransition.change_scene(target_scene, spawn_id)
