shader_type spatial;
// Chama cartunesca (estilo Breath of the Wild): forma de gota que se mexe com
// ruído subindo, em faixas de cor bem marcadas: miolo amarelo-claro, meio
// laranja, borda vermelha. Gira só no eixo Y pra câmera (fica sempre em pé).
// Sem luz (unshaded) e com cor acima de 1 pro glow do Environment brilhar.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.93, 0.55, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.55, 0.08, 1.0);
uniform vec4 outer_color : source_color = vec4(0.88, 0.14, 0.04, 1.0);
uniform float brightness = 2.2;          // > 1 pra acender o glow
uniform float speed = 1.6;               // velocidade das línguas subindo
uniform float distortion = 0.35;         // quanto o ruído entorta a chama
uniform float flicker = 0.18;            // pisca rápido do brilho
uniform float time_offset = 0.0;         // dessincroniza chamas vizinhas
uniform float core_band = 0.55;          // a partir daqui é miolo
uniform float mid_band = 0.25;           // a partir daqui é meio (abaixo: borda)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.6 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3 + 7.1) * 0.1;
}

void vertex() {
	// billboard só no Y, mantendo a escala do node
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 fwd = normalize(cross(right, vec3(0.0, 1.0, 0.0)));
	mat4 bb = mat4(vec4(right, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(-fwd, 0.0), MODEL_MATRIX[3]);
	mat4 sc = mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb * sc;
}

void fragment() {
	float t = TIME * speed + time_offset;
	float h = 1.0 - UV.y;                      // 0 na base, 1 no topo
	float n = fbm(vec2(UV.x * 3.0, UV.y * 2.5 + t));
	float n2 = fbm(vec2(UV.x * 5.0 + 11.0, UV.y * 4.0 + t * 1.7));

	// gota: larga e redonda embaixo, afinando pra cima, entortada pelo ruído
	float x = (UV.x - 0.5) * 2.0 + (n - 0.5) * distortion * (0.3 + h * 1.6);
	float width = mix(0.8, 0.05, pow(h, 0.8));
	float shape = 1.0 - abs(x) / width;
	shape -= n2 * 0.75 * h;                    // línguas se soltando no topo
	shape *= smoothstep(0.0, 0.18, h);         // base arredondada
	if (shape <= 0.0) {
		discard;
	}

	vec3 col = outer_color.rgb;
	col = mix(col, mid_color.rgb, smoothstep(mid_band - 0.03, mid_band + 0.03, shape));
	col = mix(col, core_color.rgb, smoothstep(core_band - 0.03, core_band + 0.03, shape));
	float pulse = 1.0 + (noise(vec2(t * 4.0, time_offset)) - 0.5) * 2.0 * flicker;
	ALBEDO = col * brightness * pulse;
	ALPHA = smoothstep(0.0, 0.06, shape);
}
