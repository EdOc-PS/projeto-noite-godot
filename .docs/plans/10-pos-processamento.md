# Pós-processamento e efeitos de ambiente

> **Vale:** silhueta e tilt-shift. A pincelada será definida em [11-estilo-visual.md](11-estilo-visual.md).

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Câmera: [plans/05-camera.md](05-camera.md) · Ambiente noturno: [plans/02-ambiente-calm-place.md](02-ambiente-calm-place.md)

Estilo geral (Breath of the Wild): [11-estilo-visual.md](11-estilo-visual.md)

**Regra: toda cena jogável usa este pacote.** Valores de referência: o campo (`tools/gen_field.py`). Já aplicado em campo, outside, inside_house e área de teste; só a cidade ainda usa o pacote do vinil. Cenas sem ciclo (outside, inside_house) usam o `BotwPost` com `fixed_phase` 1 (noite).

## Checklist de toda cena (estilo BotW)

| Efeito | Onde | Valor padrão | Pra quê |
|---|---|---|---|
| **Tonemap AgX** | `Environment.tonemap_mode = 4` | exposição 1,0 | Cores ricas sem estourar |
| **Luz ambiente do céu** | `ambient_light_source = 3` | energia ~1,1 de dia | Sombra clara e azulada |
| **Glow** | `glow_enabled`, blend soft light | bloom **0**, intensidade 0,15 de dia | Só emissões; o BotW é vivo, não brilhoso |
| **SSAO** (obrigatório) | `ssao_enabled` | intensidade 0,8, `ssao_light_affect` 0,15 | Profundidade sem escurecer |
| **Névoa** | `fog_enabled`, modo **distância** (+ volumétrica e bolsões à noite) | clara de dia, `fog_aerial_perspective` 0,7, `fog_sun_scatter` 0,4; valores por hora em [06-clima.md](06-clima.md) "Névoa" | Ar "lavado", esconde a borda do mapa; nunca chapada |
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
