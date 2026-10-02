shader_type spatial;
// Rim light "vinil": camada extra (material_overlay) somada por cima do
// material original do objeto — realça as bordas sem substituir a textura.
render_mode blend_add, unshaded, depth_draw_never, cull_back;

uniform vec4 rim_color : source_color = vec4(0.62, 0.7, 1.0, 1.0);
uniform float rim_power = 3.0;     // maior = borda mais fina
uniform float rim_strength = 0.35;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	ALBEDO = rim_color.rgb * fresnel * rim_strength;
}
