shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
// Borboleta: quad deitado com as duas asas; as asas dobram no meio (eixo do
// corpo) batendo rápido, cada uma num ritmo. Cor da asa pela partícula
// (COLOR), transparência pelo COLOR.a (fade). Usado por scripts/weather/butterflies.gd.

uniform sampler2D wing_tex : source_color, filter_linear_mipmap;
uniform float flap_speed = 14.0;
uniform float flap_angle = 1.1;   // radianos: quanto a asa sobe

void vertex() {
	float t = TIME * flap_speed + float(INSTANCE_ID) * 2.3;
	float a = (0.5 + 0.5 * sin(t)) * flap_angle;    // 0 = aberta, flap_angle = fechada pra cima
	float side = sign(VERTEX.x);
	float r = abs(VERTEX.x);
	// gira a asa em volta do corpo (eixo z): sobe de cada lado
	VERTEX.x = side * r * cos(a);
	VERTEX.y += r * sin(a);
}

void fragment() {
	vec4 tex = texture(wing_tex, UV);
	ALBEDO = tex.rgb * COLOR.rgb;
	ROUGHNESS = 0.7;
	ALPHA = step(0.5, tex.a) * COLOR.a;
}
