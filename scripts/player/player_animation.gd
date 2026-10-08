extends Node
## Animações do personagem (KayKit Character Animations, rig "Rig_Medium").
## O modelo (`mannequin_medium.glb`) vem sem animações; elas ficam em glTFs
## separados com o mesmo esqueleto. Ao iniciar, copiamos as bibliotecas de
## animação desses glTFs pra um AnimationPlayer no modelo e escolhemos a
## animação pela velocidade do CharacterBody3D (parado / andando / correndo).

@export var model_path: NodePath = NodePath("../Model")
@export var animation_scenes: Array[PackedScene] = [
	preload("res://assets/animations/rig_medium/rig_medium_movement_basic.glb"),
	preload("res://assets/animations/rig_medium/rig_medium_general.glb"),
]
@export var idle_anim: StringName = &"Idle_A"
@export var walk_anim: StringName = &"Walking_A"
@export var run_anim: StringName = &"Running_A"
@export var walk_threshold: float = 0.3  ## m/s: abaixo disso fica parado
@export var run_threshold: float = 3.5   ## m/s: acima disso corre
@export var blend_time: float = 0.15
@export var walk_anim_speed: float = 2.0 ## m/s em que a animação de andar tem velocidade 1
@export var run_anim_speed: float = 5.0  ## m/s em que a animação de correr tem velocidade 1

const LOOPED := [&"Idle_A", &"Idle_B", &"Walking_A", &"Walking_B", &"Walking_C", &"Running_A", &"Running_B"]

@onready var _body := get_parent() as CharacterBody3D
var _anim: AnimationPlayer
var _names := {}  ## nome curto ("Walking_A") -> nome completo ("biblioteca/Walking_A")

func _ready() -> void:
	var model := get_node(model_path)
	_anim = AnimationPlayer.new()
	_anim.name = "AnimationPlayer"
	model.add_child(_anim)
	_anim.root_node = NodePath("..")  # trilhas são relativas à raiz do modelo (Rig_Medium/Skeleton3D:...)
	for i in animation_scenes.size():
		var inst := animation_scenes[i].instantiate()
		var src := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if src != null:
			for lib_name in src.get_animation_library_list():
				var lib := src.get_animation_library(lib_name).duplicate(true) as AnimationLibrary
				var key := "lib%d" % i
				_anim.add_animation_library(key, lib)
				for a in lib.get_animation_list():
					if a in LOOPED:
						lib.get_animation(a).loop_mode = Animation.LOOP_LINEAR
					_names[a] = "%s/%s" % [key, a]
		inst.free()
	_play(idle_anim)

func _physics_process(_delta: float) -> void:
	if _body == null or _anim == null:
		return
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	if speed > run_threshold:
		_play(run_anim, speed / run_anim_speed)
	elif speed > walk_threshold:
		_play(walk_anim, speed / walk_anim_speed)
	else:
		_play(idle_anim)

## Toca `anim` (nome curto) com mistura suave; não reinicia se já está tocando.
func play_once(anim: StringName) -> void:
	if _names.has(anim):
		_anim.play(_names[anim], blend_time)

func _play(anim: StringName, speed_scale: float = 1.0) -> void:
	if not _names.has(anim):
		return
	var full: String = _names[anim]
	_anim.speed_scale = clampf(speed_scale, 0.5, 1.6)
	if _anim.current_animation != full:
		_anim.play(full, blend_time)
