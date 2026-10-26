// Luz toon compartilhada (baseada no tutorial "Godot Toon Shading", Binbun3D:
// https://bun3d.com/tutorials/shading/godot-toon-shading/).
// Usada pelo material toon (toon_tutorial.gdshader) e pelos shaders próprios
// (vento/grama), pra tudo ter a mesma luz. Ligada/desligada pelo global
// `toon_enabled` (ToonApplier). Regras do projeto:
//  - degraus em TODAS as luzes (sol/lua e também lanternas, lâmpadas, fogo:
//    interiores não têm sol). Borda clara e brilho de vinil só na principal;
//  - sol/lua: degraus só no ângulo da luz (N·L) e a sombra entra suave depois
//    (a sombra macia do sol tem ruído e, quantizada, virava quadradinhos);
//  - lâmpadas: degraus no N·L × alcance, então a poça de luz também fica em
//    faixas (claro perto, escurecendo em degraus). Sombra dura nelas
//    (SoftShadows.lamp_size 0), pra não ter ruído.
// Com toon desligado, é a luz difusa comum (Lambert).

global uniform float toon_enabled;
global uniform float toon_bands;
global uniform float toon_secondary_amount;  // quanto as lâmpadas ficam em degraus (0 = luz comum, 1 = degrau cheio)
global uniform float toon_band_smoothness;  // 0 = degrau seco, 0,5 = degradê contínuo
global uniform float toon_rim_threshold;
global uniform float toon_rim_strength;
global uniform float toon_vinyl_strength;   // brilho suave de vinil (0 = sem)
global uniform float toon_vinyl_shininess;  // maior = brilho menor e mais concentrado

vec3 toon_diffuse(vec3 normal, vec3 light_dir, float attenuation, vec3 light_color, bool is_main) {
	float ndl = max(dot(normal, light_dir), 0.0);
	if (toon_enabled > 0.5 && !is_main) {
		float l = ndl * attenuation;
		float x = l * toon_bands;
		float base = floor(x);
		float stepped = clamp((base + smoothstep(0.5 - toon_band_smoothness, 0.5 + toon_band_smoothness, x - base)) / toon_bands, 0.0, 1.0);
		// misturado com a luz comum: degrau cheio deixava escuro demais onde a
		// lâmpada é fraca (o round() jogava a luz baixa pra zero)
		l = mix(l, stepped, toon_secondary_amount);
		return vec3(l) * light_color / PI;
	}
	if (toon_enabled > 0.5 && is_main) {
		// degraus com a passagem entre eles suavizada (degradê curto na borda)
		// (com suavidade 0 é igual ao round() do tutorial)
		float x = ndl * toon_bands;
		float base = floor(x);
		float f = smoothstep(0.5 - toon_band_smoothness, 0.5 + toon_band_smoothness, x - base);
		ndl = clamp((base + f) / toon_bands, 0.0, 1.0);
	}
	return vec3(ndl * attenuation) * light_color / PI;
}

vec3 toon_rim(vec3 normal, vec3 view, vec3 light_dir, float attenuation, vec3 light_color, bool is_main) {
	if (toon_enabled < 0.5 || !is_main) {
		return vec3(0.0);
	}
	float fres = 1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0);
	float lit = max(dot(normal, light_dir), 0.0) * attenuation;
	return vec3(step(toon_rim_threshold, fres) * lit * toon_rim_strength) * light_color / PI;
}

// Brilho suave de vinil: reflexo largo e macio da luz principal (Blinn-Phong
// suave, sem corte), pra o toon não perder a cara de brinquedo de plástico.
// Diferente da "bolinha branca" do tutorial (cortada e forte), reprovada.
vec3 toon_vinyl(vec3 normal, vec3 view, vec3 light_dir, float attenuation, vec3 light_color, bool is_main) {
	if (toon_enabled < 0.5 || !is_main) {
		return vec3(0.0);
	}
	vec3 h = normalize(light_dir + view);
	float spec = pow(max(dot(normal, h), 0.0), toon_vinyl_shininess);
	return vec3(spec * attenuation * toon_vinyl_strength) * light_color / PI;
}
