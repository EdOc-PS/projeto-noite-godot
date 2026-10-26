// Filtro de tela de AQUARELA, num ColorRect de tela cheia
// (scenes/vfx/paint_post.tscn), lendo a imagem final. Em ordem:
//  1. pincelada (Kuwahara: cada pixel vira a média do quadrante com menos
//     variação → manchas de tinta, bordas mantidas);
//  2. borda escurecida: onde uma cor encontra outra a tinta acumula e escurece;
//  3. cor viva: sombras puxadas pro azul, luzes pro amarelo quente;
//  4. textura de papel de aquarela (granulação + fibras), fixa na tela.
// Regras: .docs/plans/06-pos-processamento.md.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

group_uniforms pincelada;
uniform float paint_amount : hint_range(0.0, 1.0) = 0.85;
uniform int paint_radius : hint_range(1, 4) = 2;

group_uniforms borda_aquarela;
uniform float edge_darken : hint_range(0.0, 1.0) = 0.35;   // quanto a borda entre cores escurece
uniform float edge_width : hint_range(0.5, 4.0) = 1.5;     // largura da borda (pixels)
uniform float edge_threshold : hint_range(0.0, 0.5) = 0.04; // diferença mínima de cor pra virar borda

group_uniforms cor;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;     // a saturação principal está no Environment (1,3)
uniform vec3 shadow_tint : source_color = vec3(0.86, 0.92, 1.08);   // sombras pro azul
uniform vec3 light_tint : source_color = vec3(1.06, 1.02, 0.9);     // luzes pro amarelo quente
uniform float tint_amount : hint_range(0.0, 1.0) = 0.6;

group_uniforms papel;
uniform float paper_amount : hint_range(0.0, 0.5) = 0.12;  // 10–15%: bem leve
uniform float paper_scale = 1.0;                            // maior = grão mais fino

group_uniforms nitidez;
uniform float sharpen : hint_range(0.0, 1.0) = 0.0;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// papel: grão miúdo + manchas largas + fibras compridas (ruído esticado)
float paper(vec2 frag) {
	vec2 p = frag * paper_scale;
	float grain = h21(floor(p));
	float blot = vnoise(p / 90.0) * 0.6 + vnoise(p / 30.0) * 0.4;
	float fiber = vnoise(vec2(p.x / 3.0, p.y / 40.0)) * 0.5 + vnoise(vec2(p.x / 45.0, p.y / 2.5)) * 0.5;
	return grain * 0.35 + blot * 0.4 + fiber * 0.25;  // ~0..1, média 0,5
}

vec3 kuwahara(vec2 uv, vec2 px) {
	vec3 best = vec3(0.0);
	float best_var = 1e9;
	for (int q = 0; q < 4; q++) {
		vec2 dir = vec2(q % 2 == 0 ? -1.0 : 1.0, q < 2 ? -1.0 : 1.0);
		vec3 sum = vec3(0.0);
		vec3 sum2 = vec3(0.0);
		float n = 0.0;
		for (int x = 0; x <= paint_radius; x++) {
			for (int y = 0; y <= paint_radius; y++) {
				vec3 c = textureLod(screen_tex, uv + vec2(float(x), float(y)) * dir * px, 0.0).rgb;
				sum += c;
				sum2 += c * c;
				n += 1.0;
			}
		}
		vec3 m = sum / n;
		vec3 v = sum2 / n - m * m;
		float var = v.r + v.g + v.b;
		if (var < best_var) {
			best_var = var;
			best = m;
		}
	}
	return best;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 base = textureLod(screen_tex, uv, 0.0).rgb;
	vec3 col = base;
	if (paint_amount > 0.0) {
		col = mix(col, kuwahara(uv, px), paint_amount);
	}
	if (sharpen > 0.0) {
		vec3 n_sum = textureLod(screen_tex, uv + vec2(px.x, 0.0), 0.0).rgb + textureLod(screen_tex, uv - vec2(px.x, 0.0), 0.0).rgb
			+ textureLod(screen_tex, uv + vec2(0.0, px.y), 0.0).rgb + textureLod(screen_tex, uv - vec2(0.0, px.y), 0.0).rgb;
		col += (base - n_sum * 0.25) * sharpen;
	}
	// borda escurecida: diferença de cor com os vizinhos (Sobel na luminância e na cor)
	if (edge_darken > 0.0) {
		vec2 o = px * edge_width;
		vec3 l = textureLod(screen_tex, uv - vec2(o.x, 0.0), 0.0).rgb;
		vec3 r = textureLod(screen_tex, uv + vec2(o.x, 0.0), 0.0).rgb;
		vec3 u = textureLod(screen_tex, uv - vec2(0.0, o.y), 0.0).rgb;
		vec3 d = textureLod(screen_tex, uv + vec2(0.0, o.y), 0.0).rgb;
		float diff = length(r - l) + length(d - u);
		float e = smoothstep(edge_threshold, edge_threshold * 4.0, diff);
		// tinta acumulada: escurece e satura um pouco (não fica cinza)
		col = mix(col, col * col * 1.1, e * edge_darken);
	}
	// cor viva: sombras azuladas, luzes quentes
	float lum = luma(col);
	vec3 tint = mix(shadow_tint, light_tint, smoothstep(0.15, 0.75, lum));
	col = mix(col, col * tint, tint_amount);
	col = mix(vec3(luma(col)), col, saturation);
	// papel: multiplica em volta de 1 (o claro clareia, o escuro escurece de leve)
	float pp = paper(FRAGCOORD.xy);
	col *= 1.0 + (pp - 0.5) * 2.0 * paper_amount;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
