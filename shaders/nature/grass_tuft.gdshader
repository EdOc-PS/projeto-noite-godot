shader_type spatial;
// Tufos de grama com borda por casca (next_pass grass_tuft_outline.tres).
// TESTE: opacidade igual na lâmina toda (`sprite_alpha` 0,8 no material).
// cull_back: lâmina-cilindro fechada, só a face de fora desenha (senão o lado
// de dentro aparece pela transparência). depth_draw_always: a parte
// transparente grava profundidade, lâminas de trás não vazam por cima.
render_mode cull_back, depth_draw_always;
#define SPRITE_ALPHA
#include "res://shaders/nature/grass_body.gdshaderinc"
