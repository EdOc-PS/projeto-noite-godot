shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;
// Água escorrendo: passe extra (next_pass) por cima dos materiais molhados
// (WetnessApplier). Faixas finas descendo nas faces verticais, em coordenadas
// do mundo. Força pelo global `weather_wetness`. Regras em .docs/plans/06-clima.md.

#include "res://shaders/includes/rain_wet.gdshaderinc"

uniform vec4 water_color : source_color = vec4(0.75, 0.82, 0.95, 0.35);

varying vec3 v_world;
varying vec3 v_normal;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	ALBEDO = water_color.rgb;
	ROUGHNESS = 0.05;
	SPECULAR = 0.8;
	ALPHA = rain_streak(v_world, v_normal, TIME) * water_color.a;
}
