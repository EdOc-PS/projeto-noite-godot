# Plano 02 — Ambiente Noturno do Calm Place

Referência: [.docs/PROJETO-NOITE.md](../PROJETO-NOITE.md)

Objetivo: noite estilizada tipo diorama (Stylized Toy Aesthetic, Link's Awakening remake) em `scenes/calm_place/outside/outside_environment.tscn` — contraste quente (postes/casa) contra frio (luar), cores vibrantes e materiais "vinil".

Fora de escopo: dungeons, cidade (dia), sistemas de gameplay.

## Escopo

1. Luar (luz direcional + ambiente + fog) — ✅
2. Postes (luz quente + emissão + tremulação) — ✅
3. Pós-processamento (tonemap, SSAO, glow, cor, tilt-shift) — ✅
4. Atmosfera (janelas acesas, vento, vagalumes, névoa nas bordas) — ✅ (flores bioluminescentes ✅, poeira dos passos ✅)
5. Materiais vinil (roughness + rim light) — ✅
6. Iluminação baked (LightmapGI) — configurado; falta clicar **Bake Lightmaps** no editor

## 1. Luar

- **`DirectionalLight3D`**: luz de sol/lua (raios paralelos, direção pela rotação). `light_color` azul-lavanda `#9fb4ff`, `light_energy = 0.4`, `shadow_blur = 3.0` (sombra macia).
- **`Environment_1`** (no `WorldEnvironment`, config global da cena): céu `PanoramaSkyMaterial` com `assets/skyboxes/space/skybox-space-nebula.png` (`energy_multiplier = 0.6`), luz ambiente vinda do céu (`ambient_light_energy = 0.7`), fog de profundidade azul-marinho `#1b2340` (`fog_density = 0.015`, `fog_depth_curve = 1.5`) que apaga a borda do mapa ao longe.

## 2. Postes

- **`OmniLight3D`** (`LanternLight`, dentro de cada `StreetLantern`): luz puntual laranja `Color(1, 0.55, 0.1)`, `light_energy = 2.5`, `omni_range = 6.5`, sem sombra própria.
- **`LanternGlow`**: esfera emissiva (`LanternGlowMaterial`, emissão 7) dentro da caixa de vidro. Necessária porque o `street_lantern.gltf` usa um único material pro poste inteiro — emissão nele faria o metal brilhar.
- **`scripts/environment/lantern_flicker.gd`**: tremulação suave via `FastNoiseLite` (`base_energy`, `flicker_amount`, `flicker_speed` editáveis no Inspector), dessincronizada por poste.

## 3. Pós-processamento (`Environment_1`)

- **Tonemap AgX** (`tonemap_mode = 4`): comprime o HDR sem estourar pra branco.
- **SSAO**: escurece frestas/contatos (base de árvores, cercas) — efeito "pousado na maquete".
- **Glow**: espalha brilho dos pixels acima de `glow_hdr_threshold`; `glow_levels` 2–6, aditivo. Anti-aliasing MSAA 4x + FXAA no `project.godot`.
- **Cor**: `adjustment_saturation = 1.3`, `adjustment_contrast = 1.12` — cores vivas, "limpinhas", de brinquedo de vinil.
- **Tilt-shift**: `shaders/tilt_shift.gdshader` num `CanvasLayer` + `ColorRect` de tela cheia (`TiltShiftLayer`). Desfoca topo/rodapé, faixa central nítida; desfoque suave tipo vidro fosco (mipmaps da tela + 16 amostras em espiral). Feito à mão porque o DOF nativo não funciona com câmera ortogonal.

## 4. Atmosfera

- **Janelas e luzes da casa** (filhos do nó `house`): coração do frontão (`HeartWindowGlow`/`Light`), janela da porta (`DoorWindowGlow`), janelas laterais (`SideWindowLeft`/`SideWindowRigth`), lanternas da varanda (`PorchLanternLeft/Right`), fogo da chaminé (`ChimneyFireGlow`/`Light`). Quads/formas emissivas com `WindowGlowMaterial` + `OmniLight3D` fraca; lanternas e chaminé usam `lantern_flicker.gd`.
- **Vento**: `shaders/wind_sway.gdshader` — balança só a parte alta do mesh (base parada), fase pela posição no mundo. Aplicado ao iniciar pelo node `WindApplier` (`scripts/environment/wind_applier.gd`), que classifica pelo nome do glTF: grama/flores (~65%, `grass_chance`; o resto parado pra ficar natural), folhagem (`foliage_*`) e árvores (`tree*`, tronco parado até `tree_start`). Um material compartilhado por tipo e textura atlas do kit. Ajuste pelos exports do `WindApplier`.
- **Toque do jogador**: no mesmo shader. Ao passar perto, a planta achata (inclina só um pouco pra longe do jogador). O `player.gd` atualiza a variável global de shader `player_pos` (registrada em `project.godot` → `[shader_globals]`). Força por tipo nos exports `*_push` do `WindApplier` (árvores não reagem). Arbustos: vento e toque mais leves. Vegetação a mais de `far_radius` (20 m) da casa fica parada, exceto árvores.
- **Vagalumes dos postes**: o poste perto do banco (`StreetLantern2`) tem um `LanternFireflies` (12 partículas emitidas num anel em volta do poste, `local_coords`), girando devagar com `scripts/environment/slow_spin.gd`, que faz eles rodearem a luz.
- **Vagalumes**: nó `Fireflies` (`GPUParticles3D`) — 45 esferas emissivas amarelo-esverdeadas (emissão 12) sobre o mapa, sem gravidade, turbulência e fade in/out. Ajuste: `amount`, `emission_box_extents` (`FireflyProcess`), `radius` (`FireflyMesh`).
- **Névoa nas bordas**: nó `EdgeFog` — planos horizontais em duas alturas (0.35 / 1.0), faixas de 16 de largura (entram ~8 no mapa), ao longo das 4 bordas do mapa (onde estão as paredes invisíveis), com `shaders/fog_card.gdshader` (ruído rolando devagar, bordas suaves, fade ao encostar em objetos). Ajuste: `density`, `fog_color`, `noise_scale` no `FogCardMaterial`.

## 5. Materiais vinil

- Tiny Treats já vinha com `roughness 0.5` / `metallic 0` (dentro do alvo). O pack `forest_nature` vinha com `0.6`: árvores recebem `0.42` via material de vento; arbustos e rochas via `ForestVinylMaterial` (`surface_material_override/0`).
- **Rim light**: `shaders/rim_overlay.gdshader` — realce lavanda nas bordas (fresnel), somado por cima do material original via `material_overlay` (`RimOverlayMaterial`) em casa, banco, cercas, postes, tocos, arbustos, rochas, frutas, plantas e objetos da casa. Nos objetos com vento o rim está embutido no `wind_sway.gdshader` (o overlay não acompanharia o balanço). Ajuste: `rim_strength`, `rim_power`, `rim_color`.

## 6. Iluminação baked (LightmapGI) — configurado, falta gerar o bake no editor

- Nó `LightmapGI` na raiz (`quality = 1` médio, `bounces = 3`, denoiser ligado, usa o céu da cena).
- Import dos `.gltf`: objetos fixos (chão, casa, cercas, postes, árvores, pedras, arbustos, tocos, caminho) com `meshes/light_baking = 2` (gera UV2 pro lightmap); grama, flores, folhagem, plantas, frutas e pássaro com `3` (dinâmicos, iluminados pelos probes do lightmap — mexem com o vento/são pequenos).
- Luzes (luar, postes, janelas, lanternas, chaminé) ficam em `bake_mode = Dynamic` (padrão): luz direta em tempo real (mantém a tremulação), só a luz rebatida é "assada".
- Gerar: selecionar `LightmapGI` → **Bake Lightmaps** (salva um `.lmbake` ao lado da cena). Refazer sempre que mover/adicionar objetos fixos.

## Extras

- **Cenário denso**: área jogável = elipse do spawn até a casa (centro `(1.5, -0.5)`, raios 9 × 12).
  - `forest_ring` (com colisão): anel de árvores, pedras e arbustos na borda da elipse + `InvisibleWall` (48 segmentos logo atrás, fecha qualquer fresta).
  - `forest_fill` (sem colisão, fora do alcance do player): árvores, arbustos, pedras e grama `forest_nature` até as bordas do mapa; árvores maiores (Tree_1_C, 2_D, 2_E, 3_C, 4_C) só longe da área jogável.
  - Itens soltos reorganizados nos grupos certos (pedras → `rocks`, arbustos → `bush`, grama → `grass_flowers`, árvores Tree_2 → `tree_simple_large`, Tree_4 → `tree_especie_large`); itens dentro da área jogável sem colisão receberam colisão (formas `Col_<asset>`).
- **Bordas invisíveis**: `MapBounds` (4× `StaticBody3D`, `x/z = ±17.5`, altura 4) — o player não sai dos 34×34 do chão.
- **Câmera** (`scripts/camera/isometric_camera.gd`, configurada em `scenes/calm_place/outside/outside.tscn`): top-down fixa, sem rotação. O rig segue o jogador; o `Camera3D` é recuado ao longo do próprio eixo, então o jogador fica sempre centralizado. Ângulo: **diagonal isométrica**, `pitch_degrees` 45° + `yaw_degrees` -17° (porta da casa vista um pouco pela direita; ver plano 05). Zoom ortogonal abre de `size 6` → `10` ao se aproximar da casa (`focus_radius = 10`).

## Avisos

- **Posições estimadas**: janelas/luzes da casa foram posicionadas pela geometria do `.gltf` + fotos, não medidas no editor — ajuste fino pelo gizmo se necessário.
- **Edições por fora do editor**: salvar a cena no Godot com uma versão antiga aberta sobrescreve mudanças feitas direto no `.tscn` (já aconteceu com overrides de material). Reabra a cena no editor antes de salvar após edições externas.
## Créditos dos assets

Ver [CREDITOS.md](../CREDITOS.md).

## Sombras da noite (ajuste de 2026-10-08)

Como os jogos modernos fazem: a **lua é a luz principal** (forte o bastante pra desenhar sombras), o **ambiente é baixo** e a sombra é suave e azulada, nunca recorte preto. Brilho geral parecido, mas com sombras que se leem.

- Lua (`DirectionalLight3D`): energia 0,4 → **0,8**, `shadow_opacity` 0,9, `shadow_blur` 1,5, `directional_shadow_max_distance` 35 m (o mapa é pequeno: concentrar a resolução da sombra deixa o contorno nítido).
- Ambiente (`ambient_light_energy`): 0,7 → **0,45**, compensando a lua mais forte.
- SSAO: raio 1,2 → 2,0, intensidade 2,0, `ssao_light_affect` 0,3 (escurece cantos também sob a luz da lua e dos postes).
- **Sombra de contato** (`ContactShadows`, `scripts/environment/contact_shadows.gd`): Decal com mancha radial escura embaixo de cada árvore, arbusto, folhagem, pedra e toco, do tamanho da base. O SSAO de tela não pega bem a base de objetos vistos de cima (câmera ortogonal) e sem isso eles parecem flutuar. Ajuste: `color` (alpha = força) e `size_factor`.

## Sombra das nuvens

`CloudShadows`: um `Decal` de 120 × 120 m (`scripts/environment/cloud_shadow_decal.gd`) com a textura `assets/textures/effects/cloud_shadows.png` (gerada por `tools/gen_cloud_shadows.py`: 2 manchas macias a cada 40 m, repetindo). Desliza na direção do vento e, a cada período, volta ao início sem emenda. Não depende da luz da lua nem do lightmap. Ajuste: `modulate` (cor e força; alpha 0,6), `speed`, `wind_dir`.

Escolhido no lugar de nuvens 3D projetando sombra: a câmera nunca mostra o céu, então só a sombra importa, e o Decal dá sombra mais macia, barata e controlável. Os modelos `assets/models/custom/clouds/` ficam pra cenas que mostrem o céu.

Fumaça da chaminé: `house/ChimneySmoke` (`scripts/environment/chimney_smoke.gd`, mesh `custom/smoke/smoke_puff.gltf`).

## Flores bioluminescentes — desligado

Removido a pedido (`flower_glow` = 0). O código continua no shader/`WindApplier` pra reativar se quiser.


No `wind_sway.gdshader` (`bio_glow`, `bio_pulse_speed`): as pétalas emitem luz na própria cor, pulsando devagar e fora de sincronia entre flores. O caule não brilha (máscara: pixels onde o verde domina). O `WindApplier` aplica em metade das `flower_*` (`flower_glow_chance` 0,5; o resto só balança), ajuste por `flower_glow` (0,7) e `flower_pulse_speed`. O glow do `Environment` faz o halo.

## Poeira dos passos

`Player/FootstepDust` (`scripts/player/footstep_dust.gd`): 5 partículas com o mesh `smoke_puff` (nasce com ~0,3 e encolhe até sumir), lavanda clara semitransparente (alpha 0,4, sem sombreamento), soltas enquanto o personagem anda no chão (`min_speed`). Ficam no mundo (`local_coords = false`) e somem encolhendo em 0,6 s.

## Riscos de vento

`WindStreaks` (`scripts/environment/wind_streaks.gd`): 4 linhas brancas finas e compridas (rastro de 1 s) e semitransparentes passando na direção do vento, com leve ondulação (rastro/trail de partícula com fita em cruz, afinando nas pontas). O emissor acompanha o jogador, então sempre aparecem na área da câmera. Ajuste: `streak_count`, `speed`, `streak_color` (alpha = força), `width`.

Vagalumes soltos (`Fireflies`): 45 → 25. Os do poste continuam iguais.

Poeira dos passos: no fim da vida se deforma e esfarela em manchas (`shaders/dust_dissolve.gdshader`, usa a idade da partícula), estilo Death's Door.

Tilt-shift: a área nítida agora é uma **elipse** (borda convexa: cantos e laterais também desfocam), não uma faixa. Ajuste `ellipse_x` no `TiltShiftMaterial` (0 = faixa antiga; maior = elipse mais estreita).

## Tufos de grama densa

`GrassField` (`scripts/environment/grass_field.gd`): **milhares** de tufos (`assets/models/custom/grass/grass_tuft_A/B.gltf`, gerados por `tools/gen_models.py`) agrupados em **manchas** pelo cenário. As manchas vêm de um ruído (onde passa de `threshold`, mais densa no centro). Desenhados com **MultiMesh** (um desenho por tipo de tufo), por isso a quantidade não pesa como nós separados. Usam o `wind_sway.gdshader`: balançam com o vento e amassam com o jogador. Não nascem na casa (caixa da casa + `house_margin`), no caminho de pedras (`path_clearance`, ligando as pedras próximas) nem em cima de cercas, banco e postes (`clearance`). Faixas **densas nas laterais da casa** (`house_side_width`) e zonas extras (`bonus_zones`).

Ajuste: `spacing` (densidade dentro da mancha), `threshold` (quantidade de manchas), `noise_frequency` (tamanho das manchas), `noise_seed` (outro desenho de manchas).

## Névoa com profundidade

A névoa por distância ficava "achatada" porque a câmera é ortogonal (tudo está quase à mesma distância dela). Agora: névoa **por altura** no `Environment` (`fog_height` 1,2, `fog_height_density` 0,45: mais densa embaixo) e 3 camadas de névoa (`GroundFog`, planos de 44 m com `fog_card.gdshader` a 0,3 / 1,1 / 2,0 m) com manchas que se movem, dando volume. Densidade de distância caiu pra 0,008.

## Nuvens de poeira no chão

`GroundDust` (`scripts/environment/ground_dust.gd`): a cada 3–6 s (`interval`) nasce, a 2,5–7 m do jogador, um bolinho de 9 nuvenzinhas (`smoke_puff`) rente ao chão que cresce, vai com o vento e esfarela (mesmo `dust_dissolve.gdshader` da poeira dos passos). Ajuste: `dust_color` (alpha = força), `puffs`, `cloud_size`, `drift_speed`.

Grama densa (`GrassField`): balança mais rápido (`sway_speed` 2,3) e tem **altura em ondas** (`height_range` 0,6–1,7, `height_frequency`): um ruído largo faz a grama crescer e baixar pelo campo, e dentro de cada mancha ela é mais alta no centro. Faixa densa acompanhando o caminho de pedras (`path_border_width`), sem entrar nele.
