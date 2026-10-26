// Tufo de florzinhas em PNG (tools/gen_flower_textures.py): caules em duas
// cartas cruzadas e as flores numa carta deitada (vista de cima). Balança e dobra com o vento global (mesmos
// globais do wind_sway) e recebe luz "de cima" (normal pra cima), então não
// fica com um lado escuro. Usado pelo scripts/vegetation/flower_field.gd.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform float sway_strength = 0.12;
uniform float bend_max = 0.9;
uniform bool flat_card = false;  // carta deitada das flores: anda inteira (no topo dos caules)

global uniform vec2 wind_direction;
global uniform float wind_strength;
global uniform float wind_gust;
global uniform vec3 player_pos;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float h = flat_card ? 1.0 : 1.0 - UV.y;  // 0 na base, 1 no topo
	vec2 wd = length(wind_direction) > 0.5 ? normalize(wind_direction) : vec2(1.0, 0.3);
	vec3 l = inverse(mat3(MODEL_MATRIX)) * vec3(wd.x, 0.0, wd.y);
	vec2 ld = length(l.xz) > 0.0001 ? normalize(l.xz) : wd;
	float phase = TIME * 1.8 + dot(origin.xz, vec2(0.41, 0.27));
	float s = 0.4 + 0.6 * sin(phase);
	float a = wind_gust * bend_max * (0.6 + 0.4 * fract(sin(dot(origin.xz, vec2(12.9898, 78.233))) * 43758.5453));
	vec2 off = ld * (sin(a) + s * sway_strength * wind_strength) * VERTEX.y * h;
	VERTEX.xz += off;
	VERTEX.y += (cos(a) - 1.0) * VERTEX.y * h;
	// jogador passando: abaixa um pouco
	float d = length(origin.xz - player_pos.xz);
	VERTEX.y *= mix(0.55, 1.0, smoothstep(0.25, 0.8, d));
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	ALBEDO = c.rgb;
	// luz sempre "de cima" nos dois lados da carta (o verso virava a normal
	// pra baixo e a flor ficava preta à noite)
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
