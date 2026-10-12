shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
// Poeira que se desfaz (estilo Death's Door): no fim da vida a partícula se
// deforma e "esfarela" em manchas de ruído antes de sumir.
// Só funciona em partículas: INSTANCE_CUSTOM.y = fração da vida (0..1),
// preenchido pelo ParticleProcessMaterial.

uniform vec4 color : source_color = vec4(0.78, 0.8, 0.9, 0.4);
uniform float dissolve_start = 0.35;  // fração da vida em que começa a esfarelar
uniform float noise_scale = 6.0;      // tamanho das manchas (maior = mais miúdo)
uniform float wobble = 0.12;          // quanto deforma no fim

varying float v_age;
varying vec3 v_local;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
	               mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
	           mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
	               mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	v_age = INSTANCE_CUSTOM.y;
	v_local = VERTEX;
	// deforma: empurra os vértices pra fora/dentro com ruído, mais forte no fim
	float d = smoothstep(dissolve_start, 1.0, v_age);
	float n = noise(VERTEX * 4.0 + vec3(INSTANCE_CUSTOM.x * 3.0)) - 0.5;
	VERTEX += NORMAL * n * wobble * d * 2.0;
}

void fragment() {
	float d = smoothstep(dissolve_start, 1.0, v_age);
	float n = noise(v_local * noise_scale + vec3(v_age * 1.5));
	// conforme envelhece, mais manchas são cortadas (esfarela)
	float keep = smoothstep(d - 0.08, d + 0.08, n);
	ALBEDO = color.rgb;
	ALPHA = color.a * keep * (1.0 - d * 0.5);
}
