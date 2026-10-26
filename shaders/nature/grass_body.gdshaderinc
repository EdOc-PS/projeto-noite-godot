// Corpo dos shaders de grama (grass_tuft e grass_sprig). Ver grass_tuft.gdshader.
// Tufos de grama (assets/models/grass/, pincel do Terrain3D).
//
// Cor: baseada no "Stylized Grass" de StayAtHomeDev (MIT, licença em
// .docs/licencas/stylized_grass_LICENSE.txt): degradê base → ponta pela altura
// (UV.y: 1 na base, 0 na ponta), então cada tufo tem a base mais escura e o
// topo claro. As manchas de ruído do original ficaram bem leves (`noise_amount`):
// fortes, escureciam áreas inteiras do campo.
// Shaded: cada lâmina tem um tom (COLOR.r do mesh, 0.86..1): a mesma cor, umas
// folhas só levemente mais escuras.
// Luz: o lado de trás da lâmina vira a normal (como no original) e a luz é
// suave, sem lado preto: a parte na sombra fica só um pouco mais escura.
// Movimento: o mesmo do projeto antigo (wind_sway_body.gdshaderinc): balanço em
// oval com fase pela posição, dobra na rajada (rigidez e ruído por tufo) e o
// tufo abre quando o jogador passa (player_pos).

uniform vec3 base_color : source_color = vec3(0.53, 0.64, 0.12);
uniform vec3 tip_color : source_color = vec3(0.64, 0.76, 0.2);
// degradê em 3 tons (verde claro -> verde-amarelo -> amarelo aquarela) com a
// divisa "borrada" por ruído, como tinta aquarela escorrendo
uniform vec3 mid_color : source_color = vec3(0.72, 0.82, 0.25);
uniform float mid_pos : hint_range(0.05, 0.95) = 0.5;  // altura do verde-amarelo
uniform float paint_wobble : hint_range(0.0, 0.5) = 0.18;  // quanto a divisa entre os tons ondula
uniform float paint_scale = 0.35;  // metros por mancha da aquarela
uniform float noise_scale = 20.0;      // metros por mancha (noiseScale do original)
uniform float noise_amount : hint_range(0.0, 1.0) = 0.3;
uniform float shade_amount : hint_range(0.0, 1.0) = 1.0;
// Contorno: a silhueta de cada lâmina opaca e o miolo numa cor só, meio
// transparente (dá pra ver a grama de trás). UV2.x = 0 na borda.
uniform bool outline_only = false;
uniform float outline_width = 1.5;  // espessura da borda em pixels
// Sprite (raminho do Kenney Foliage em cartas): recorta pela transparência do
// PNG e o cinza do sprite sombreia a cor.
uniform bool use_sprite = false;
uniform sampler2D sprite : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform bool alpha_by_height = false;
// Transparência FALSA (material opaco): mistura a cor com a do chão pela
// opacidade sorteada por planta (`sprite_alpha`). Transparência de verdade
// piscava claro/escuro andando (o Terrain3D ordena os blocos de grama
// transparentes por distância e a ordem troca com a câmera).
uniform bool fake_alpha = false;
uniform vec3 ground_color : source_color = vec3(0.569, 0.745, 0.004);
uniform vec2 sprite_alpha = vec2(1.0, 1.0);  // opacidade do sprite, sorteada por raminho entre x e y
// Carta virada sempre pra câmera, girando só no eixo Y (raminho).
uniform bool billboard = false;
uniform float light_floor : hint_range(0.0, 1.0) = 0.78;  // brilho do lado na sombra

// Brilho (tudo multiplicado pela cor da lâmina, então o shaded continua: a
// lâmina escura brilha menos que a clara).
uniform float tip_glow : hint_range(0.0, 1.0) = 0.0;       // ponta acesa (degradê de luz pro topo)
uniform float glow_start : hint_range(0.0, 1.0) = 0.55;    // altura onde o brilho começa
uniform float rim_glow : hint_range(0.0, 1.0) = 0.0;       // borda clara contra o céu (fresnel)
uniform float backlight : hint_range(0.0, 2.0) = 0.0;      // translucidez com o sol atrás
// Borda (passe de contorno, grass_outline.gdshader): casca invertida em volta
// da lâmina, num verde escuro do mesmo tom.
uniform float edge_amount : hint_range(0.0, 1.0) = 0.0;  // borda suave: quanto escurece de perfil
uniform float edge_softness : hint_range(0.5, 4.0) = 1.6;  // maior = borda mais fina
uniform float outline_size = 0.006;  // espessura da borda (m)
uniform vec3 outline_color : source_color = vec3(0.16, 0.3, 0.02);
// lâmina CHATA com normal de "cúpula" (tufo iso): a casca da borda usa a normal
// de verdade da face, guardada em COLOR.gba (0..1), e não a normal da luz
uniform bool outline_face_normal = false;
// topo da BORDA arredondado: perto da ponta a casca engorda pros lados, então
// a borda fecha em cúpula em volta da ponta fina da lâmina (0 = segue a ponta)
uniform float outline_round = 0.0;
uniform vec3 backlight_color : source_color = vec3(1.0, 0.95, 0.6);

uniform float sway_strength = 0.06;
uniform float sway_speed = 2.3;
uniform float sway_start = 0.0;
uniform float sway_height = 0.35;
uniform vec2 wind_dir = vec2(1.0, 0.3);
uniform float orbit = 0.35;
uniform float bend_max = 1.1;
uniform float bend_limit = 0.6;  // dobra máxima do vento (rad, ~35°): a grama nunca deita de vez
uniform float push_strength = 0.25;  // quanto se inclina pra longe do jogador (m)
uniform float push_radius = 0.8;
uniform float push_squash = 0.75;   // quanto achata (fração da altura)

global uniform vec3 player_pos;
// Onda de luz (shimmer): uma faixa clara/dourada que atravessa o campo na
// direção do vento, espera e passa de novo. Acende mais as pontas.
uniform float shimmer_strength : hint_range(0.0, 2.0) = 0.0;  // 0 = desligado
uniform vec3 shimmer_color : source_color = vec3(1.0, 0.86, 0.42);
uniform float shimmer_speed = 3.0;     // m/s da faixa
uniform float shimmer_spacing = 60.0;  // m entre uma faixa e a próxima (espera = spacing / speed)
uniform float shimmer_width = 14.0;    // largura da faixa (m)
global uniform vec2 wind_direction;
global uniform float wind_strength;
global uniform float wind_gust;

varying vec3 v_world;
varying float v_rand;  // número fixo por planta (0..1)
varying float v_phase;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	v_rand = hash(world_origin.xz + vec2(3.1, 7.7));
	if (billboard) {
		// cada carta vira pra câmera em volta do PRÓPRIO centro (UV2 = x, z do
		// pé da carta no espaço do tufo): um tufo pode ter várias cartas em
		// lugares diferentes, o que enche o tufo visto de cima
		vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
		float sx = length(MODEL_MATRIX[0].xyz);
		float sy = length(MODEL_MATRIX[1].xyz);
		vec3 c = vec3(UV2.x, 0.0, UV2.y);
		vec3 rel = VERTEX - c;
		vec3 world_off = right * rel.x * sx + vec3(0.0, rel.y * sy, 0.0);
		VERTEX = c + inverse(mat3(MODEL_MATRIX)) * world_off;
	}
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = TIME * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	v_phase = dot(world_origin.xz, vec2(1.7, 2.3));
	float w = smoothstep(sway_start, sway_start + sway_height, VERTEX.y);
	// balanço: oval na direção do material (no espaço do tufo: cada um pra um lado)
	vec2 wd = normalize(wind_dir);
	float s = 0.35 + 0.5 * sin(phase) + 0.25 * sin(phase * 0.37 + 1.3);
	float side = orbit * cos(phase);
	VERTEX.xz += (wd * s + vec2(-wd.y, wd.x) * side) * sway_strength * w * wind_strength;
	if (length(wind_direction) > 0.5) {
		// dobra: gira em volta da base, a ponta faz arco (comprimento igual)
		float h1 = hash(world_origin.xz);
		float stiff = mix(0.3, 1.15, h1 * h1);
		float wobble = 0.75 + 0.25 * sin(TIME * (0.7 + h1) + v_phase);
		float a = min(wind_gust * bend_max * stiff * wobble, bend_limit) * w;
		float rel = max(VERTEX.y - sway_start, 0.0);
		vec3 l = inverse(mat3(MODEL_MATRIX)) * vec3(wind_direction.x, 0.0, wind_direction.y);
		vec2 bd = length(l.xz) > 0.0001 ? normalize(l.xz) : normalize(wind_direction);
		VERTEX.xz += bd * sin(a) * rel;
		VERTEX.y += (cos(a) - 1.0) * rel;
	}
	// toque: o tufo todo se abre junto (pela origem)
	vec2 away = world_origin.xz - player_pos.xz;
	float dist = length(away);
	float p = (1.0 - smoothstep(push_radius * 0.3, push_radius, dist)) * step(0.001, push_strength);
	if (p > 0.0) {
		vec2 dir = dist > 0.001 ? away / dist : vec2(1.0, 0.0);
		vec3 push = vec3(0.0);
		push.xz = dir * push_strength * p * w;
		push.y = -push_squash * p * w * max(VERTEX.y, 0.0);
		VERTEX += inverse(mat3(MODEL_MATRIX)) * push;
	}
#ifdef OUTLINE_PASS
	// casca um pouco maior que a lâmina (largura em metros, igual em qualquer escala)
	vec3 on = outline_face_normal ? COLOR.gba * 2.0 - 1.0 : NORMAL;
	vec3 wn = normalize(mat3(MODEL_MATRIX) * on);
	float tipz = smoothstep(0.6, 1.0, 1.0 - UV.y);
	vec3 off = wn * outline_size;
	off.xz *= 1.0 + tipz * outline_round;
	off.y += tipz * outline_round * outline_size * 0.6;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * off;
#endif
}

void fragment() {
	float n = noise(v_world.xz / noise_scale);
	// cada tufo: base mais escura → topo claro. As manchas de ruído pelo mundo
	// só mexem de leve (`noise_amount`), pra não escurecer áreas inteiras.
	float t = clamp(1.0 - UV.y + (noise(v_world.xz / paint_scale + vec2(UV.y * 3.0, 0.0)) - 0.5) * paint_wobble * 2.0, 0.0, 1.0);
	vec3 col = t < mid_pos ? mix(base_color, mid_color, smoothstep(0.0, mid_pos, t))
		: mix(mid_color, tip_color, smoothstep(mid_pos, 1.0, t));
	col *= mix(1.0, mix(0.9, 1.05, n), noise_amount);
	col *= mix(1.0, COLOR.r, shade_amount);
	if (use_sprite) {
		vec4 t = texture(sprite, UV);
		if (t.a < alpha_cut) {
			discard;
		}
		col *= mix(0.75, 1.0, t.r);
	}
	// borda suave: onde a lâmina vira de perfil, a cor escurece aos poucos
	float side_on = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), edge_softness);
	col = mix(col, col * 0.62, side_on * edge_amount);
	ALBEDO = col;
	// brilho: degradê de luz subindo pra ponta + borda clara contra o céu
	float height01 = 1.0 - UV.y;
	float tip = smoothstep(glow_start, 1.0, height01);
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = col * (tip * tip_glow + fres * rim_glow * height01);
	if (shimmer_strength > 0.0) {
		vec2 sd = length(wind_direction) > 0.5 ? normalize(wind_direction) : normalize(vec2(1.0, 0.3));
		// frente da onda torta (ruído largo), pra não ser uma linha reta
		// frente bem torta: curva larga (ruído grande) + ondinhas, nunca uma linha reta
		float bend = (noise(v_world.xz * 0.03) - 0.5) * 28.0 + (noise(v_world.xz * 0.12 + 7.0) - 0.5) * 6.0;
		float d = dot(v_world.xz, sd) + bend - TIME * shimmer_speed;
		float pos = mod(d, shimmer_spacing);
		float band = smoothstep(0.0, shimmer_width * 0.5, pos) * (1.0 - smoothstep(shimmer_width * 0.5, shimmer_width, pos));
		// a luz acende MANCHAS largas e irregulares (não uma faixa inteira), como
		// sol entre nuvens passando por cima do mato
		// MANCHAS em lugares aleatórios: cada passada (wave_id) sorteia outro
		// desenho de manchas, então nunca acende sempre no mesmo lugar
		float wave_id = floor(d / shimmer_spacing);
		vec2 shift = vec2(hash(vec2(wave_id, 1.3)), hash(vec2(wave_id, 7.9))) * 500.0;
		float blot = smoothstep(0.55, 0.8, noise(v_world.xz * 0.11 + shift) * 0.7 + noise(v_world.xz * 0.27 + shift + 3.0) * 0.3);
		EMISSION += shimmer_color * band * blot * shimmer_strength * (0.3 + 0.7 * height01);
	}
#ifdef SPRITE_ALPHA
	// alpha_by_height: degradê pela altura (pé = sprite_alpha.y, topo = .x);
	// senão, sorteado por planta entre .x e .y
	ALPHA = alpha_by_height ? mix(sprite_alpha.y, sprite_alpha.x, 1.0 - UV.y) : mix(sprite_alpha.x, sprite_alpha.y, v_rand);
#endif
	if (outline_only) {
		float e = UV2.x;
		if (e > fwidth(e) * outline_width) {
			discard;  // miolo vazado (a versão com miolo semitransparente deixava toda a grama transparente)
		}
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
#ifdef OUTLINE_PASS
	ALBEDO = outline_color;
	EMISSION = vec3(0.0);
#endif
	// depois da borda: o tufo e a borda dele somem juntos no chão
	if (fake_alpha) {
		float fa = mix(sprite_alpha.x, sprite_alpha.y, v_rand);
		ALBEDO = mix(ground_color, ALBEDO, fa);
		EMISSION *= fa;
	}
}

void light() {
	float lit = clamp((dot(NORMAL, LIGHT) + 0.6) / 1.6, 0.0, 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * mix(light_floor, 1.0, lit) / PI;
	if (backlight > 0.0 && LIGHT_IS_DIRECTIONAL) {
		// sol atrás da grama (olhando pra ele): a ponta acende, como folha contra a luz
		float back = smoothstep(-0.2, 1.0, dot(VIEW, -LIGHT));
		DIFFUSE_LIGHT += LIGHT_COLOR * backlight_color * back * backlight * (1.0 - UV.y) * ATTENUATION / PI;
	}
}
