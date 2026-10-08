shader_type spatial;
// Névoa baixa em "cartões" (planos) nas bordas do mapa.
// Ruído rolando devagar + fade nas bordas do plano + fade suave onde o
// plano encosta em objetos (não aparece a linha de corte).
// A densidade cai com a altura (fog_base -> fog_top), então cartões mais altos
// ficam mais fracos e planos verticais (cortinas) viram névoa que sobe e some.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 fog_color : source_color = vec4(0.22, 0.26, 0.42, 1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform float density = 0.7;
uniform float noise_scale = 0.08;
uniform vec2 scroll = vec2(0.015, 0.008);
uniform float edge_softness = 0.35;    // fade nas bordas do plano, eixo U
uniform float edge_softness_v = 0.35;  // fade nas bordas do plano, eixo V
uniform float soft_distance = 0.8;     // fade ao encostar em objetos
uniform float fog_base = 0.0;          // altura (mundo) onde a névoa é densa
uniform float fog_top = 3.0;           // altura (mundo) onde a névoa some
uniform float noise_height_scale = 4.0; // desloca o ruído por altura (descorrelaciona camadas)

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz + vec2(world_pos.y) * noise_height_scale;
	float n = texture(noise_tex, p * noise_scale + TIME * scroll).r;
	n *= texture(noise_tex, p * noise_scale * 1.9 - TIME * scroll * 0.7).r * 1.6;

	vec2 soft_edge = vec2(edge_softness, edge_softness_v);
	vec2 e = smoothstep(vec2(0.0), soft_edge, UV)
		* smoothstep(vec2(0.0), soft_edge, 1.0 - UV);

	float height_fade = 1.0 - smoothstep(fog_base, fog_top, world_pos.y);

	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = scene.z / scene.w;
	float soft = clamp((VERTEX.z - scene_z) / soft_distance, 0.0, 1.0);

	ALBEDO = fog_color.rgb;
	ALPHA = clamp(n * e.x * e.y * soft * height_fade * density, 0.0, 1.0);
}
