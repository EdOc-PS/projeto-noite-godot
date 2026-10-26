// Caules das flores (cartas cruzadas em pé), com efeito chiclete: escurecem e
// ficam transparentes indo pro pé. Transparente de verdade (sem alpha scissor).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
#define STEM
#include "res://shaders/nature/flower_card.gdshaderinc"
