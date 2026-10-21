extends Node
## Color grading estilo Link's Awakening: gera, ao iniciar, uma LUT 3D e põe
## em `Environment.adjustment_color_correction`. Diferente da saturação global
## (que satura tudo por igual), a LUT dá "vibrance" (satura mais o que está
## apagado e quase não mexe no que já é vivo), puxa os verdes e o céu, e tinge
## de leve sombras (frias) e luzes (quentes). Regras em .docs/plans/11-estilo-visual.md.

@export var world_environment: WorldEnvironment
@export_range(0.0, 1.0) var vibrance: float = 0.5      ## satura os tons apagados
@export_range(0.0, 1.0) var green_boost: float = 0.4   ## saturação extra em verdes
@export_range(0.0, 1.0) var sky_boost: float = 0.15     ## saturação extra em azul-céu
@export var shadow_tint: Color = Color(0.0, 0.01, 0.03) ## somado nas sombras
@export var highlight_tint: Color = Color(0.025, 0.012, 0.0) ## somado nas luzes
@export_range(0.0, 1.0) var s_curve: float = 0.15       ## contraste suave (curva em S)

const SIZE := 17   ## LUT 17³ (padrão de color grading; interpolada pela GPU)
const STEPS := 8   ## LUTs pré-geradas de força 1 até 0, pra trocar suave pela hora

## Força atual (0 = sem grading, igual à noite do outside; 1 = grading cheio do dia).
## O weather_cycle.gd chama set_strength().
var _luts: Array[ImageTexture3D] = []
var _strength := 1.0

func _ready() -> void:
	if world_environment == null:
		return
	for i in STEPS:
		_luts.append(_build(1.0 - i / float(STEPS - 1)))
	set_strength(_strength)

func set_strength(v: float) -> void:
	_strength = clampf(v, 0.0, 1.0)
	if _luts.is_empty():
		return
	var i := roundi((1.0 - _strength) * (STEPS - 1))
	# força 0: sem LUT nenhuma, a imagem fica idêntica à das cenas sem grading
	world_environment.environment.adjustment_color_correction = null if i == STEPS - 1 else _luts[i]

func _build(k: float) -> ImageTexture3D:
	var slices: Array[Image] = []
	for b in SIZE:
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
		for g in SIZE:
			for r in SIZE:
				var c := Color(r / float(SIZE - 1), g / float(SIZE - 1), b / float(SIZE - 1))
				var o := _grade(c)
				img.set_pixel(r, g, c.lerp(o, k))
		slices.append(img)
	var lut := ImageTexture3D.new()
	lut.create(Image.FORMAT_RGB8, SIZE, SIZE, SIZE, false, slices)
	return lut

func _grade(c: Color) -> Color:
	var luma := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var sat := c.s
	# vibrance: mais efeito em cores pouco saturadas, quase nada nas já vivas
	var boost := vibrance * (1.0 - sat)
	# verdes (hue ~0,22–0,45) e azul-céu (~0,52–0,62) ganham um extra
	var h := c.h
	boost += green_boost * _band(h, 0.22, 0.45) * (1.0 - sat * 0.5)
	boost += sky_boost * _band(h, 0.52, 0.62) * (1.0 - sat * 0.5)
	var out := Color(
		lerpf(luma, c.r, 1.0 + boost),
		lerpf(luma, c.g, 1.0 + boost),
		lerpf(luma, c.b, 1.0 + boost))
	# sombras frias, luzes quentes
	out.r += shadow_tint.r * (1.0 - luma) + highlight_tint.r * luma
	out.g += shadow_tint.g * (1.0 - luma) + highlight_tint.g * luma
	out.b += shadow_tint.b * (1.0 - luma) + highlight_tint.b * luma
	# curva em S suave
	out.r = lerpf(out.r, smoothstep(0.0, 1.0, out.r), s_curve)
	out.g = lerpf(out.g, smoothstep(0.0, 1.0, out.g), s_curve)
	out.b = lerpf(out.b, smoothstep(0.0, 1.0, out.b), s_curve)
	return Color(clampf(out.r, 0.0, 1.0), clampf(out.g, 0.0, 1.0), clampf(out.b, 0.0, 1.0))

## 1 dentro da faixa de hue [a, b], caindo suave nas bordas.
func _band(h: float, a: float, b: float) -> float:
	var w := 0.05
	return smoothstep(a - w, a, h) * (1.0 - smoothstep(b, b + w, h))
