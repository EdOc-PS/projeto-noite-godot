shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
// Poças: plano um pouco acima do chão com manchas de ruído que crescem com a
// chuva (`wetness`). Escuras e lisas (roughness baixa), então refletem o céu
// pelo ReflectionProbe. Regras em .docs/plans/06-clima.md.

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D mask_noise : repeat_enable, filter_linear;
uniform float mask_scale = 14.0;        // metros por repetição do ruído
uniform float coverage = 0.38;          // quanto do chão vira poça na chuva cheia
uniform vec4 water_color : source_color = vec4(0.16, 0.2, 0.28, 0.75);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = texture(mask_noise, v_world.xz / mask_scale).r;
	float limit = 1.0 - coverage * wetness;   // mais chuva, mais área
	float m = smoothstep(limit, limit + 0.04, n);
	ALBEDO = water_color.rgb;
	ROUGHNESS = 0.03;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	ALPHA = m * water_color.a * smoothstep(0.0, 0.3, wetness);
}
