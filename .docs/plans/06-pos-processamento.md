# Pós-processamento e efeitos de ambiente

> **Vale:** silhueta e tilt-shift. A pincelada será definida em [07-estilo-visual.md](07-estilo-visual.md).

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Câmera: [plans/04-camera.md](04-camera.md) · Ambiente noturno: [plans/02-ambiente-calm-place.md](02-ambiente-calm-place.md)

Estilo geral (Breath of the Wild): [07-estilo-visual.md](07-estilo-visual.md)

**Regra: toda cena jogável usa este pacote.** Valores de referência: o campo (`tools/gen_field.py`). Já aplicado em campo, outside, inside_house e área de teste; só a cidade ainda usa o pacote do vinil. Cenas sem ciclo (outside, inside_house) usam o `BotwPost` com `fixed_phase` 1 (noite).

## Checklist de toda cena (estilo BotW)

| Efeito | Onde | Valor padrão | Pra quê |
|---|---|---|---|
| **Tonemap AgX** | `Environment.tonemap_mode = 4` | exposição 1,0 | Cores ricas sem estourar |
| **Luz ambiente do céu** | `ambient_light_source = 3` | energia ~1,1 de dia | Sombra clara e azulada |
| **Glow** | `glow_enabled`, blend soft light | bloom **0**, intensidade 0,15 de dia | Só emissões; o BotW é vivo, não brilhoso |
| **SSAO** (obrigatório) | `ssao_enabled` | intensidade 0,8, `ssao_light_affect` 0,15 | Profundidade sem escurecer |
| **Névoa** | `fog_enabled`, modo **distância** (+ volumétrica e bolsões à noite) | clara de dia, `fog_aerial_perspective` 0,7, `fog_sun_scatter` 0,4; valores por hora em [05-clima.md](05-clima.md) "Névoa" | Ar "lavado", esconde a borda do mapa; nunca chapada |
| **Anti-aliasing** (obrigatório) | `project.godot` (MSAA 4x + FXAA) | global | Bordas lisas |
| **Cor por hora** | `WeatherCycle.palette = BOTW` (`KEYS_BOTW`) | saturação 1,4–1,5, contraste 0,92 | Vivo e lavado |
| **Filtro de tela** | `ColorRect` com `shaders/post_process/botw_post.gdshader` + `scripts/visuals/botw_post.gd` (CanvasLayer 1) | pintura leve 0,3, nitidez 0,25, cor por hora | Cara de guache |
| **Desfoque das bordas** | tilt-shift (CanvasLayer 2) | blur **3,5** (mais fraco que o do vinil) | Foco no centro |
| **Personagens toon** | node com `scripts/visuals/botw_character.gd` | Ultimate Toon | Só personagens são cel shading |

**Proibido:** vinheta, bloom forte, DOF de distância (a câmera de cima borra tudo), filtro de tela em quad 3D (deixa partícula transparente preta), `PlasticApplier`/`ToonApplier` em cena nova.

## Por tipo de cena

| | Externa (noite) — `home/outside` | Interna — `home/inside_house` |
|---|---|---|
| Fundo | Céu (panorama noturno) | Cor quase preta azulada (o vazio em volta do cômodo) |
| Luz ambiente | Do céu, 0,45 | Cor quente, 0,35 |
| Luz principal | Lua (direcional azul-lavanda, 0,8, `shadow_opacity` 0,9) | Spots do teto (quentes, de cima pra baixo) + lareira |
| Névoa | Sim (azul-marinho nas bordas do mapa) | Não |
| Névoa em camadas | `fog_height` 1,2 / `fog_height_density` 0,45 (névoa que se acumula embaixo) + 3 camadas `GroundFog` (planos com `fog_card.gdshader` a 0,3 / 1,1 / 2,0 m) | — |
| Extras | Vento, sombra das nuvens (Decal), sombra de contato, riscos de vento, vagalumes | **Luminárias de teto** com feixe de luz (`scenes/props/ceiling_lamp.tscn`: spot **largo e suave**, ângulo 75°, alcance 9 m, borda esfumada `spot_angle_attenuation` 0,5, `spot_attenuation` 0,6, energia 2,6: ilumina a casa toda sem marcar um círculo no chão), fogo da lareira, **natureza em silhueta** no vazio em volta |

## Peças reutilizáveis

| Peça | Arquivo | Uso |
|---|---|---|
| Tilt-shift | `scenes/vfx/tilt_shift.tscn` + `shaders/post_process/tilt_shift.gdshader` | Toda cena (o outside ainda tem uma cópia própria igual; trocar pela instância quando mexer nele) |
| Luminária de teto | `scenes/props/ceiling_lamp.tscn` (fio + cúpula + lâmpada + spot + feixe `light_shaft.gdshader` saindo de dentro da cúpula) | Interiores: a luz "sai" da luminária, sem o topo do cone aparecendo |
| Sombra de contato | `scripts/visuals/contact_shadows.gd` | Externas com árvores/arbustos/pedras |
| Natureza em silhueta (**padrão de todo interior**) | node com `scripts/visuals/silhouette_applier.gd` + `shaders/silhouette*.gdshader` | Vazio em volta de interiores: vegetação preta com contorno cinza, balançando com o vento (o mesmo vento de fora, via `shaders/includes/wind.gdshaderinc`) |
| Luz tremulando | `scripts/props/lantern_flicker.gd` | Lareira, tochas, velas |
| Lanterna viva | `scripts/props/lantern_pulse.gd` (no `LanternLight`) | Postes do outside: tremula e a cor "respira" até um vermelho-brasa; o vidro (`LanternGlow`) acompanha |
| Fogo | `scenes/vfx/fire.tscn` (`shaders/fire/flame.gdshader` + `scripts/props/fire_embers.gd` + luz opcional) | Chama cartunesca estilo Breath of the Wild: gota com ruído subindo, faixas marcadas (miolo amarelo, meio laranja, borda vermelha), pisca. Tamanho pela escala. Lareira e tochas usam com a luz delas (`lantern_pulse.gd`) piscando junto |

## Regra de interiores

Toda vez que o jogador entra num prédio ou estrutura: o cômodo flutua no fundo escuro e, em volta, a **natureza de fora aparece em silhueta** (preta, contorno cinza discreto, balançando com o vento): árvores grandes (maiores que a construção) atrás e dos lados longe da câmera, grama fina em volta e aglomerada nos cantos.

## O que evitar

- **Vinheta** (escurecer as bordas com degradê): testada no interior e descartada.
- **Névoa só por distância** com câmera ortogonal: fica "achatada" (todo pixel está quase à mesma distância). Usar névoa por altura e camadas.
- Sombra preta e dura à noite: sombra noturna é clara e azulada, com contorno definido.
- Cena sem tilt-shift ou sem saturação: destoa do resto do jogo.

## Recomeço: field (estilo pintado)

| Efeito | Onde | Valores |
|---|---|---|
| Oclusão de ambiente (SSAO) | `Environment` do field | raio 1,2, intensidade 1,6, power 1,3, `light_affect` 0,15 |
| Brilho leve (glow) | `Environment` | intensidade 0,4, bloom 0,05 |
| Saturação | `Environment` (adjustments) | 1,1 |
| Sombra suave | `Sun` (DirectionalLight3D) | `light_angular_distance` 2,5 (penumbra que abre com a distância), `shadow_blur` 1,5, opacidade 0,75 |
| Pintura (Kuwahara) + nitidez + saturação | `scenes/vfx/paint_post.tscn` (CanvasLayer 1), `shaders/post_process/paint_post.gdshader` | pintura 0,35, raio 2, nitidez 0,2, saturação 1,15 |
| Tilt-shift (bordas desfocadas, vidro fosco) | `scenes/vfx/tilt_shift.tscn` (CanvasLayer 2, com `BackBufferCopy` pra ler a tela já pintada) | área nítida 0,28, elipse 0,5, desfoque 3,5 |

### Desempenho da grama

Testado e desfeito (visual piorou): transparência pontilhada (alpha hash), cilindro de 6 lados, MSAA desligado, sombras em qualidade 2 e pintura com raio 1.

- Sombras suaves em qualidade 2 (`soft_shadow_filter_quality`) e cilindro de 6 lados (decisão do usuário, por FPS).
- Grama some além de 45 m da câmera (`lod0_range` dos meshes no `terrain_assets.tres`).
- Grama não projeta sombra; a borda de casca (`next_pass`) desenha cada tufo duas vezes: se precisar de FPS, é a primeira coisa a desligar.
- Outras alavancas: menos lados no cilindro (`CYL_SIDES`), menos lâminas por tufo (`CYL_BLADES`), espaçamento maior (`grass_spacing`), pintura com `paint_radius` 1.

## Aquarela viva (2026-10-26) — campo
- `Environment`: tonemap **AgX** (`tonemap_mode` 4), saturação 1,3, **SSIL** ligado (raio 3, intensidade 0,8 — opcional: desligar `ssil_enabled` se o FPS cair; é o efeito mais pesado).
- `paint_post.gdshader` (cena `scenes/vfx/paint_post.tscn`, CanvasLayer 1), em ordem: pincelada Kuwahara (`paint_amount` 0,85, raio 2) → borda escurecida da aquarela (`edge_darken` 0,35, largura 1,5 px; a tinta acumula: escurece e satura) → cor viva (sombras × `shadow_tint` azul, luzes × `light_tint` quente, `tint_amount` 0,6). Nitidez desligada (brigava com a aquarela); saturação do shader 1 (a principal fica no Environment).
- Papel de aquarela removido (2026-10-26).
- Pincelada pronta (2026-10-26): primeiro passe = **Generalized Kuwahara** (Firerabbit/Acerola, MIT, `shaders/post_process/generalized_kuwahara.gdshader`, `_KernelSize` 6) no `KuwaharaRect`; um `BackBufferCopy` e depois o `PaintRect` (`paint_post` com o Kuwahara próprio desligado, `paint_amount` 0: só borda e cor). Cores mais vivas: saturação do Environment 1,45, do filtro 1,15, `tint_amount` 0,75.

## Field estilo Kenney (2026-10-27) — `scenes/levels/field/field_kenney.tscn`
Cópia do field com o visual dos previews do Kenney (low poly de brinquedo, cor chapada, luz macia). Mesma grama/flores/arbustos e o MESMO `terrain_data` (a semeadura é igual); só muda a aparência:
- Sem filtro de aquarela (`PaintPost`) e sem tilt-shift. Sem borda na grama e nos arbustos, sem onda dourada, sem aquarela no degradê.
- Luz: sol branco quente 1,15, sombra macia (`shadow_blur` 2,5, `light_angular_distance` 4, opacidade 0,6); luz ambiente LILÁS (0.66,0.66,0.86) → sombras azuladas; SSAO forte e macio (2,4, raio 1,6, `light_affect` 0,35) = cara de maquete; AgX, saturação 1,05, glow 0,15.
- Cores Kenney: chão `grass_kenney.png` (verde menta #5CC778), grama `grass_tuft_kenney.tres` (0.27,0.62,0.4 → 0.46,0.85,0.55), arbustos `bush_*_kenney.tres` (verde-árvore 0.17,0.5,0.36 → 0.33,0.74,0.5). Pincel `terrain_assets_kenney.tres`.
- Hachura de lápis no field Kenney (2026-10-27): `HatchingPost` (`scenes/vfx/hatching_post.tscn`, `hatching_post.gdshader`, adaptado do Hatching shader de annie, MIT). Riscos diagonais nas sombras (luminância < `range` 0,55), mais grossos no mais escuro, cruzados no bem escuro, tremendo a cada 0,15 s; cor do lápis roxo-escuro.
