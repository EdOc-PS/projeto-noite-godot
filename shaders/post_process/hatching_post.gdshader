// CONTORNO DE LÁPIS na tela inteira: onde a cor muda de repente (borda dos
// objetos) entra um traço fino, tremido e falhado como grafite. Nasceu do
// "Hatching shader" de annie (godotshaders.com/shader/hatching-shader, MIT,
// .docs/licencas/hatching_LICENSE.txt): a hachura (riscos nas sombras) saiu;
// ficou o tremido em "baixo FPS" (troca a cada 0,15 s) no contorno.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform vec3 line_color : source_color = vec3(0.16, 0.14, 0.22);  // cor do lápis
// contorno de lápis: onde a cor muda de repente (borda do objeto), um traço
// fino e tremido (deslocado pelo ruído, muda junto com o "baixo FPS")
uniform float outline_strength : hint_range(0.0, 1.0) = 0.85;
uniform float outline_width : hint_range(0.5, 4.0) = 1.2;     // pixels
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.12; // diferença de cor que vira borda
uniform float outline_wobble : hint_range(0.0, 4.0) = 1.2;     // quanto o traço treme (pixels)
uniform float fps_speed : hint_range(0.1, 10.0) = 1.0;

float h21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec3 col = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float frame_time = floor(TIME * fps_speed / 0.15) * 0.15;
	vec3 outc = col;
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
