shader_type spatial;
// Névoa baixa em "cartões" (planos horizontais) nas bordas do mapa.
// Ruído rolando devagar + fade nas bordas do plano + fade suave onde o
// plano encosta em objetos (não aparece a linha de corte).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 fog_color : source_color = vec4(0.22, 0.26, 0.42, 1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform float density = 0.7;
uniform float noise_scale = 0.08;
uniform vec2 scroll = vec2(0.015, 0.008);
uniform float edge_softness = 0.35;  // fade nas bordas do plano (em UV)
uniform float soft_distance = 0.8;   // fade ao encostar em objetos

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float n = texture(noise_tex, world_xz * noise_scale + TIME * scroll).r;
	n *= texture(noise_tex, world_xz * noise_scale * 1.9 - TIME * scroll * 0.7).r * 1.6;

	vec2 e = smoothstep(vec2(0.0), vec2(edge_softness), UV)
		* smoothstep(vec2(0.0), vec2(edge_softness), 1.0 - UV);

	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = scene.z / scene.w;
	float soft = clamp((VERTEX.z - scene_z) / soft_distance, 0.0, 1.0);

	ALBEDO = fog_color.rgb;
	ALPHA = clamp(n * e.x * e.y * soft * density, 0.0, 1.0);
}
