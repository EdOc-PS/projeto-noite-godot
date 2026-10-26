shader_type spatial;
render_mode cull_disabled;
// Shader da grama do JOGO ANTIGO (projeto-noite-old: wind_sway_body.gdshaderinc,
// usado pelo GrassField com `stylized`), trazido pro tufo 2D. Degradê base ->
// ponta pela altura vezes manchas de ruído no mundo, borda azulada (rim),
// translucidez contra o sol na ponta e luz do toon_light. Vento, dobra e toque
// do jogador iguais aos do jogo antigo.
#include "res://shaders/includes/toon_light.gdshaderinc"
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
// quanto o balanço faz um oval (0 = só vai e vem)
uniform float orbit = 0.35;

// Toque do jogador: a planta achata (e inclina só um pouco pra longe dele).
// `player_pos` é global (project.godot), atualizado pelo player.gd. push_strength 0 = não reage (árvores).
global uniform vec3 player_pos;
// Vento global (scripts/weather/wind.gd, "Vento (sistema)" em 06-clima.md):
//  - wind_direction: direção fixa no mundo; (0,0) = cena sem Wind (usa wind_dir
//    do material, como antes);
//  - wind_strength: multiplica o balanço normal;
//  - wind_gust / wind_gust_slow: quanto a planta DOBRA na direção do vento
//    (grama / árvores). A lâmina gira em volta da base mantendo
//    o comprimento (não amassa).
global uniform vec2 wind_direction;
global uniform float wind_strength;
global uniform float wind_gust;
global uniform float wind_gust_slow;
uniform float bend_max = 1.1;       // ângulo máximo da dobra (rad) na grama
uniform float tree_bend_max = 0.12; // nas árvores (sway_start > 0,5)
uniform float bend_scale = 1.0;      // por tipo (arbusto dobra pouco: wind_applier.bush_bend)
// Translucidez contra o sol (estilo BotW): com o sol atrás da planta, a ponta
// acende amarela. Global, 0 = desligado (só o campo liga; plano 16-estilo-botw.md).
uniform float veg_backlight = 0.4;  // no jogo antigo vinha do BotwPost (global); aqui fixo
// Multiplica a borda clara (rim) da vegetação. 1 = normal; o campo baixa
// (à noite a borda azul fazia as árvores brilharem ao balançar).
uniform float veg_rim_scale = 0.5;  // idem (rim_day do BotwPost)
global uniform vec3 veg_backlight_color;
uniform float push_strength = 0.0;  // quanto se inclina pra longe (metros)
uniform float push_radius = 0.9;    // alcance do toque (metros)
uniform float push_squash = 0.5;    // fração da altura que achata
// Balanço ao tocar (arbusto): sacode quando o jogador ENTRA ou SAI (borda do
// alcance), sem deformar; parado dentro, fica no tamanho original. 0 = desligado.
uniform float touch_shake = 0.0;
uniform float touch_radius = 0.9;

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

// Grama estilizada (baseado em "Stylized Grass" de StayAtHomeDev, MIT, ver
// stylized_grass_LICENSE.txt): troca a textura por um degradê base → ponta e
// manchas de ruído no mundo. Ligado só na grama densa (GrassField). 0 = textura.
uniform bool stylized = true;
// oclusão na base da grama: o pé do tufo fica escuro e clareia até a ponta
// (sombra "de contato" entre as lâminas). 0 = sem.
uniform float base_ao : hint_range(0.0, 1.0) = 0.0;
uniform vec3 grass_base_color : source_color = vec3(0.35, 0.62, 0.22);
uniform vec3 grass_tip_color : source_color = vec3(0.86, 0.98, 0.5);
uniform sampler2D grass_noise : repeat_enable, filter_linear;
uniform float grass_noise_scale = 20.0;  // metros por repetição das manchas
uniform float grass_height = 0.35;       // altura local onde fica a cor da ponta
varying float v_height;
varying vec3 v_world;

void vertex() {
	// fase pela posição no mundo: cada planta balança um pouco fora de sincronia
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	v_phase = dot(world_origin.xz, vec2(1.7, 2.3));
	v_height = VERTEX.y;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// balanço suave: inclina com o vento e faz um oval (nunca para de vez nas
	// pontas, sem aquele "acelera e freia"), com uma rajada lenta por cima
	bool global_wind = length(wind_direction) > 0.5;
	// balanço: igual ao do outside (direção do material no espaço da planta,
	// então cada tufo balança pra um lado: é o que deixa a grama viva parada)
	vec2 wd = normalize(wind_dir);
	float s = 0.35 + 0.5 * sin(phase) + 0.25 * sin(phase * 0.37 + 1.3);
	float side = orbit * cos(phase);
	float w = smoothstep(sway_start, sway_start + sway_height, VERTEX.y);
	VERTEX.xz += (wd * s + vec2(-wd.y, wd.x) * side) * sway_strength * w * wind_strength;
	if (global_wind) {
		// dobra: gira em volta da base, a ponta faz arco (comprimento igual)
		bool is_tree = sway_start > 0.5;
		float amount = (is_tree ? wind_gust_slow * tree_bend_max : wind_gust * bend_max) * bend_scale;
		// cada planta tem sua "rigidez" (umas deitam muito, outras pouco) e
		// um ruído lento próprio, pra não deitarem todas na mesma altura
		float h1 = fract(sin(dot(world_origin.xz, vec2(12.9898, 78.233))) * 43758.5453);
		float stiff = mix(0.3, 1.15, h1 * h1);
		float wobble = 0.75 + 0.25 * sin(TIME * (0.7 + h1) + v_phase);
		float a = amount * stiff * wobble * w;
		float rel = max(VERTEX.y - sway_start, 0.0);
		// dobra na direção fixa do vento: mundo -> espaço local da planta
		vec3 l = inverse(mat3(MODEL_MATRIX)) * vec3(wind_direction.x, 0.0, wind_direction.y);
		vec2 bd = length(l.xz) > 0.0001 ? normalize(l.xz) : normalize(wind_direction);
		VERTEX.xz += bd * sin(a) * rel;
		VERTEX.y += (cos(a) - 1.0) * rel;
	}

	if (touch_shake > 0.0) {
		float dd = length(world_origin.xz - player_pos.xz);
		float edge = smoothstep(touch_radius * 0.45, touch_radius * 0.8, dd) * (1.0 - smoothstep(touch_radius * 0.9, touch_radius * 1.3, dd));
		vec3 shake = vec3(sin(TIME * 17.0 + v_phase), 0.0, cos(TIME * 13.0 + v_phase)) * touch_shake * edge * w;
		VERTEX += inverse(mat3(MODEL_MATRIX)) * shake;
	}
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
	if (stylized) {
		float h = clamp(v_height / grass_height, 0.0, 1.0);
		float n = texture(grass_noise, v_world.xz / grass_noise_scale).r;
		albedo = mix(grass_base_color, grass_tip_color, h) * mix(grass_base_color, grass_tip_color, n);
	}
	if (base_ao > 0.0) {
		float h_ao = clamp(v_height / grass_height, 0.0, 1.0);
		albedo *= mix(1.0 - base_ao, 1.0, smoothstep(0.0, 0.7, h_ao));
	}
	ALBEDO = albedo;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength * veg_rim_scale;
	if (bio_glow > 0.0) {
		float petal = 1.0 - smoothstep(0.0, 0.08, albedo.g - max(albedo.r, albedo.b));
		float pulse = 0.65 + 0.35 * sin(TIME * bio_pulse_speed + v_phase);
		EMISSION += albedo * bio_glow * petal * pulse;
	}
}

// Luz: comum (Lambert) ou toon, pelo global `toon_enabled` (ver toon_light.gdshaderinc).
void light() {
	bool is_main = LIGHT_IS_DIRECTIONAL;
	DIFFUSE_LIGHT += toon_diffuse(NORMAL, LIGHT, ATTENUATION, LIGHT_COLOR, is_main);
	if (is_main && veg_backlight > 0.0) {
		float back = smoothstep(-0.3, 1.0, dot(VIEW, -LIGHT));  // câmera de cima: vale também de lado
		float tip = stylized ? smoothstep(0.2, 1.0, v_height / grass_height) : 0.6;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * veg_backlight_color * back * tip * veg_backlight * ATTENUATION;
	}
	// sem a borda clara do toon aqui: a grama é fina e vista de lado, então a
	// borda pegava quase o tufo todo e a grama ficava branca
}
