extends Node3D
## Sombras de nuvens passando (manhã e tarde). Cada nuvem é um plano
## INVISÍVEL no céu que só projeta sombra (cast_shadow = só sombra, recorte
## nítido pela forma): a sombra é a mesma sombra do sol que os objetos fazem.
##
## - Posição: aleatória, mas **em volta do jogador** (nasce perto dele, do lado
##   de onde vem o vento, e anda com o vento pelo mundo). Quando fica longe do
##   jogador, renasce em outro ponto perto dele, com outro tamanho/forma.
## - Tamanho aleatório (`size_range`).
## - Forma de nuvem de verdade: um corpo central com **gomos** em volta do
##   contorno (curvas, como nuvem de desenho), não um círculo espichado.
##
## Grupo `cloud_fx`: o WeatherCycle chama `set_strength()` (dia 1, noite 0).
## Regras em .docs/plans/06-clima.md.

@export var cloud_count: int = 3                     ## poucas: céu "parcialmente nublado"
@export var radius: float = 30.0                     ## distância máx. do jogador antes de renascer
@export var size_range: Vector2 = Vector2(12.0, 26.0) ## tamanho das nuvens (m)
@export var speed: float = 0.5                       ## m/s (devagar)
@export var wind_dir: Vector2 = Vector2(1.0, -0.02)  ## mesmo vento do resto
@export var height: float = 7.0                      ## altura das nuvens (acima de tudo da cena)
@export var sun: DirectionalLight3D                  ## pra sombra cair em volta do jogador mesmo com sol baixo
@export var shapes: int = 6                          ## variações de forma

var strength := 1.0
const SHADER := preload("res://shaders/weather/cloud_shadow.gdshader")
var _shapes: Array = []  # cada forma: Array de Vector4 (x, y, raio, usado)
var _clouds: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _player: Node3D
var _ground := {}  # nuvem -> ponto no CHÃO onde a sombra cai (anda com o vento)

func _ready() -> void:
	add_to_group("cloud_fx")
	_rng.randomize()
	for i in shapes:
		_shapes.append(_make_shape(i))
	for i in cloud_count:
		var d := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE
		d.mesh = plane
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		# forma calculada no shader (borda lisa, sem textura esticada)
		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter(&"blobs", _shapes[i % _shapes.size()])
		d.material_override = mat
		d.top_level = true  # anda no mundo, não junto com este node
		add_child(d)
		_clouds.append(d)
	_respawn_all.call_deferred()
	set_strength(strength)

func set_strength(v: float) -> void:
	strength = clampf(v, 0.0, 1.0)
	# recorte nítido não tem transparência: em vez de sumir de uma vez (piscava),
	# a nuvem encolhe até sumir no anoitecer
	visible = strength > 0.01

func _process(delta: float) -> void:
	# a nuvem anda pelo CHÃO (onde a sombra cai) e a posição no céu é
	# recalculada pelo sol a cada frame: quando o sol muda (troca de período),
	# a sombra não pula, não volta nem renasce
	var center := _player_pos()
	var dir := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	var k := smoothstep(0.0, 1.0, strength)
	for d in _clouds:
		if not _ground.has(d):
			continue
		var g: Vector3 = _ground[d] + dir * speed * delta
		_ground[d] = g
		var off := g - center
		off.y = 0.0
		if off.length() > radius + d.get_meta(&"size", 10.0) * 0.5:
			_respawn(d, false)
			g = _ground[d]
		var s: Vector2 = d.get_meta(&"scale2", Vector2.ONE)
		d.scale = Vector3(s.x * k, 1.0, s.y * k)
		d.global_position = g + _sun_offset()

func _respawn_all() -> void:
	for d in _clouds:
		_respawn(d, true)

## Nova nuvem perto do jogador, com tamanho sorteado. `anywhere` = em qualquer
## ponto em volta dele (início); senão nasce do lado de onde vem o vento, pra
## entrar andando.
func _respawn(d: MeshInstance3D, anywhere: bool) -> void:
	var s := _rng.randf_range(size_range.x, size_range.y)
	var stretch := _rng.randf_range(0.7, 1.0)
	d.set_meta(&"size", s)
	d.set_meta(&"scale2", Vector2(s, s * stretch))
	d.scale = Vector3(s, 1.0, s * stretch)
	d.rotation.y = _rng.randf_range(0.0, TAU)
	var center := _player_pos()
	var dir := Vector3(wind_dir.x, 0.0, wind_dir.y).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x)
	var pos: Vector3
	if anywhere:
		var a := _rng.randf() * TAU
		pos = center + Vector3(cos(a), 0.0, sin(a)) * _rng.randf_range(0.0, radius)
	else:
		pos = center - dir * _rng.randf_range(radius * 0.6, radius) + side * _rng.randf_range(-radius * 0.7, radius * 0.7)
	_ground[d] = Vector3(pos.x, 0.0, pos.z)
	d.global_position = _ground[d] + _sun_offset()

func _player_pos() -> Vector3:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	return _player.global_position if _player != null else global_position

## Do ponto no chão até onde a nuvem precisa estar no céu pra sombra cair ali.
## Com o sol baixo (tarde) a sombra cai longe da nuvem.
func _sun_offset() -> Vector3:
	var o := Vector3(0.0, height, 0.0)
	if sun != null:
		var l := -sun.global_transform.basis.z           # pra onde a luz vai
		var down := maxf(-l.y, 0.15)                      # sol muito baixo: limita o deslocamento
		o -= Vector3(l.x, 0.0, l.z) * (height / down)
	return o

## Forma de nuvem vista de cima: corpo central + gomos em volta do contorno
## (o shader une em curvas lisas). Devolve até 10 Vector4 (x, y, raio, usado).
func _make_shape(seed_i: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed_i * 77
	var out: Array = []
	# mancha ÚNICA e cheia: corpo grande + poucos lóbulos largos (bem fundidos
	# pelo `smoothness` baixo do shader), não um anel de bolinhas
	var core := rng.randf_range(0.24, 0.28)
	out.append(Vector4(0.5, 0.5, core, 1.0))
	var lobes := rng.randi_range(3, 5)
	var phase := rng.randf() * TAU
	for i in lobes:
		var a := phase + TAU * i / lobes + rng.randf_range(-0.4, 0.4)
		var lr := rng.randf_range(0.13, 0.2)
		var dist := core * rng.randf_range(0.55, 0.85)   # lóbulo bem dentro do corpo: só estica a forma
		out.append(Vector4(0.5 + cos(a) * dist, 0.5 + sin(a) * dist, lr, 1.0))
	while out.size() < 10:
		out.append(Vector4.ZERO)
	return out
