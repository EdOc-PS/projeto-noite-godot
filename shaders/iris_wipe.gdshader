shader_type canvas_item;
// Iris wipe: tela preta com um buraco circular. Fora do círculo = preto.
// `center` e `radius` em pixels da tela; radius 0 = tela toda preta.

uniform vec2 center = vec2(0.0);
uniform float radius = 0.0;
uniform vec2 rect_size = vec2(1.0);
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness = 1.5; // borda em pixels (anti-alias)

void fragment() {
	float d = distance(UV * rect_size, center);
	float a = smoothstep(radius - softness, radius + softness, d);
	COLOR = vec4(color.rgb, color.a * a);
}
