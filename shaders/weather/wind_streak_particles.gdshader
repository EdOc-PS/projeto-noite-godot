shader_type particles;
// Movimento dos riscos de vento (scripts/weather/wind_streaks.gd).
// Cada risco anda reto na direção do vento e faz um "nado de tubarão": vai e
// volta de leve pros lados num seno suave (não turbulência aleatória, que
// fazia o risco dar trancos e laços). Também controla o nascer/sumir: a
// espessura cresce e afina (o rastro não herda a transparência) e a cor some.

uniform vec3 emission_extents = vec3(11.0, 0.75, 11.0);
uniform vec3 wind_dir = vec3(1.0, 0.0, 0.08);
uniform vec2 speed_range = vec2(4.0, 6.25);    // m/s sorteado por risco
uniform vec2 width_range = vec2(0.4, 1.5);     // multiplicador da espessura
uniform float swim_amp = 0.35;                  // m/s pros lados (bem leve)
uniform float swim_freq = 1.4;                  // voltas por segundo do vai-e-volta
uniform vec2 alpha_range = vec2(0.3, 0.7);      // opacidade sorteada por risco
uniform float fade_end = 0.75;                  // fração da vida em que a cor já sumiu (o rastro acaba antes da morte)

float hash(uint n) {
	n = (n << 13u) ^ n;
	n = n * (n * n * 15731u + 789221u) + 1376312589u;
	return float(n & 0x7fffffffu) / float(0x7fffffff);
}

void start() {
	uint s = NUMBER * 7u + RANDOM_SEED;
	if (RESTART_POSITION) {
		vec3 r = vec3(hash(s + 1u), hash(s + 2u), hash(s + 3u)) * 2.0 - 1.0;
		TRANSFORM = EMISSION_TRANSFORM;
		TRANSFORM[3].xyz += r * emission_extents;
	}
	CUSTOM.x = mix(speed_range.x, speed_range.y, hash(s + 4u));  // velocidade
	CUSTOM.y = hash(s + 5u) * 6.2831;                              // fase do nado
	CUSTOM.z = mix(width_range.x, width_range.y, hash(s + 6u));   // espessura
	CUSTOM.w = 0.0;                                                // idade
	VELOCITY = normalize(wind_dir) * CUSTOM.x;
	COLOR = vec4(1.0, 1.0, 1.0, 0.0);
}

void process() {
	CUSTOM.w += DELTA;
	float life = clamp(CUSTOM.w / LIFETIME, 0.0, 1.0);
	vec3 d = normalize(wind_dir);
	vec3 side = vec3(-d.z, 0.0, d.x);
	// some junto: o fade, o encolher e o nado acabam juntos (o nado parando no
	// fim evita o risco "tremer" enquanto encolhe)
	float fade_out = 1.0 - smoothstep(0.4, fade_end, life);
	float fade_in = smoothstep(0.0, 0.25, life);
	VELOCITY = d * CUSTOM.x + side * sin(CUSTOM.w * swim_freq * 6.2831 + CUSTOM.y) * swim_amp * fade_out;
	// nasce fino e engrossa (fade in); no fim vai diminuindo junto com o fade
	float w = max(fade_in * fade_out * CUSTOM.z, 0.0001);
	TRANSFORM[0].xyz = vec3(w, 0.0, 0.0);
	TRANSFORM[1].xyz = vec3(0.0, w, 0.0);
	TRANSFORM[2].xyz = vec3(0.0, 0.0, w);
	float a = mix(alpha_range.x, alpha_range.y, fract(CUSTOM.y * 7.13));  // fixo por risco (vem da fase sorteada)
	COLOR = vec4(1.0, 1.0, 1.0, fade_in * fade_out * a);
}
