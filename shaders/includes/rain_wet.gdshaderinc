// Molhado de chuva compartilhado: escorrido de água nas faces verticais.
// Usado pelo rain_streaks.gdshader (passe extra dos materiais normais) e pelo
// material toon, pra chuva aparecer com o toon ligado ou desligado.
// `weather_wetness` (0..1) é global, setado pelo WeatherCycle.

global uniform float weather_wetness;

float rw_hash(float n) { return fract(sin(n) * 43758.5453); }

// alpha (0..1) das faixas de água escorrendo neste ponto
float rain_streak(vec3 world, vec3 world_normal, float time) {
	float vertical = 1.0 - smoothstep(0.3, 0.6, abs(world_normal.y));
	float u = dot(world.xz, normalize(vec2(-world_normal.z, world_normal.x) + 1e-4));
	float density = 9.0;
	float r = rw_hash(floor(u * density));
	float lane = smoothstep(0.5, 0.0, abs(fract(u * density) - 0.5) * 2.0 - 0.3);
	float y = world.y + time * 0.6 * (0.6 + r) + r * 10.0;
	float drip = smoothstep(0.0, 0.15, fract(y * 0.7)) * (1.0 - smoothstep(0.35, 0.6 + r * 0.3, fract(y * 0.7)));
	return vertical * lane * drip * step(0.45, r) * weather_wetness;
}
