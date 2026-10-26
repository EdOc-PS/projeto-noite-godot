shader_type spatial;
// Tufo de grama 2D (lâminas chatas, assets/models/grass/grass_tuft_2d.gltf):
// mesmo corpo do tufo 3D, dos dois lados e sem borda (a casca não funciona em
// lâmina chata).
render_mode cull_disabled;
#include "res://shaders/nature/grass_body.gdshaderinc"
