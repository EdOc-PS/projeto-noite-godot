shader_type canvas_item;
// Efeito tilt-shift (miniatura/diorama): desfoca as bordas da tela mantendo
// uma área nítida no meio. Com `ellipse_x` > 0 a área nítida é uma elipse
// (borda "convexa": cantos e laterais também desfocam); 0 = faixa horizontal.
// Desfoque suave tipo "vidro fosco": lê mipmaps da tela (já pré-desfocados
// pela GPU) e mistura 16 amostras num disco em espiral, em vez de poucas
// amostras espaçadas (que dão aspecto pixelado/duplicado).

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float focus_center : hint_range(0.0, 1.0) = 0.55; // altura (0=topo, 1=rodapé) do centro da faixa nítida
uniform float focus_width : hint_range(0.0, 1.0) = 0.22;  // meia-largura da faixa totalmente nítida
uniform float falloff : hint_range(0.0, 1.0) = 0.25;      // distância extra até o desfoque máximo
uniform float blur_amount : hint_range(0.0, 12.0) = 5.0;  // força do desfoque nas bordas
uniform float ellipse_x : hint_range(0.0, 1.0) = 0.5;     // quanto as laterais contam (0 = faixa, maior = elipse mais estreita)

// Ar tremendo de calor (meio-dia, setado pelo WeatherCycle; 0 = desligado,
// que é o valor em toda cena sem ciclo de dia): ondula a imagem de leve, mais
// na parte de cima da tela (longe da câmera) que embaixo.
global uniform float heat_haze;

const int SAMPLES = 16;
const float GOLDEN_ANGLE = 2.39996;

void fragment() {
	// distância até o centro da área nítida, numa elipse (largura = altura / ellipse_x)
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;  // largura/altura da tela
	vec2 d = vec2((SCREEN_UV.x - 0.5) * ellipse_x / aspect * 1.6, SCREEN_UV.y - focus_center);
	float dist = length(d);
	float blur_factor = smoothstep(focus_width, focus_width + falloff, dist);

	// nível de mipmap cresce com o desfoque (0 = imagem nítida)
	float lod = blur_factor * log2(1.0 + blur_amount);
	vec2 radius = SCREEN_PIXEL_SIZE * blur_amount * blur_factor * 1.5;

	vec2 uv = SCREEN_UV;
	if (heat_haze > 0.001) {
		float top = 1.0 - smoothstep(0.1, 0.75, SCREEN_UV.y);   // mais no alto da tela
		uv.x += sin(SCREEN_UV.y * 90.0 + TIME * 3.0) * 0.0008 * heat_haze * top;
		uv.y += sin(SCREEN_UV.x * 60.0 + TIME * 2.3) * 0.0005 * heat_haze * top;
	}

	vec4 sum = vec4(0.0);
	for (int i = 0; i < SAMPLES; i++) {
		float r = sqrt((float(i) + 0.5) / float(SAMPLES));
		float a = float(i) * GOLDEN_ANGLE;
		vec2 offset = vec2(cos(a), sin(a)) * r * radius;
		sum += textureLod(screen_tex, uv + offset, lod);
	}
	COLOR = sum / float(SAMPLES);
}
