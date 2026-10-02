shader_type spatial;
// Vento: balança os vértices mais altos do mesh (a base fica parada).
// Usado na grama/flores/folhagem e nas árvores, substituindo o material do
// glTF (por isso recebe a mesma textura atlas do pack em albedo_tex).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.5;

uniform float sway_strength = 0.05;  // deslocamento máximo (unidades locais)
uniform float sway_speed = 1.5;
uniform float sway_start = 0.0;      // altura local onde começa a balançar
uniform float sway_height = 0.4;     // quanto acima de sway_start atinge força total
uniform vec2 wind_dir = vec2(1.0, 0.3);

// rim light "vinil" (mesmo efeito do rim_overlay, embutido aqui porque o
// overlay não acompanharia o balanço do vento)
uniform vec4 rim_color : source_color = vec4(0.62, 0.7, 1.0, 1.0);
uniform float rim_power = 3.0;
uniform float rim_strength = 0.35;

void vertex() {
	// fase pela posição no mundo: cada planta balança um pouco fora de sincronia
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	float s = sin(phase) + 0.4 * sin(phase * 2.3 + 1.7);
	float w = smoothstep(sway_start, sway_start + sway_height, VERTEX.y);
	VERTEX.xz += normalize(wind_dir) * s * sway_strength * w;
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
}
