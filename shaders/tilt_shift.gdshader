shader_type canvas_item;
// Efeito tilt-shift (miniatura/diorama): desfoca o topo e o rodapé da tela,
// mantendo uma faixa horizontal nítida no meio.
// Desfoque suave tipo "vidro fosco": lê mipmaps da tela (já pré-desfocados
// pela GPU) e mistura 16 amostras num disco em espiral, em vez de poucas
// amostras espaçadas (que dão aspecto pixelado/duplicado).

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float focus_center : hint_range(0.0, 1.0) = 0.55; // altura (0=topo, 1=rodapé) do centro da faixa nítida
uniform float focus_width : hint_range(0.0, 1.0) = 0.22;  // meia-largura da faixa totalmente nítida
uniform float falloff : hint_range(0.0, 1.0) = 0.25;      // distância extra até o desfoque máximo
uniform float blur_amount : hint_range(0.0, 12.0) = 5.0;  // força do desfoque nas bordas

const int SAMPLES = 16;
const float GOLDEN_ANGLE = 2.39996;

void fragment() {
	float dist = abs(SCREEN_UV.y - focus_center);
	float blur_factor = smoothstep(focus_width, focus_width + falloff, dist);

	// nível de mipmap cresce com o desfoque (0 = imagem nítida)
	float lod = blur_factor * log2(1.0 + blur_amount);
	vec2 radius = SCREEN_PIXEL_SIZE * blur_amount * blur_factor * 1.5;

	vec4 sum = vec4(0.0);
	for (int i = 0; i < SAMPLES; i++) {
		float r = sqrt((float(i) + 0.5) / float(SAMPLES));
		float a = float(i) * GOLDEN_ANGLE;
		vec2 offset = vec2(cos(a), sin(a)) * r * radius;
		sum += textureLod(screen_tex, SCREEN_UV + offset, lod);
	}
	COLOR = sum / float(SAMPLES);
}
