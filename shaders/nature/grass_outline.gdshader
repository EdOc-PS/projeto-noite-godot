shader_type spatial;
// Borda dos tufos: segundo passe do material da grama (next_pass do
// grass_tuft.tres). Desenha só o lado de trás de uma casca um pouco maior que
// a lâmina, então sobra uma borda em volta dela. Mesmo vento e mesmo amassar.
render_mode cull_front, unshaded, depth_draw_always;
#define OUTLINE_PASS
#define SPRITE_ALPHA  // borda com a mesma opacidade do tufo (mesmo sorteio)
#include "res://shaders/nature/grass_body.gdshaderinc"
