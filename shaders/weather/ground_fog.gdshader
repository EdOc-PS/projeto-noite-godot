shader_type fog;
// Névoa rasteira (ground fog / low-lying fog) pro cenário todo, num FogVolume
// caixa que segue o jogador (scripts/weather/ground_fog.gd).
// - Altura: densa colada no chão e some até `fog_height` (curva exponencial).
// - Volume: duas camadas de ruído 3D (NoiseTexture3D, só o canal vermelho)
//   em escalas diferentes, andando com o vento em velocidades diferentes, com
//   contraste (`noise_low`..`noise_high`): fica em "gomos" e fiapos, não um véu.
// - Laterais da caixa somem suave, sem corte reto.
// Futuro: buracos (clareiras) dá pra fazer com uma máscara 2D subtraindo DENSITY.

uniform vec3 fog_color : source_color = vec3(1.0);
uniform float emission_amount = 0.25;          // brilho próprio (não escurecer o verde)
uniform float density = 1.6;
uniform float fog_height = 0.35;                // m acima do chão onde quase acaba
uniform float height_falloff = 2.2;            // maior = topo mais definido
uniform float ground_y = 0.0;

uniform sampler3D noise_tex : repeat_enable, filter_linear;
uniform float noise_scale = 14.0;              // m por repetição da camada grande
uniform float detail_scale = 4.5;              // m por repetição da camada de detalhe
uniform vec3 wind = vec3(0.6, 0.0, -0.01);     // m/s (direção do vento)
uniform float noise_low : hint_range(0.0, 1.0) = 0.22;   // abaixo disso: vazio
uniform float noise_high : hint_range(0.0, 1.0) = 0.7;   // acima disso: cheio
uniform float edge_fade = 6.0;                 // m de fade nas bordas da caixa

void fog() {
	vec3 p = WORLD_POSITION;
	float h = max(p.y - ground_y, 0.0);
	// colada no chão, some até fog_height
	float height_mask = exp(-height_falloff * h / max(fog_height, 0.01)) * (1.0 - smoothstep(fog_height * 0.75, fog_height, h));

	// camada grande (bancos de névoa) + detalhe (fiapos), andando com o vento
	float big = texture(noise_tex, (p + wind * TIME) / noise_scale).r;
	float det = texture(noise_tex, (p + wind * TIME * 1.7 + vec3(13.0, 0.0, 7.0)) / detail_scale).r;
	float n = big * 0.7 + det * 0.3;
	// topo em gomos: quanto mais alto, mais o ruído precisa ser forte pra ter névoa
	float lo = noise_low + h / max(fog_height, 0.01) * 0.25;
	float shape = smoothstep(lo, max(noise_high, lo + 0.05), n);

	// fade só nas laterais da caixa (em cima e embaixo quem manda é a altura)
	vec2 inside = SIZE.xz * 0.5 - abs(p.xz - OBJECT_POSITION.xz);
	float edge = clamp(min(inside.x, inside.y) / max(edge_fade, 0.01), 0.0, 1.0);
	DENSITY = density * height_mask * shape * edge;
	ALBEDO = fog_color;
	EMISSION = fog_color * emission_amount;
}
