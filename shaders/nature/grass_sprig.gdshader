shader_type spatial;
render_mode cull_disabled;
// Raminhos (sprite do Kenney em carta virada pra câmera), levemente
// transparentes (`sprite_alpha`). Shader separado do tufo porque usar ALPHA
// deixa o material inteiro no modo transparente; a grama tem que ficar opaca.
#define SPRITE_ALPHA
#include "res://shaders/nature/grass_body.gdshaderinc"
