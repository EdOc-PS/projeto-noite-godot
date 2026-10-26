shader_type spatial;
render_mode unshaded, cull_disabled;
// Forma da nuvem calculada aqui (não numa textura): corpo + gomos unidos de
// forma suave, recortados com precisão de pixel. Com textura, a borda da
// sombra (esticada por 20+ m) ficava serrilhada/rugosa; assim fica lisa.
// O plano só projeta sombra (cast_shadow = só sombra). Usado por
// scripts/weather/drifting_clouds.gd, que sorteia os gomos de cada nuvem.

uniform vec4 blobs[10];        // x, y (0..1 no plano), raio, 1 = usado
uniform float smoothness = 12.0;  // união suave dos gomos (maior = curvas mais marcadas)

void fragment() {
	float acc = 0.0;
	for (int i = 0; i < 10; i++) {
		if (blobs[i].w > 0.5) {
			float d = distance(UV, blobs[i].xy) / blobs[i].z;
			acc += exp(-smoothness * (d - 1.0));
		}
	}
	float field = log(max(acc, 1e-6)) / smoothness;   // > 0 dentro da nuvem
	ALBEDO = vec3(1.0);
	ALPHA = field > 0.0 ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
