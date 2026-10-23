shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Raio de sol (falso volume): faixa de luz quente atravessando o ar, forte
// no meio e sumindo nas pontas e nas bordas, com leve tremulação. Quad
// alongado (QuadMesh), alinhado com a direção do sol. Força e cor pelo
// SunRays (`strength`/`color`). Usado por scripts/weather/sun_rays.gd.

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform float strength = 0.0;

void fragment() {
	float along = sin(UV.y * PI);                          // some nas duas pontas
	float across = 1.0 - abs(UV.x - 0.5) * 2.0;
	across = across * across;                              // borda macia
	float flicker = 0.85 + 0.15 * sin(TIME * 0.7 + UV.y * 3.0 + NODE_POSITION_WORLD.x);
	ALBEDO = color.rgb;
	ALPHA = strength * along * across * flicker;
}
