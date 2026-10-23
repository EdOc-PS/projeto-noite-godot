shader_type fog;
// Névoa rasteira (ground fog) pro cenário todo, num FogVolume caixa que segue o
// jogador (scripts/weather/ground_fog.gd). Técnica do vídeo "All about Fog
// Shader in Godot 4.0" (youtube zDRgxDuR1bY):
// - Ruído 2D (mais leve que 3D), lido pela posição no MUNDO (x, z): mudar o
//   tamanho da caixa não estica a textura. Textura seamless + repeat.
// - Ruído de detalhe DISTORCE a coordenada do ruído principal (domain warp):
//   quebra a repetição e dá fiapos.
// - Embaixo a densidade é cheia e vai virando o ruído conforme sobe
//   (mix pelo UVW.y × `flatness`): base sólida, topo em gomos.
// - Cor pela densidade (gradiente opcional): onde é mais densa, outra cor.
// - Laterais da caixa somem suave, sem corte reto.
// Futuro: clareiras (parecer nuvens) com uma máscara 2D subtraindo DENSITY.

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;    // ruído principal (seamless)
uniform sampler2D detail_tex : repeat_enable, filter_linear_mipmap;   // ruído de detalhe (seamless)
uniform sampler2D color_ramp : repeat_disable, filter_linear;         // cor pela densidade (0..1)
uniform bool use_color_ramp = false;
uniform vec3 fog_color : source_color = vec3(1.0);
uniform float emission_amount = 0.25;      // brilho próprio (não escurecer o verde)

uniform float density = 1.6;               // densidade final
uniform float noise_scale = 0.06;          // 1/m do ruído principal (menor = manchas maiores)
uniform float detail_scale = 0.18;         // 1/m do ruído de detalhe
uniform float warp = 0.2;                  // quanto o detalhe distorce o principal
uniform float flatness = 1.0;              // maior = vira ruído mais rápido ao subir
uniform vec2 move = vec2(0.0);             // m/s (0 = parada); o detalhe anda na metade
uniform float noise_low : hint_range(0.0, 1.0) = 0.25;  // contraste: abaixo disso, vazio
uniform float noise_high : hint_range(0.0, 1.0) = 0.7;  // acima disso, cheio
uniform float edge_fade = 6.0;             // m de fade nas laterais da caixa

void fog() {
	vec3 p = WORLD_POSITION;
	vec2 uv = p.xz;
	float detail = texture(detail_tex, (uv + move * TIME * 0.5) * detail_scale).r;
	float n = texture(noise_tex, (uv + move * TIME) * noise_scale + detail * warp).r;
	n = smoothstep(noise_low, noise_high, n);
	// embaixo cheia (1), subindo vira o ruído; e some no topo da caixa
	float d = mix(1.0, n, clamp(UVW.y * flatness, 0.0, 1.0));
	d *= 1.0 - smoothstep(0.6, 1.0, UVW.y);

	vec2 inside = SIZE.xz * 0.5 - abs(p.xz - OBJECT_POSITION.xz);
	d *= clamp(min(inside.x, inside.y) / max(edge_fade, 0.01), 0.0, 1.0);

	DENSITY = density * d;
	vec3 col = use_color_ramp ? texture(color_ramp, vec2(clamp(d, 0.0, 1.0), 0.5)).rgb : fog_color;
	ALBEDO = col;
	EMISSION = col * emission_amount;
}
