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

// Toque do jogador: a planta achata (e inclina só um pouco pra longe dele).
// `player_pos` é global (project.godot), atualizado pelo player.gd. push_strength 0 = não reage (árvores).
global uniform vec3 player_pos;
uniform float push_strength = 0.0;  // quanto se inclina pra longe (metros)
uniform float push_radius = 0.9;    // alcance do toque (metros)
uniform float push_squash = 0.5;    // fração da altura que achata

// rim light "vinil" (mesmo efeito do rim_overlay, embutido aqui porque o
// overlay não acompanharia o balanço do vento)
uniform vec4 rim_color : source_color = vec4(0.62, 0.7, 1.0, 1.0);
uniform float rim_power = 3.0;
uniform float rim_strength = 0.35;

// Bioluminescência (flores): pétalas brilham na própria cor, pulsando devagar.
// O caule/folha (pixels onde o verde domina) não brilha. 0 = desligado.
uniform float bio_glow = 0.0;
uniform float bio_pulse_speed = 0.8;
varying float v_phase;

void vertex() {
	// fase pela posição no mundo: cada planta balança um pouco fora de sincronia
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	v_phase = dot(world_origin.xz, vec2(1.7, 2.3));
	float s = sin(phase) + 0.4 * sin(phase * 2.3 + 1.7);
	float w = smoothstep(sway_start, sway_start + sway_height, VERTEX.y);
	VERTEX.xz += normalize(wind_dir) * s * sway_strength * w;

	// toque: calculado pela origem da planta, então ela toda se abre junta
	vec2 away = world_origin.xz - player_pos.xz;
	float dist = length(away);
	float p = (1.0 - smoothstep(push_radius * 0.3, push_radius, dist)) * step(0.001, push_strength);
	if (p > 0.0) {
		vec2 dir = dist > 0.001 ? away / dist : vec2(1.0, 0.0);
		vec3 push = vec3(0.0);
		push.xz = dir * push_strength * p * w;
		push.y = -push_squash * p * w * max(VERTEX.y, 0.0);
		VERTEX += inverse(mat3(MODEL_MATRIX)) * push;  // mundo -> local
	}
}

void fragment() {
	vec3 albedo = texture(albedo_tex, UV).rgb;
	ALBEDO = albedo;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
	if (bio_glow > 0.0) {
		float petal = 1.0 - smoothstep(0.0, 0.08, albedo.g - max(albedo.r, albedo.b));
		float pulse = 0.65 + 0.35 * sin(TIME * bio_pulse_speed + v_phase);
		EMISSION += albedo * bio_glow * petal * pulse;
	}
}
