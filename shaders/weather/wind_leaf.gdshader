shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
// Folha/lâmina de grama voando com o vento, com o MESMO visual da grama fina
// (wind_sway com `stylized`): cor no degradê base → ponta da grama (a imagem
// só dá a forma e o claro/escuro), borda clara (rim) e a mesma luz (inclui o
// a mesma luz suave da grama). Ondula no ar sem girar no próprio eixo; transparência
// pelo COLOR.a da partícula (fade). Usado por scripts/weather/wind_leaves.gd.


uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
// mesmas cores da grama estilizada (GrassField: base_color / tip_color)
uniform vec3 grass_base_color : source_color = vec3(0.35, 0.62, 0.22);
uniform vec3 grass_tip_color : source_color = vec3(0.86, 0.98, 0.5);
uniform float grass_style = 1.0;   // 1 = cores da grama, 0 = cores da imagem
uniform vec4 rim_color : source_color = vec4(0.62, 0.7, 1.0, 1.0);
uniform float rim_power = 3.0;
uniform float rim_strength = 0.35;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.5;
uniform float flutter = 0.08;      // quanto a folha ondula no ar (suave, não molenga)
uniform float curl = 0.12;         // quanto as bordas dobram (leve, não uma placa)
uniform float shade_dark = 0.55;   // quanto o lado cinza do sprite escurece (efeito Shaded do Kenney)
uniform vec2 plane_size = vec2(0.25, 0.25);  // tamanho do plano (setado pelo wind_leaves.gd)

void vertex() {
	float t = TIME * 3.0 + float(INSTANCE_ID) * 1.7;
	// no ar ondula; pousada no chão (origem perto de y = 0) fica parada e reta
	float air = smoothstep(0.05, 0.4, MODEL_MATRIX[3].y);
	// posição no plano normalizada (-0,5..0,5) e tamanho da folha: a dobra e a
	// onda são proporcionais ao tamanho (antes eram em metros e, numa folha de
	// 25 cm, quase não apareciam; na lâmina fina, nada)
	vec2 q = VERTEX.xz / plane_size;
	float sz = max(plane_size.x, plane_size.y);
	// dobra: as bordas caem, como folha mole (respira devagar)
	VERTEX.y -= curl * dot(q, q) * sz * (0.8 + 0.4 * sin(t * 0.6)) * air;
	// onda que corre pela folha (ondulando no ar)
	VERTEX.y += sin(t + q.y * 7.0) * flutter * sz * (q.x * 2.0 + q.y) * air;
	VERTEX.y += sin(t * 0.7 + q.x * 6.0) * flutter * sz * 0.4 * (0.3 + abs(q.y)) * air;
	// nunca abaixo do chão (y = 0,01 no mundo)
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (wp.y < 0.01) {
		VERTEX += inverse(mat3(MODEL_MATRIX)) * vec3(0.0, 0.01 - wp.y, 0.0);
	}
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	// claro/escuro da imagem vira o degradê da grama: lado escuro = base, claro = ponta
	float lum = clamp((dot(tex.rgb, vec3(0.299, 0.587, 0.114)) - 0.35) / 0.5, 0.0, 1.0);
	vec3 grass = mix(grass_base_color, grass_tip_color, lum);
	float shade = mix(shade_dark, 1.0, dot(tex.rgb, vec3(0.333)));  // cinza do sprite = lado escuro (Shaded)
	ALBEDO = mix(shade * tint.rgb, grass * tint.rgb, grass_style) * COLOR.rgb;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	float fresnel = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
	ALPHA = tex.a * tint.a * COLOR.a;
}

// mesma luz suave da grama (lado na sombra no máximo ~22% mais escuro)
void light() {
	float lit = clamp((dot(NORMAL, LIGHT) + 0.6) / 1.6, 0.0, 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * mix(0.78, 1.0, lit) / PI;
}
