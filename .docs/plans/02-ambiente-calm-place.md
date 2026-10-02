# Plano 02 — Ambiente Noturno do Calm Place

Referência: [.docs/PROJETO-NOITE.md](../PROJETO-NOITE.md)

Objetivo: noite estilizada tipo diorama (Stylized Toy Aesthetic, Link's Awakening remake) em `scenes/calm_place/calm_place.tscn` — contraste quente (postes/casa) contra frio (luar), cores vibrantes e materiais "vinil".

Fora de escopo: dungeons, cidade (dia), sistemas de gameplay.

## Escopo

1. Luar (luz direcional + ambiente + fog) — ✅
2. Postes (luz quente + emissão + tremulação) — ✅
3. Pós-processamento (tonemap, SSAO, glow, cor, tilt-shift) — ✅
4. Atmosfera (janelas acesas, vento, vagalumes, névoa nas bordas) — ✅ (flores bioluminescentes: pendente, opcional)
5. Materiais vinil (roughness + rim light) — ✅
6. Iluminação baked (LightmapGI) — pendente, etapa final

## 1. Luar

- **`DirectionalLight3D`**: luz de sol/lua (raios paralelos, direção pela rotação). `light_color` azul-lavanda `#9fb4ff`, `light_energy = 0.4`, `shadow_blur = 3.0` (sombra macia).
- **`Environment_1`** (no `WorldEnvironment`, config global da cena): céu `ProceduralSkyMaterial` noturno, luz ambiente vinda do céu (`ambient_light_energy = 0.7`), fog de profundidade azul-marinho `#1b2340` (`fog_density = 0.015`, `fog_depth_curve = 1.5`) que apaga a borda do mapa ao longe.

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
- **Vento**: `shaders/wind_sway.gdshader` — balança só a parte alta do mesh (base parada), fase pela posição no mundo. Via `material_override` em ~65% da grama/flores (o resto parado, pra ficar natural), em toda folhagem e em todas as árvores. Materiais: `WindGrassMaterial`, `WindFoliageMaterial`, `WindTreeForestMaterial`, `WindTreeHouseMaterial` — ajuste com `sway_strength`/`sway_speed`.
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
- **Câmera** (`scripts/camera/isometric_camera.gd`, configurada em `scenes/main.tscn`): top-down fixa, sem rotação. O rig segue o jogador; o `Camera3D` é recuado ao longo do próprio eixo, então o jogador fica sempre centralizado. Inclinação por `pitch_degrees` (55°, sobrescreve a rotação do editor). Zoom ortogonal abre de `size 6` → `10` ao se aproximar da casa (`focus_radius = 10`).

## Avisos

- **Posições estimadas**: janelas/luzes da casa foram posicionadas pela geometria do `.gltf` + fotos, não medidas no editor — ajuste fino pelo gizmo se necessário.
- **Edições por fora do editor**: salvar a cena no Godot com uma versão antiga aberta sobrescreve mudanças feitas direto no `.tscn` (já aconteceu com overrides de material). Reabra a cena no editor antes de salvar após edições externas.
## Créditos dos assets

Todos KayKit / Tiny Treats, de Kay Lousberg (kaylousberg.com), CC0 — inclusive `forest_nature` e `city` (conferido nos `License.txt`).
