extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = 20.0

func _ready() -> void:
	# chegando de outra cena: vai pro ponto de chegada pedido (antes da câmera fazer o _ready)
	var spawn := SceneTransition.get_spawn_point()
	if spawn != null:
		global_position = spawn.global_position
		rotation.y = spawn.global_rotation.y

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)

	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		var target_angle := atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 10.0)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	# vegetação reage ao jogador (wind_sway.gdshader)
	RenderingServer.global_shader_parameter_set(&"player_pos", global_position)
