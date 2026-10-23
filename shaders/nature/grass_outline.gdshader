shader_type spatial;
// Borda dos tufos: segundo passe do material da grama (next_pass do
// grass_tuft.tres). Desenha só o lado de trás de uma casca um pouco maior que
// a lâmina, então sobra uma borda em volta dela. Mesmo vento e mesmo amassar.
render_mode cull_front, unshaded;
#define OUTLINE_PASS
#include "res://shaders/nature/grass_body.gdshaderinc"
