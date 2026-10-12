shader_type sky;
// Céu do ciclo dia/noite: mistura três panoramas (dia, tarde, noite).
// Os pesos são controlados por scripts/environment/day_night_cycle.gd.

uniform sampler2D day_sky : source_color, filter_linear, repeat_enable;
uniform sampler2D dusk_sky : source_color, filter_linear, repeat_enable;
uniform sampler2D night_sky : source_color, filter_linear, repeat_enable;
uniform float dusk_weight : hint_range(0.0, 1.0) = 0.0;
uniform float night_weight : hint_range(0.0, 1.0) = 0.0;
uniform float day_energy = 1.0;
uniform float dusk_energy = 1.0;
uniform float night_energy = 0.6;

void sky() {
	vec3 day = texture(day_sky, SKY_COORDS).rgb * day_energy;
	vec3 dusk = texture(dusk_sky, SKY_COORDS).rgb * dusk_energy;
	vec3 night = texture(night_sky, SKY_COORDS).rgb * night_energy;
	COLOR = mix(mix(day, dusk, dusk_weight), night, night_weight);
}
