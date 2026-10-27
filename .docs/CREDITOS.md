# Créditos dos Assets

Todos os assets de terceiros usados no projeto são **CC0** (domínio público): livres para uso pessoal, educacional e comercial, sem obrigação de crédito. Mesmo assim, creditamos os autores. O pacote original de cada um (com o `License.txt`) fica fora do projeto, em `E:\Estudos\Desenvolvimento de Games\Jogo - 3D\projeto-noite_sources\` (ver [ARQUITETURA.md](ARQUITETURA.md#pacotes-originais-ficam-fora-do-projeto)).

## UI (`assets/ui/`)

| Pacote | Autor | Pasta | Licença |
|---|---|---|---|
| Input Prompts (1.5A) | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/input_prompts/` | CC0 |
| Cursor Pack (1.1) | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/cursors/` | CC0 |
| Emotes | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/emotes/` | CC0 |

## Texturas (`assets/textures/`)

Só as nossas: `textures/terrain/grass.png` (verde liso, #61CB8B da paleta Kenney) e `grass_normal.png` (normal lisa). Os pacotes de natureza anteriores (Quaternius, Stylized Grass and Dirt, Kenney Foliage) foram arquivados em `projeto-noite_sources/natureza-arquivada/`.


## Feitos no projeto

| Asset | Pasta | Uso |
|---|---|---|
| `grass_tuft`, `grass_sprig` | `assets/models/grass/` | tufo de grama (lâminas-cilindro) e raminho branco, gerados por `tools/gen_grass_tufts.py`; pincel do Terrain3D (`terrain_assets.tres`) |

## Sprites

| Pacote | Autor | Pasta | Licença |
|---|---|---|---|
| Foliage Sprites (`PNG/Shaded/sprite_0093` → `sprig_0093.png`; `sprite_0081/0086/0084` → folhas voando `leaf_drop/leaf_maple/leaf_lobed.png`) | Kenney ([kenney.nl](https://www.kenney.nl)) | `textures/vegetation/`, `textures/effects/leaves/` (pacote completo em `projeto-noite_sources/textures/kenney_foliage_sprites/`) | CC0 |

## Modelos de terceiros

| Modelo | Autor | Pasta | Licença |
|---|---|---|---|
| `Bush_Common` + `Leaves_TwistedTree_C.png` (Stylized Nature MegaKit) | Quaternius ([quaternius.com](https://quaternius.com)) | `assets/models/bushes/` (teste de arbusto; pacote em `projeto-noite_sources/natureza-arquivada/`) | CC0 |

## Shaders de terceiros

| Shader | Autor | Onde | Licença |
|---|---|---|---|
| Stylized Grass (cor da grama) | StayAtHomeDev | adaptado em `shaders/nature/grass_body.gdshaderinc` | MIT — texto em `.docs/licencas/stylized_grass_LICENSE.txt` |

## Shaders guardados (não usados agora, prontos pra reaplicar)

| Shader | Autor | Onde | Licença |
|---|---|---|---|
| Generalized Kuwahara (aquarela) | Firerabbit, porte de Acerola ([godotshaders](https://godotshaders.com/shader/generalized-kuwahara/)) | `shaders/post_process/generalized_kuwahara.gdshader` (+ `paint_post.gdshader`, nosso) | MIT — `.docs/licencas/generalized_kuwahara_LICENSE.txt` |
| Hatching shader (contorno de lápis) | annie ([godotshaders](https://godotshaders.com/shader/hatching-shader/)) | `shaders/post_process/hatching_post.gdshader` (adaptado) | MIT — `.docs/licencas/hatching_LICENSE.txt` |

## Plugins (`addons/`)

| Plugin | Autor | Pasta | Licença |
|---|---|---|---|
| Terrain3D 1.0.2 | Tokisan Games ([github.com/TokisanGames/Terrain3D](https://github.com/TokisanGames/Terrain3D)) | `addons/terrain_3d/` | MIT |

## Texto sugerido para a tela de créditos do jogo

> Ícones de controle, cursores, emotes e folhagem: Kenney (kenney.nl). Terreno: Terrain3D (Tokisan Games). Grama estilizada: StayAtHomeDev. Licenças CC0 e MIT.

Ao adicionar um pacote novo, registre aqui: nome e versão, autor com link, pasta e licença.
