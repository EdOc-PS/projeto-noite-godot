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

const SIZE := 32

func _ready() -> void:
	if world_environment == null:
		return
	var slices: Array[Image] = []
	for b in SIZE:
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
		for g in SIZE:
			for r in SIZE:
				var c := Color(r / float(SIZE - 1), g / float(SIZE - 1), b / float(SIZE - 1))
				img.set_pixel(r, g, _grade(c))
		slices.append(img)
	var lut := ImageTexture3D.new()
	lut.create(Image.FORMAT_RGB8, SIZE, SIZE, SIZE, false, slices)
	world_environment.environment.adjustment_color_correction = lut

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
