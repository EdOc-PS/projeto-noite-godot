shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Feixe de luz descendo do teto (falso volume): cone transparente que soma
// luz, forte em cima e sumindo embaixo, com as bordas suaves.
// Usar num CylinderMesh com top_radius pequeno e bottom_radius grande.

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float strength = 0.18;
uniform float edge_softness = 2.0;  // maior = bordas mais suaves

void fragment() {
	float down = UV.y;                           // 0 no topo, 1 embaixo
	float fade = (1.0 - down) * (1.0 - down);
	float facing = abs(dot(NORMAL, VIEW));       // centro do cone mais forte que a borda
	float edge = pow(facing, edge_softness);
	ALBEDO = color.rgb;
	ALPHA = strength * fade * edge;
}
