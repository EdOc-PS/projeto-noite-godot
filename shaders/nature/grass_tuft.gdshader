shader_type spatial;
// Tufos de grama com borda por casca (next_pass grass_tuft_outline.tres).
// Opaco com transparência FALSA (`fake_alpha`: cor misturada com a do chão pela
// opacidade sorteada por tufo), sem piscar ao andar.
render_mode cull_back;
#include "res://shaders/nature/grass_body.gdshaderinc"
