# Vegetação

Referência: [07-estilo-visual.md](07-estilo-visual.md) · Vento: [05-clima.md](05-clima.md)

Regras de como a vegetação é feita e posta. Recomeço do zero: só a grama por enquanto.

## Grama (tufos)

- **Um modelo de cada** (decisão: variar com giro, escala e altura já basta; menos modelos = menos peso):
  - `assets/models/grass/grass_tuft.gltf` (mesh 0 do pincel): tufo de **lâminas-cilindro** (tubo de 6 lados, raio de 120% da meia-largura, afina 12%, 60% das lâminas do tufo base) com **ponta pontuda de bico arredondado** (ogiva de 2,4 raios), curvando pra fora do centro.
  - `assets/models/grass/grass_sprig.gltf` (mesh 1): raminho de folhinhas brancas.
  - Gerados por `tools/gen_grass_tufts.py`. Os tufos de fita (2D) e as variações B/C foram testados e tirados.
- **Importação**: `meshes/generate_lods=false` (com LOD o Godot simplifica a malha e a ponta vira triângulo) e `meshes/light_baking=0` nos `.gltf.import`.
- **Onde fica**: no pincel do Terrain3D (`scenes/levels/field/terrain_assets.tres`), nunca em nós. Pintar/apagar com a ferramenta Instancer (Ctrl apaga). A grama inicial do field é semeada pelo `scripts/world/terrain_flat_start.gd` (quando o script ou os valores da grama mudam, a cena refaz o chão e a grama sozinha ao abrir no editor; também dá pra forçar marcando **Regenerate** no nó Terrain3D. Refazer apaga o que foi pintado à mão).
- **Material**: `assets/materials/grass_tuft.tres` (borda por casca no `next_pass`: `grass_tuft_outline.tres`). Raminho: `grass_sprig.tres` com `grass_sprig.gdshader` (transparente). Os dois usam `shaders/nature/grass_body.gdshaderinc`.

### Cor e shaded

- Cor do shader **Stylized Grass** (StayAtHomeDev, MIT, licença em `.docs/licencas/`): degradê base → ponta × manchas de ruído pelo mundo.
- Verde vivo da referência. **Ponta clara, base mais escura**: ponta `(0.56, 0.75, 0.2)`, base `(0.34, 0.53, 0.08)`: verde vivo levemente aquarela (um pouco menos saturado), com manchas suaves de tom a cada ~6 m (`noise_amount` 0,6, `noise_scale` 6).
- **Shaded** (como os sprites Shaded do Kenney): cada lâmina tem o topo claro e a base mais escura, e **40% das lâminas são inteiras mais escuras** (mesma cor, tom 0,68–0,78); as outras ficam na cor cheia. Nunca um verde diferente, nunca preto.
- Luz suave: o lado na sombra fica no máximo ~22% mais escuro (`light_floor` 0,78); o verso da lâmina vira a normal.

### Borda

- Contorno verde leve em volta de cada lâmina: segundo passe do material (`grass_tuft_outline.tres`, `shaders/nature/grass_outline.gdshader`), casca invertida de 10 mm (`outline_size`), cor próxima da grama, com o mesmo vento e o mesmo amassar.

### Brilho

- **Ponta acesa** (`tip_glow` 0,25): degradê de luz subindo pra ponta, a partir de `glow_start` 0,55 da altura.
- **Borda clara** contra o céu (`rim_glow` 0,35, fresnel), mais forte em cima.
- **Translucidez** com o sol atrás (`backlight` 0,6, cor amarelada): a ponta acende quando se olha na direção do sol.
- Tudo é **multiplicado pela cor da lâmina**, então o shaded continua: a lâmina escura brilha menos que a clara.

### Contorno (teste, desligado)

- `outline_only` no material: cada lâmina tem a **silhueta** opaca (borda com `outline_width` px na tela) e o miolo vazado. (Miolo semitransparente foi testado e tirado: usar ALPHA deixa o material inteiro transparente e a grama se desenha fora de ordem.) O mesh guarda em UV2.x a distância até a borda (0 na borda, 1 no pé do meio da lâmina).

### Raminhos de folhinhas

- `assets/models/grass/grass_sprig.gltf` (mesh 1 do pincel): o `sprite_0093` do Kenney Foliage **refeito em 3D**: caule em tubo fino, 6 galhos diagonais **em espiral em volta do caule**, começando logo acima do pé (quase sem caule pelado), com folhas grandes, (frente, trás e lados), terminando em folhas em gota (elipsoides) e folhinhas menores no meio dos galhos. **Sempre mais alto que a grama em volta** (`sprig_over`).
- Cor `assets/materials/grass_sprig.tres`: **verde no pé e branco no topo**.
- Pouca quantidade e **nunca perto um do outro**: só onde tem tufo, `sprig_chance` 0,01 e no mínimo 3 m entre raminhos (`sprig_min_distance`). Opacidade sorteada por raminho entre 0,4 e 0,5 (`sprite_alpha`) e topo bem branco, pra ficarem mais visíveis que a grama. Sem sombra.

### Direção da câmera

- O jogador anda principalmente de **sudoeste pra nordeste** (e volta), às vezes de oeste pra leste; a câmera fica fixa (yaw 40,5°).
- **Tufos**: lâminas e tufos em direções aleatórias. Virar as lâminas pra câmera foi testado e tirado: o tufo ficava chapado, com cara de PNG.
- **Raminhos**: 3D, direções aleatórias (a versão em carta virada pra câmera foi trocada pelo 3D).

### Movimento (igual ao projeto antigo)

- **Regra**: a borda (`grass_tuft_outline.tres`) tem que ter os **mesmos valores de vento e de amassar** do `grass_tuft.tres` (`sway_*`, `wind_dir`, `orbit`, `bend_*`, `push_*`). Se forem diferentes, a borda se mexe diferente da lâmina e descola dela quando o jogador passa.

- **O vento nunca deita a grama de vez**: a dobra tem limite de ~35° (`bend_limit` 0,6 rad).


- Balanço em oval, fase pela posição de cada tufo (`sway_strength` 0,06, `sway_speed` 2,3, `sway_height` 0,35).
- Dobra nas rajadas do vento global (`wind.gd`), com rigidez e ruído próprios por tufo (uns deitam mais que outros).
- Grama e raminhos **amassam** quando o jogador passa: inclinam pra longe dele e achatam (no material: `push_strength` 0,08, `push_radius` 0,9, `push_squash` 0,5), sem atravessar o personagem.

### Regras de tamanho

- Tufos: A raio 0,14 m e lâminas de 32–52 cm; B 0,11 m e 25–41 cm; C 0,16 m e 37–60 cm.
- Escala por tufo `0,75–1,1`.
- **Altura: o tamanho do tufo é o mínimo.** Só onde a mancha é densa ele cresce, até **80% mais alto** no meio (`grass_dense_growth` 0,8): nas áreas densas os tufos ficam entre +56% e +80% (a onda varia 70–100% do crescimento). Na borda e em áreas ralas fica no tamanho normal.
- **Nunca esticar a altura muito além da largura** (> ~1,4×): a ponta redonda vira ponta fina. Por isso as regras do campo antigo (altura 1,8–2,8×) não servem pra este tufo.
- Espaçamento 0,26 m entre tufos na mancha e limite das manchas em 0,06 (`grass_threshold`): menos tufos e mais chão entre as manchas, por FPS.
- **Manchas com clareiras**: o ruído decide onde nasce, o resto é chão.
- Grama **não projeta sombra**.

## Chão: terra

- **Terra** (`assets/textures/terrain/dirt.png`, marrom amarelado liso, RGB 176, 138, 78): textura 1 do Terrain3D, pra caminhos. Pintar com a ferramenta **Paint** (textura "Terra").
- **Manchas de terra automáticas** (**desligadas**: `dirt_patches` 0; o código fica pra usar de novo) (`terrain_flat_start.gd`, `dirt_*`): 4 manchas **pequenas** de 1,5–3 m de raio (o campo tem muito mais grama livre que terra), contorno torto por ruído (não círculo perfeito), pintadas direto no mapa de controle do Terrain3D quando o chão é criado. **Degradê de 1,5 m** (`dirt_edge`) pra grama: a terra vai sendo misturada por cima da grama pelo `blend`. Dentro da terra não nasce grama nem raminho; no degradê a grama vai rareando.
- **Degradê ao pintar à mão**: é a própria mistura do Terrain3D. A borda de cada pincelada vira mistura das duas texturas; `blend_sharpness` 0 no material do terreno deixa a passagem bem suave (o padrão era bem mais dura). Não precisa de textura de degradê. Pra borda ainda mais larga: pincel com **Strength** menor nas bordas ou a ferramenta **Spray**.
- **Grama caída no chão**: testada (sprites 0100/0101 deitados, em 3 cores) e tirada.

## Flores (`FlowerField`, `scripts/vegetation/flower_field.gd` + `shaders/nature/flower_card.gdshader`, trazidos do projeto antigo)

- Tufos de flores em PNG (`assets/textures/vegetation/flowers/`, gerados por `tools/gen_flower_textures.py`) em cartas cruzadas, balançando com o vento.
- Tipos: **branca baixinha** (quase rente ao chão, a mais comum: 3 de 6 montes), **azul** com caule, **rosa** com caule e **vermelho pastel em espiga reta**. Caule no verde da grama.
- **Onde nascem** (`placement`): a **branca baixinha só no chão** (fora da grama); **azul, rosa e vermelha só no meio da grama**. A grama é a mesma mancha de ruído da semeadura (seed 11, frequência 0,09, limite 0,06).
- **Montes de um tipo só** (nunca misturar cores no mesmo monte): 45 montes em 36 × 36 m. Altura por tipo (`size_scales`: branca 0,45, azul/rosa 0,75, vermelha 0,85).

### Ajuste 2026-10-25
- Flores maiores (flor e caule): `size_scales` 0,7 (branca) / 1,15 (azul, rosa) / 1,3 (vermelha). A branca fica colada no chão (flores a 84–92% da altura da carta, caule escondido).
- Tufo de grama mais fino e pontudo: `CYL_RADIUS` 0,75, `CYL_TIP` 4,5 (ponta em cone fino), lâminas espalhadas num raio de 0,2 m (menos coladas).

### Ajuste 2026-10-25 (2)
- Flores viradas pra cima (câmera isométrica): as cabeças ficam numa carta DEITADA (`flowers_<tipo>.png`, vista de cima). Tipos com caule ganham `flowers_<tipo>_stem.png` em cartas cruzadas e a carta das flores fica a 72% da altura; a branca fica rente ao chão (3 cm).
- Tufos menos colados: `grass_spacing` 0,45.
- Teste: tufo SEM borda (`next_pass` tirado de `grass_tuft.tres`; o `grass_tuft_outline.tres` continua guardado). Pra voltar a borda, põe ele de novo em `next_pass`.

### Ajuste 2026-10-25 (3)
- `grass_spacing` de volta a 0,26 e borda de volta (`next_pass`).
- Lâminas dentro do tufo menos coladas: pés a no mínimo 7 cm (`CYL_GAP`), raio do tufo 0,24 m, menos lâminas (`CYL_BLADES` 0,5), mais inclinadas pra fora.
- Branca maior: `size_scales` 0,95.

### Ajuste 2026-10-25 (4)
- Tufo opaco de novo (tirado o teste de opacidade 0,8); `grass_spacing` 0,27.
- Flores com caule: CADA flor (não só o centro do monte) precisa estar `grass_margin` (0,12) pra dentro da mancha de grama, onde ela é densa e alta; o caule não aparece mais na borda.
- Caule das flores mais grosso (2,6 px).

### Ajuste 2026-10-25 (5)
- Caule fino de novo (1,6 px) com efeito chiclete: escurece (`stem_dark` 0,45) e some (`stem_alpha_base` 0) indo pro pé. Shader próprio `flower_stem.gdshader` (transparente); corpo comum em `flower_card.gdshaderinc`.
- Branca bem maior (`size_scales` 1,3) e mais espaçada (menos flores, mais afastadas na textura).
- `grass_margin` 0,2: flores com caule mais pro meio da grama.

### Teste 2026-10-25: tufo 2D
- Novo `grass_tuft_2d` (mesh 2 do pincel, "Tufo 2D"): lâminas CHATAS de 5 pontos, dos dois lados, como o tufo do jogo antigo (`gen_models.py`). Mais leve que o de cilindros. Material `grass_tuft_2d.tres` (mesmo corpo, `cull_disabled`, sem borda).
- O terreno semeia com ele (`grass_mesh_ids` = 2 na cena). O tufo 3D (mesh 0) continua no pincel: pra voltar, `grass_mesh_ids` = 0.

### Cor da grama 2026-10-25
- Degradê em 3 tons no `grass_body`: pé no verde do chão (`base_color` #91BE01) → verde-amarelo (`mid_color` 0.65,0.72,0.1, em `mid_pos` 0,5) → ponta amarelo suave e mais escuro (`tip_color` 0.76,0.7,0.28; claro demais brilha com muitos tufos juntos). A divisa entre os tons ondula por ruído (`paint_wobble` 0,18, `paint_scale` 0,35 m), como tinta aquarela. Vale pros tufos 2D e 3D; o raminho fica sem ondulação.

### Grama do jogo antigo no tufo 2D (2026-10-25)
- `grass_tuft_2d.tres` agora usa `shaders/nature/grass_old.gdshader`: cópia do `wind_sway_body` do projeto-noite-old (GrassField `stylized`). Cores da ÁREA DE TESTE antiga (test_area.tscn, GrassField): base (0.55,0.78,0.3) → ponta (0.88,0.96,0.58), multiplicado por manchas de ruído (FastNoise 0,02, 20 m), rim azulado, translucidez amarela na ponta (`veg_backlight` 0,4 e `veg_rim_scale` 0,5 fixos no shader, no antigo vinham do BotwPost) e luz do `shaders/includes/toon_light.gdshaderinc` (copiado).
- O tufo 3D (`grass_tuft.tres`, `grass_body`) não mudou.

### Verde da referência (2026-10-25)
- Tufo 2D voltou pro `grass_body` (`grass_tuft_2d.gdshader`); o `grass_old.gdshader` ficou guardado sem uso. Cores pela foto de referência (grama lima saturada): pé verde fechado (0.27,0.47,0.04) → meio lima (0.55,0.76,0.08) → ponta verde-amarelo vivo (0.8,0.92,0.22), aquarela leve (`paint_wobble` 0,08).

### Tufo 2D refeito pela print (2026-10-25)
- Lâminas em pé (abrem no máx. 5 cm), chatas, largas no pé e afinando até a ponta, curvinha suave pra frente (5 alturas por lâmina: `BLADE_T`/`BLADE_W`). 26 lâminas, 0,34–0,58 m.
- Degradê liso sem aquarela (`paint_wobble` 0): pé verde (0.3,0.5,0.07) → meio (0.46,0.68,0.13) → ponta verde claro (0.62,0.82,0.3). Nada de amarelo vivo.

### Tufo do jogo antigo (2026-10-25)
- `assets/models/grass_old/grass_tuft_A/B.gltf` (+ .bin) copiados do projeto-noite-old (`tools/gen_models.py` de lá), sem a textura atlas (o shader pinta). Meshes 3 e 4 do pincel ("Tufo antigo A/B"), com sombra ligada (`cast_shadows` 1).
- Material `grass_old_tuft.tres` = `grass_old.gdshader` (shader do jogo antigo) com as cores da área de teste: base (0.55,0.78,0.3) → ponta (0.88,0.96,0.58), manchas de ruído, rim, luz toon_light.
- O terreno semeia com eles (`grass_mesh_ids` = 3, 4). Os tufos 3D (0) e 2D (2) continuam no pincel.
