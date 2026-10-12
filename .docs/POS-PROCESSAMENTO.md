# Pós-processamento e efeitos de ambiente

Referência: [PROJETO-NOITE.md](PROJETO-NOITE.md) · Câmera: [plans/05-camera.md](plans/05-camera.md) · Ambiente noturno: [plans/02-ambiente-calm-place.md](plans/02-ambiente-calm-place.md)

**Regra: toda cena jogável usa este pacote de efeitos.** É o que dá a cara de "maquete de vinil" do jogo. Cena nova sem eles fica visivelmente diferente das outras.

## Checklist de toda cena

| Efeito | Onde | Valor padrão | Pra quê |
|---|---|---|---|
| **Tonemap AgX** | `Environment.tonemap_mode = 4` | — | Cores ricas sem estourar o branco |
| **Glow** | `glow_enabled`, `glow_blend_mode = 2` (soft light) | intensidade 0,6–0,7 | Brilho de lâmpadas, fogo, emissões |
| **SSAO** | `ssao_enabled` | raio 1–2, intensidade 1,5–2 | Cantos e encontros escurecem (profundidade) |
| **Saturação e contraste** | `adjustment_enabled` | contraste **1,12**, saturação **1,3** | Cores vivas de brinquedo |
| **Tilt-shift (desfoque nas bordas)** | instância de **`scenes/effects/tilt_shift.tscn`** | foco 0,55, faixa 0,28, `ellipse_x` 0,5, blur 5 | Visual de miniatura: centro nítido, bordas desfocadas em elipse |
| **Sombras da luz principal** | `DirectionalLight3D` / luzes | `shadow_blur` 1,5–2 | Contorno definido, mas macio |

Pra adicionar numa cena: copiar os valores do `Environment` acima e instanciar `scenes/effects/tilt_shift.tscn` na raiz.

## Por tipo de cena

| | Externa (noite) — `calm_place/outside` | Interna — `calm_place/inside_house` |
|---|---|---|
| Fundo | Céu (panorama noturno) | Cor quase preta azulada (o vazio em volta do cômodo) |
| Luz ambiente | Do céu, 0,45 | Cor quente, 0,35 |
| Luz principal | Lua (direcional azul-lavanda, 0,8, `shadow_opacity` 0,9) | Spots do teto (quentes, de cima pra baixo) + lareira |
| Névoa | Sim (azul-marinho nas bordas do mapa) | Não |
| Névoa em camadas | `fog_height` 1,2 / `fog_height_density` 0,45 (névoa que se acumula embaixo) + 3 camadas `GroundFog` (planos com `fog_card.gdshader` a 0,3 / 1,1 / 2,0 m) | — |
| Extras | Vento, sombra das nuvens (Decal), sombra de contato, riscos de vento, vagalumes | **Luminárias de teto** com feixe de luz (`scenes/props/ceiling_lamp.tscn`), fogo da lareira, **natureza em silhueta** no vazio em volta |

## Peças reutilizáveis

| Peça | Arquivo | Uso |
|---|---|---|
| Tilt-shift | `scenes/effects/tilt_shift.tscn` + `shaders/tilt_shift.gdshader` | Toda cena (o outside ainda tem uma cópia própria igual; trocar pela instância quando mexer nele) |
| Luminária de teto | `scenes/props/ceiling_lamp.tscn` (fio + cúpula + lâmpada + spot + feixe `light_shaft.gdshader` saindo de dentro da cúpula) | Interiores: a luz "sai" da luminária, sem o topo do cone aparecendo |
| Sombra de contato | `scripts/environment/contact_shadows.gd` | Externas com árvores/arbustos/pedras |
| Natureza em silhueta (**padrão de todo interior**) | node com `scripts/environment/silhouette_applier.gd` + `shaders/silhouette*.gdshader` | Vazio em volta de interiores: vegetação preta com contorno cinza, balançando com o vento (o mesmo vento de fora, via `shaders/includes/wind.gdshaderinc`) |
| Luz tremulando | `scripts/environment/lantern_flicker.gd` | Lareira, tochas, velas |
| Lanterna viva | `scripts/environment/lantern_pulse.gd` (no `LanternLight`) | Postes do outside: tremula e a cor "respira" até um vermelho-brasa; o vidro (`LanternGlow`) acompanha |
| Fogo | `scenes/effects/fire.tscn` (`shaders/flame.gdshader` + `scripts/props/fire_embers.gd` + luz opcional) | Chama cartunesca estilo Breath of the Wild: gota com ruído subindo, faixas marcadas (miolo amarelo, meio laranja, borda vermelha), pisca. Tamanho pela escala. Lareira e tochas usam com a luz delas (`lantern_pulse.gd`) piscando junto |

## Regra de interiores

Toda vez que o jogador entra num prédio ou estrutura: o cômodo flutua no fundo escuro e, em volta, a **natureza de fora aparece em silhueta** (preta, contorno cinza discreto, balançando com o vento): árvores grandes (maiores que a construção) atrás e dos lados longe da câmera, grama fina em volta e aglomerada nos cantos.

## O que evitar

- **Vinheta** (escurecer as bordas com degradê): testada no interior e descartada.
- **Névoa só por distância** com câmera ortogonal: fica "achatada" (todo pixel está quase à mesma distância). Usar névoa por altura e camadas.
- Sombra preta e dura à noite: sombra noturna é clara e azulada, com contorno definido.
- Cena sem tilt-shift ou sem saturação: destoa do resto do jogo.
