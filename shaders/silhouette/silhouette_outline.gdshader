shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never;
// Contorno da silhueta (técnica "inverted hull"): desenha o mesmo modelo um
// pouco inflado pelas normais, só as faces de trás, em cinza. Acompanha o
// mesmo vento da silhueta.

#include "res://shaders/includes/wind.gdshaderinc"

uniform vec4 outline_color : source_color = vec4(0.42, 0.44, 0.5, 0.25);  // alpha = força do contorno
uniform float outline_width = 0.035;  // espessura do contorno (metros)

void vertex() {
	VERTEX += wind_offset(VERTEX, MODEL_MATRIX[3].xyz, TIME);
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
