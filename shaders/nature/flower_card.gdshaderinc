// Corpo do shader das flores (flower_card = cabeças, flower_stem = caules com #define STEM).
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform bool flat_card = false;       // carta deitada das flores: anda inteira (no topo dos caules)
uniform float stem_dark = 0.45;        // cor no pé do caule (× cor)
uniform float stem_alpha_base = 0.0;   // opacidade no pé do caule
// borda das flores (só a carta das flores): pixel vazio colado num pixel de
// pétala vira contorno NA COR DA PRÓPRIA FLOR (a pétala vizinha), num tom
// `outline_shade` (1 = mesma cor; menor = mais escuro)
uniform float outline_shade : hint_range(0.0, 1.0) = 0.8;
uniform float outline_px = 3.0;        // espessura em pixels da textura (0 = sem borda)

// Movimento IGUAL ao da grama (grass_body.gdshaderinc): balanço em oval, dobra
// com a rajada (rigidez própria por flor, limitada) e o jogador abre/achata.
// Tudo pela origem de CADA flor: cada uma balança separada. Pela altura (y), a
// carta das flores e o caule (mesmo transform) andam juntos.
uniform float sway_strength = 0.06;
uniform float sway_speed = 1.6;
uniform float sway_height = 0.6;
uniform vec2 wind_dir = vec2(1.0, -0.02);
uniform float orbit = 0.35;
uniform float bend_max = 1.1;
uniform float bend_limit = 0.6;
uniform float push_strength = 0.08;
uniform float push_radius = 0.9;
uniform float push_squash = 0.5;

global uniform vec2 wind_direction;
global uniform float wind_strength;
global uniform float wind_gust;
global uniform vec3 player_pos;

// Onda de luz dourada (mesma conta e mesmos valores do `grass_tuft.tres`, pelo
// mundo e pelo TIME: passa pela grama e pelas flores juntas). 0 = desligado
// (a flor branca do chão fica sem).
uniform float shimmer_strength = 0.0;
uniform vec3 shimmer_color : source_color = vec3(1.0, 0.93, 0.66);
uniform float shimmer_speed = 18.0;
uniform float shimmer_spacing = 160.0;
uniform float shimmer_width = 22.0;
varying vec3 v_world;

float fhash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float fnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(fhash(i), fhash(i + vec2(1.0, 0.0)), f.x),
			mix(fhash(i + vec2(0.0, 1.0)), fhash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * sway_speed + dot(origin.xz, vec2(0.35, 0.21));
	float vph = dot(origin.xz, vec2(1.7, 2.3));
	float w = smoothstep(0.0, sway_height, VERTEX.y);
	vec2 wd = normalize(wind_dir);
	float s = 0.35 + 0.5 * sin(phase) + 0.25 * sin(phase * 0.37 + 1.3);
	float side = orbit * cos(phase);
	VERTEX.xz += (wd * s + vec2(-wd.y, wd.x) * side) * sway_strength * w * wind_strength;
	if (length(wind_direction) > 0.5) {
		float h1 = fhash(origin.xz);
		float stiff = mix(0.3, 1.15, h1 * h1);
		float wobble = 0.75 + 0.25 * sin(TIME * (0.7 + h1) + vph);
		float a = min(wind_gust * bend_max * stiff * wobble, bend_limit) * w;
		float rel = max(VERTEX.y, 0.0);
		vec3 l = inverse(mat3(MODEL_MATRIX)) * vec3(wind_direction.x, 0.0, wind_direction.y);
		vec2 bd = length(l.xz) > 0.0001 ? normalize(l.xz) : normalize(wind_direction);
		VERTEX.xz += bd * sin(a) * rel;
		VERTEX.y += (cos(a) - 1.0) * rel;
	}
	vec2 away = origin.xz - player_pos.xz;
	float dist = length(away);
	float p = (1.0 - smoothstep(push_radius * 0.3, push_radius, dist)) * step(0.001, push_strength);
	if (p > 0.0) {
		vec2 dir = dist > 0.001 ? away / dist : vec2(1.0, 0.0);
		vec3 push = vec3(0.0);
		push.xz = dir * push_strength * p * w;
		push.y = -push_squash * p * w * max(VERTEX.y, 0.0);
		VERTEX += inverse(mat3(MODEL_MATRIX)) * push;
	}
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	ALBEDO = c.rgb;
	// luz sempre "de cima" nos dois lados da carta (o verso virava a normal
	// pra baixo e a flor ficava preta à noite)
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
#ifdef STEM
	// efeito chiclete: o caule escurece e some aos poucos indo pro pé
	float up = 1.0 - UV.y;
	ALBEDO *= mix(stem_dark, 1.0, smoothstep(0.0, 0.8, up));
	ALPHA = c.a * mix(stem_alpha_base, 1.0, smoothstep(0.0, 0.9, up));
#else
	float a_out = c.a;
	if (outline_px > 0.0 && c.a < alpha_cut) {
		vec2 px = outline_px / vec2(textureSize(albedo_tex, 0));
		float near = 0.0;
		vec3 near_col = vec3(0.0);
		for (int i = 0; i < 8; i++) {
			float ang = float(i) * 0.785398;
			vec4 t = texture(albedo_tex, UV + vec2(cos(ang), sin(ang)) * px);
			if (t.a > near) {
				near = t.a;
				near_col = t.rgb;
			}
		}
		if (near >= alpha_cut) {
			ALBEDO = near_col * outline_shade;
			a_out = 1.0;
		}
	}
	ALPHA = a_out;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
#endif
	if (shimmer_strength > 0.0) {
		vec2 sd = length(wind_direction) > 0.5 ? normalize(wind_direction) : normalize(vec2(1.0, 0.3));
		float bend = (fnoise(v_world.xz * 0.03) - 0.5) * 28.0 + (fnoise(v_world.xz * 0.12 + 7.0) - 0.5) * 6.0;
		float d = dot(v_world.xz, sd) + bend - TIME * shimmer_speed;
		float pos = mod(d, shimmer_spacing);
		float band = smoothstep(0.0, shimmer_width * 0.5, pos) * (1.0 - smoothstep(shimmer_width * 0.5, shimmer_width, pos));
		float wave_id = floor(d / shimmer_spacing);
		vec2 shift = vec2(fhash(vec2(wave_id, 1.3)), fhash(vec2(wave_id, 7.9))) * 500.0;
		float blot = smoothstep(0.55, 0.8, fnoise(v_world.xz * 0.11 + shift) * 0.7 + fnoise(v_world.xz * 0.27 + shift + 3.0) * 0.3);
		EMISSION += shimmer_color * band * blot * shimmer_strength;
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
