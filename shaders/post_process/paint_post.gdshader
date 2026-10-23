// Filtro de tela "pintado" (porte do botw_post do projeto antigo, sem a cor por
// hora): pintura leve (Kuwahara: cada pixel vira a média do quadrante com menos
// variação → manchas de pincel), nitidez de leve e saturação. Num ColorRect de
// tela cheia (scenes/vfx/paint_post.tscn), lê a imagem final.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

group_uniforms pintura;
uniform float paint_amount : hint_range(0.0, 1.0) = 0.35;
uniform int paint_radius : hint_range(1, 4) = 2;

group_uniforms nitidez;
uniform float sharpen : hint_range(0.0, 1.0) = 0.2;

group_uniforms cor;
uniform float saturation : hint_range(0.0, 2.0) = 1.15;

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

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 base = textureLod(screen_tex, uv, 0.0).rgb;
	vec3 col = base;
	if (paint_amount > 0.0) {
		col = mix(col, kuwahara(uv, px), paint_amount);
	}
	vec3 n_sum = textureLod(screen_tex, uv + vec2(px.x, 0.0), 0.0).rgb + textureLod(screen_tex, uv - vec2(px.x, 0.0), 0.0).rgb
		+ textureLod(screen_tex, uv + vec2(0.0, px.y), 0.0).rgb + textureLod(screen_tex, uv - vec2(0.0, px.y), 0.0).rgb;
	col += (base - n_sum * 0.25) * sharpen;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
