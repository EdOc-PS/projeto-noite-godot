shader_type spatial;
render_mode unshaded, cull_back;
// Silhueta: a vegetação em volta dos interiores aparece toda preta, com um
// contorno cinza (passe `silhouette_outline.gdshader` como next_pass) e
// balançando com o vento. Dá vida ao vazio em volta do cômodo.

#include "res://shaders/includes/wind.gdshaderinc"

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	VERTEX += wind_offset(VERTEX, MODEL_MATRIX[3].xyz, TIME);
}

void fragment() {
	ALBEDO = color.rgb;
}
