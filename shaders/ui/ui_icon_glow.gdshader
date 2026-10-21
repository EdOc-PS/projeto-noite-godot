shader_type spatial;
// Ícone de UI no mundo (interaction prompt etc.): billboard, sem luz, desenhado
// por cima de tudo. A cor é multiplicada por `glow` (> 1 = acima do branco
// puro), então o tonemap mantém branco de verdade e o glow da cena faz brilhar.
// Preenchimento "de baixo pra cima": `tex_fill` (versão preenchida do ícone)
// sobe por dentro de `tex` (outline) conforme `fill` vai de 0 a 1, com a borda
// ondulando de leve, como líquido.
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled, blend_mix;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler2D tex_fill : source_color, filter_linear_mipmap;
uniform float glow = 2.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform float icon_top = 0.125;     // UV onde o desenho do ícone começa (64px com 8px de margem)
uniform float icon_bottom = 0.875;  // UV onde o desenho termina
uniform float wave_height = 0.025;  // altura da ondinha na superfície
uniform float wave_freq = 14.0;
uniform float wave_speed = 7.0;

void vertex() {
	// billboard mantendo a escala do nó
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 outline = texture(tex, UV);
	vec4 filled = texture(tex_fill, UV);

	// nível do "líquido": UV.y cresce pra baixo, então o fundo é icon_bottom
	float level = mix(icon_bottom, icon_top, fill);
	// onda só enquanto está enchendo (some com 0 e com 1)
	float wave_amount = wave_height * sin(fill * PI);
	level += sin(UV.x * wave_freq + TIME * wave_speed) * wave_amount;
	float m = (fill <= 0.0) ? 0.0 : smoothstep(level - 0.01, level + 0.01, UV.y);

	vec4 c = mix(outline, filled, m);
	ALBEDO = c.rgb * glow;
	ALPHA = c.a * alpha;
}
