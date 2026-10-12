// Balanço de vento compartilhado (mesma fórmula do wind_sway.gdshader).
// Balança os vértices mais altos (a base fica parada), com fase pela posição
// da planta no mundo pra cada uma ficar fora de sincronia.

uniform float sway_strength = 0.05;
uniform float sway_speed = 1.5;
uniform float sway_start = 0.0;
uniform float sway_height = 0.4;
uniform vec2 wind_dir = vec2(1.0, 0.3);

vec3 wind_offset(vec3 vertex, vec3 world_origin, float time) {
	float phase = time * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	float s = sin(phase) + 0.4 * sin(phase * 2.3 + 1.7);
	float w = smoothstep(sway_start, sway_start + sway_height, vertex.y);
	vec2 d = normalize(wind_dir) * s * sway_strength * w;
	return vec3(d.x, 0.0, d.y);
}
