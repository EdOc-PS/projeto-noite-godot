# Créditos dos Assets

Todos os assets de terceiros usados no projeto são **CC0** (domínio público): livres para uso pessoal, educacional e comercial, sem obrigação de crédito. Mesmo assim, creditamos os autores. O pacote original de cada um (com o `License.txt`) fica fora do projeto, em `E:\Estudos\Desenvolvimento de Games\Jogo - 3D\projeto-noite_sources\` (ver [ARQUITETURA.md](ARQUITETURA.md#pacotes-originais-ficam-fora-do-projeto)).

## Modelos 3D (`assets/models/`)

| Pacote | Autor | Pasta | Licença |
|---|---|---|---|
| KayKit: City Builder Bits (1.0) | Kay Lousberg ([kaylousberg.com](https://www.kaylousberg.com)) | `models/city/` | CC0 |
| KayKit: Forest Nature Pack (1.0) | Kay Lousberg ([kaylousberg.com](https://www.kaylousberg.com)) | `models/calm_place/forest_nature/` | CC0 |
| Tiny Treats: Homely House (1.0) | Isa Lousberg ([isalousberg.com](https://www.isalousberg.com)) | `models/calm_place/homely_house/` | CC0 |
| Tiny Treats: Pleasant Picnic (1.0) | Isa Lousberg ([isalousberg.com](https://www.isalousberg.com)) | `models/calm_place/pleasant_picnic/` | CC0 |
| Tiny Treats: Pretty Park (1.0) | Isa Lousberg ([isalousberg.com](https://www.isalousberg.com)) | `models/calm_place/pretty_park/` | CC0 |
| Tiny Treats: Fun Playground (1.0) | Isa Lousberg ([isalousberg.com](https://www.isalousberg.com)) | `models/calm_place/fun_playground/` | CC0 |
| Tiny Treats: House Plants (1.0) | Isa Lousberg ([isalousberg.com](https://www.isalousberg.com)) | `models/calm_place/house_plants/` | CC0 |

## Skyboxes (`assets/skyboxes/`)

| Pacote | Autor | Pasta | Licença |
|---|---|---|---|
| Skyboxes (1.0) | Kenney ([kenney.nl](https://www.kenney.nl)) | `skyboxes/basic/` | CC0 |
| Skyboxes Space (1.0) | Kenney ([kenney.nl](https://www.kenney.nl)) | `skyboxes/space/` | CC0 |

## UI (`assets/ui/`)

| Pacote | Autor | Pasta | Licença |
|---|---|---|---|
| Input Prompts (1.5A) | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/input_prompts/` | CC0 |
| Cursor Pack (1.1) | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/cursors/` | CC0 |
| Emotes | Kenney ([kenney.nl](https://www.kenney.nl)) | `ui/emotes/` | CC0 |

## Texto sugerido para a tela de créditos do jogo

> Modelos 3D: Kay Lousberg (KayKit) e Isa Lousberg (Tiny Treats). Skyboxes, ícones de controle, cursores e emotes: Kenney (kenney.nl). Todos sob licença CC0.

Ao adicionar um pacote novo, registre aqui: nome e versão, autor com link, pasta e licença.

## Feitos no projeto

Gerados por `tools/gen_models.py` no padrão do Tiny Treats (icosferas com normais suaves, cor da atlas `homely_house/tiny_treats_texture_1.png`). Pasta `assets/models/custom/`. Rodar o script de novo regera os arquivos.

| Asset | Pasta | Uso |
|---|---|---|
| `smoke_puff` | `custom/smoke/` | fumaça da chaminé (partículas) |
| `cloud_a` … `cloud_d` | `custom/clouds/` | nuvens grandes (10–17 m); reservadas pra cenas que mostrem o céu; a sombra das nuvens no outside é um Decal (`textures/effects/cloud_shadows.png`, `tools/gen_cloud_shadows.py`) |

As formas das nuvens foram inspiradas no pacote **Low Poly Clouds** (CGasaurus Rex, CGTrader). O pacote foi descartado por não seguir o estilo do projeto e não é usado nem guardado.
