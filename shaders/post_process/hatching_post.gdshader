// Hachura de lápis na TELA INTEIRA (estilo "lápiz artístico"). Adaptado do
// "Hatching shader" de annie (godotshaders.com/shader/hatching-shader, MIT,
// .docs/licencas/hatching_LICENSE.txt). O original é por material e usa uma
// direção de luz fixa; aqui a mesma ideia vira pós-processamento: onde a
// imagem é escura (sombra), entram riscos diagonais; quanto mais escuro, mais
// grossos. Os riscos tremem em "baixo FPS" (troca a cada 0,15 s) como desenho
// à mão, com ângulo/posição/grossura sorteados por ruído.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform vec3 line_color : source_color = vec3(0.16, 0.14, 0.22);  // cor do lápis
uniform float strength : hint_range(0.0, 1.0) = 0.7;             // quanto o risco escurece
uniform float range : hint_range(0.0, 1.0) = 0.55;                // luminância abaixo da qual começa a hachura
uniform float softness : hint_range(0.0, 1.0) = 0.06;             // borda do risco (macio)
uniform float angle : hint_range(0.0, 360.0) = 45.0;
uniform float pattern_scale : hint_range(1.0, 40.0) = 3.5;        // pixels entre riscos
uniform float line_thickness : hint_range(0.0, 1.0) = 0.06;       // grossura no começo da sombra
uniform float dark_thickness : hint_range(0.0, 1.0) = 0.22;       // grossura extra no mais escuro
uniform bool cross_hatch = false;                                  // segunda camada cruzada no bem escuro
// contorno de lápis: onde a cor muda de repente (borda do objeto), um traço
// fino e tremido (deslocado pelo ruído, muda junto com o "baixo FPS")
uniform float outline_strength : hint_range(0.0, 1.0) = 0.85;
uniform float outline_width : hint_range(0.5, 4.0) = 1.2;     // pixels
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.12; // diferença de cor que vira borda
uniform float outline_wobble : hint_range(0.0, 4.0) = 1.2;     // quanto o traço treme (pixels)
// aleatoriedade (o "à mão")
uniform float random_thickness : hint_range(0.0, 2.0) = 0.4;
uniform float random_offset : hint_range(0.0, 10.0) = 1.5;
uniform float random_angle : hint_range(0.0, 30.0) = 8.0;
uniform float noise_scale = 0.02;
// tremido de desenho animado
uniform float fps_effect_strength : hint_range(0.0, 1.0) = 0.5;
uniform float fps_speed : hint_range(0.1, 10.0) = 1.0;
uniform float line_jitter_amount : hint_range(0.0, 1.0) = 0.25;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float hatch(vec2 frag, float ang_deg, float noise, float fps_var, float thick) {
	float rand_angle = ang_deg + (noise - 0.5) * random_angle + fps_var * 5.0 * line_jitter_amount;
	float rand_offset = (noise - 0.5) * random_offset + fps_var * 2.0 * line_jitter_amount;
	float t = thick + (noise - 0.5) * random_thickness * thick;
	vec2 p = frag / pattern_scale;
	float rad = radians(rand_angle);
	float y = p.x * sin(rad) + p.y * cos(rad);
	float h = sin((y + rand_offset) * 3.14159);
	// 1 = no risco
	return 1.0 - smoothstep(-softness, softness, abs(h) - (1.0 - t));
}

void fragment() {
	vec3 col = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float dark = clamp((range - lum) / max(range, 0.001), 0.0, 1.0);  // 0 = luz, 1 = bem escuro
	float frame_time = floor(TIME * fps_speed / 0.15) * 0.15;
	float fps_var = sin(frame_time * 3.0) * fps_effect_strength;
	float n = vnoise(FRAGCOORD.xy * noise_scale + frame_time * 0.7 * fps_effect_strength);
	float lines = 0.0;
	if (dark > 0.0) {
		lines = hatch(FRAGCOORD.xy, angle, n, fps_var, line_thickness + dark_thickness * dark) * smoothstep(0.0, 0.15, dark);
		if (cross_hatch && dark > 0.5) {
			lines = max(lines, hatch(FRAGCOORD.xy, angle + 90.0, n, fps_var, line_thickness + dark_thickness * (dark - 0.5)) * smoothstep(0.5, 0.7, dark));
		}
	}
	vec3 outc = mix(col, col * line_color * 2.0, lines * strength);
	if (outline_strength > 0.0) {
		vec2 px = SCREEN_PIXEL_SIZE;
		vec2 wob = (vec2(vnoise(FRAGCOORD.xy * 0.05 + frame_time * 3.1), vnoise(FRAGCOORD.yx * 0.05 - frame_time * 2.3)) - 0.5) * 2.0 * outline_wobble;
		vec2 uv = SCREEN_UV + wob * px;
		vec2 o = px * outline_width;
		vec3 l = textureLod(screen_tex, uv - vec2(o.x, 0.0), 0.0).rgb;
		vec3 r = textureLod(screen_tex, uv + vec2(o.x, 0.0), 0.0).rgb;
		vec3 u = textureLod(screen_tex, uv - vec2(0.0, o.y), 0.0).rgb;
		vec3 d = textureLod(screen_tex, uv + vec2(0.0, o.y), 0.0).rgb;
		float e = smoothstep(outline_threshold, outline_threshold * 2.0, length(r - l) + length(d - u));
		// traço de grafite: falha um pouco (ruído) como lápis no papel
		e *= mix(0.6, 1.0, vnoise(FRAGCOORD.xy * 0.3));
		outc = mix(outc, line_color, e * outline_strength);
	}
	COLOR = vec4(outc, 1.0);
}
