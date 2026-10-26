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

### Tufo estrela (2026-10-25)
- Removidos os tufos A/B do jogo antigo, o `grass_old.gdshader` e o `toon_light` (vieram do outro projeto).
- Novo `grass_star` (mesh 3, "Tufo estrela", `tools/gen_grass_tufts.py`): 4 cartas em pé cruzando no centro (estrela de 8 pontas vista de cima), cada carta um pente de 16 lâminas finas em leque, mais altas no meio. De qualquer ângulo da câmera isométrica sempre há carta de frente: volume com poucos triângulos.
- Material `grass_star.tres` (`grass_body`, dois lados, sem borda): verde levemente escuro no pé (0.34,0.52,0.14) → (0.5,0.67,0.2) → verde-amarelado suave (0.7,0.79,0.32), aquarela leve (`paint_wobble` 0,12).
- Terreno semeia com ele (`grass_mesh_ids` = 3). Tufos 3D (0) e 2D (2) guardados no pincel.
- Balanço/dobra/toque: mesmos do `grass_body` (vento global, rajada com `bend_limit`, jogador achata). `sway_height` 0,28 (tufo mais baixo: as lâminas curtas das pontas também balançam).

### Grama billboard estilizada (2026-10-25) — substitui as cartas em estrela
Pesquisa na internet (godotshaders "Stylized Cartoon Grass" e "Billboard Grass with Wind", série de grama do hexaquo.at, devlogs estilo Ghibli):
- Grama estilizada pra câmera fixa de cima: **carta billboard em Y** (vira sempre pra câmera). Com câmera fixa o truque não aparece; de lado a carta nunca vira "risco".
- **Pé da grama = cor do chão** naquele ponto e ponta mais clara: o tufo some dentro do chão, sem emenda (o Stylized Cartoon Grass usa a cor do terreno vista de cima no pé).
- **Lâminas brancas no PNG**, cor toda no shader (degradê pé → ponta + ruído no mundo).
- **Normal pra cima**: a grama recebe a mesma luz do chão (evita o tufo escuro/claro conforme gira).
- Alpha scissor, muitos tufos pequenos por MultiMesh (aqui o instancer do Terrain3D); lâminas pontudas combinam mais com o estilo Ghibli.

Implementado:
- Atlas `assets/textures/vegetation/grass/grass_clumps.png` (`tools/gen_grass_card_textures.py`): célula 0 = tufo cheio (11–14 lâminas em leque), célula 1 = tufo de borda (4–5 lâminas, mais baixo).
- Meshes 4 `grass_bb_full` e 5 `grass_bb_edge` (um quad cada). Material `grass_billboard.tres` (`grass_body` com `billboard` + `use_sprite`): pé = verde do chão #91BE01, ponta (0.76,0.88,0.32), aquarela leve.
- Só 2 tipos: `grass_mesh_ids` = 4 no meio, `edge_mesh_ids` = 5 onde a densidade < `edge_density`.
- Removidas as cartas estrela/meia estrela/leque (`grass_card_*`, `grass_blades.png`).

### Tufo cheio + raminho billboard (2026-10-26)
- Por que o tufo parecia vazio de cima: uma carta só é uma faixa reta; vista de cima sobra chão em volta. Solução (pesquisa: hexaquo.at grass series parte 2 — várias lâminas/cartas por tufo em posições e alturas diferentes, pé afundado): o tufo agora tem VÁRIAS cartas billboard em lugares diferentes — cheio = 4 cartas (centro + 3 em volta, alturas variadas, espelhadas), borda = 2. Cada carta vira pra câmera em volta do PRÓPRIO centro (`UV2` = x, z do pé; shader `grass_body` `billboard`). Pé afundado 3 cm. Atlas cheio com 15–18 lâminas.
- Cor um tiquinho mais escura: pé (0.53,0.7,0.01), ponta (0.7,0.82,0.28).
- Raminho branco: novo `grass_sprig_bb` (mesh 6, "Raminho billboard"): o PNG `sprig_0093` (Kenney Shaded) numa carta billboard com o mesmo shader da grama (vento, jogador, `sprite_alpha` 0,85–0,95), tons brancos. O raminho 3D (mesh 1) continua guardado. `sprig_mesh_ids` = 6.

### Tufo 3D leve pra isométrica (2026-10-26) — substitui os billboards no terreno
- Billboard/carta 2D reprovado: de cima dá pra ver que é um plano. Volta pra lâminas de geometria (como o tufo do jogo antigo), com direção FIXA no mundo.
- `grass_iso_full` (mesh 7, 22 lâminas) e `grass_iso_edge` (mesh 8, 10 lâminas, mais baixo e mais deitado) em `gen_grass_tufts.py` (`ISO`):
  - lâminas INCLINAM PRA FORA 25–45° (borda 35–55°): de cima a câmera vê a face das lâminas abrindo em roseta, não o fio; o tufo cobre um disco;
  - curva (a ponta deita mais que o pé), leve torção por lâmina;
  - normal de "cúpula" (pra cima + pra fora do centro): luz lisa no tufo todo;
  - leve: 5 pontos por lâmina, ~7 triângulos.
- Material `grass_iso.tres` (`grass_body`, dois lados): mais escuro que o billboard — pé (0.4,0.58,0.05) → (0.48,0.66,0.1) → ponta (0.6,0.76,0.2).
- `grass_mesh_ids` = 7, `edge_mesh_ids` = 8. Billboards (4, 5, 6) guardados no pincel.

### Borda no tufo iso + raminho 3D shaded (2026-10-26)
- Tufo iso com borda (`next_pass` `grass_iso_outline.tres`, mesmos parâmetros de vento, `sway_height` 0,3). Lâminas agora com dois lados; como a normal da luz é de "cúpula", a casca da borda usa a normal da FACE guardada em `COLOR.gba` (`outline_face_normal` = true no `grass_body`).
- Raminho branco de volta ao 3D (`sprig_mesh_ids` = 1). Shaded: 45% das folhas mais escuras (tom 0,68–0,78 no `COLOR.r`, `shade_amount` 1) e transparência `sprite_alpha` 0,4–0,5. O billboard (6) fica guardado.

### Lâmina do tufo iso pelo PNG de referência (2026-10-26)
- Lâmina: pé largo e reto até ~1/3, afina em curva até a ponta fina (`ISO_T`/`ISO_W`), curva pra um lado sorteado (reta no pé, deita na ponta, 8–32°; borda 15–40°). 30% das lâminas saem em par do mesmo pé (a segunda menor, abrindo pro outro lado). Tons Shaded (`DARK_CHANCE`).
- Pés soltos, não em círculo: 3–4 grupinhos sorteados numa área de 0,2 m (borda 0,16 m).
- Menos lâminas por tufo e mais tufos (2026-10-26): cheio 11 lâminas (área 0,14 m), borda 5 (0,12 m); `grass_spacing` 0,19 (era 0,27).
- De novo (2026-10-26): cheio 7 lâminas (0,11 m), borda 3 (0,09 m); `grass_spacing` 0,14.

### Campo meio a meio pra comparar (2026-10-26)
- Campo maior: `grass_area` 50 m (era 36); flores em `area_half_size` 25.
- Metade x < 0: tufos de lâminas chatas (7 cheio, 8 borda), `grass_spacing` 0,14. Metade x ≥ 0: tufo 3D de cilindros (mesh 0) com `right_spacing` 0,27 (`right_mesh_ids` no Terrain3D; vazio = campo todo igual).
- Tufo 3D voltou ao formato original (antes do "mais fino e pontudo"): raio 0,14, `CYL_RADIUS` 1,2, ponta de bico arredondado `CYL_TIP` 2,4, sem `CYL_GAP`.
- Otimização (2026-10-26): `grass_area` 40 m (flores 20); tufo 3D com menos lâminas (`CYL_BLADES` 0,4 → 6–7 lâminas) e ponta um pouco mais pontuda (`CYL_TIP` 3,2).

### Tufo iso em 3D (2026-10-26) — metade direita
- `grass_iso3d_full` (mesh 9) e `grass_iso3d_edge` (mesh 10): mesmo arranjo do tufo de lâminas chatas (mesma seed: pés, curvas, pares iguais), mas cada lâmina vira um tubo de 5 lados seguindo a linha do meio, raio = meia-largura × 0,75, fechando na ponta. Material `grass_tuft.tres` (cor e borda do tufo 3D).
- Metade x ≥ 0: `right_mesh_ids` = 9, `right_edge_mesh_ids` = 10 (novo), `right_spacing` 0,14. O tufo de cilindros antigo (mesh 0) fica guardado no pincel.
- Ajuste (2026-10-26): `grass_area` 32 m (flores 16); metade 3D mais espaçada (`right_spacing` 0,2); tufo iso 3D mais em pé (`ISO3D_TILT` 0,4 da inclinação) e mais gordo (`ISO3D_ROUND` 1,1).
- Metade direita de volta ao tufo de cilindros original e redondo (mesh 0: `CYL_BLADES` 0,6, `CYL_TIP` 2,4, `right_spacing` 0,27). Tufos iso 3D (9, 10) guardados no pincel.

### Tufo de cilindros: 7 lâminas soltas, ponta fechada e tufo de borda (2026-10-26)
- `grass_tuft`: exatamente 7 lâminas, raio 0,17 m. Cada pé é sorteado até ficar SEPARADO dos outros (distância ≥ soma dos raios dos tubos + `CYL_GAP` 0,015 m); se não couber, o raio do tufo abre aos poucos. Altura e grossura continuam variando por lâmina.
- Ponta fechada num ponto (último anel com raio 0): sumiu o furinho/bolinha no topo.
- Novo `grass_tuft_edge` (mesh 11, "Tufo borda"): 4 lâminas, mais baixas e finas, raio 0,13 m. Metade direita: `right_edge_mesh_ids` = 11.

## ESTADO ATUAL DA GRAMA (2026-10-26) — vale este bloco, o histórico acima é só registro
- Só um tipo de grama: tufo de lâminas-cilindro (`grass_tuft`, mesh 0) + tufo de borda (`grass_tuft_edge`, mesh 2) + raminho branco 3D (`grass_sprig`, mesh 1). Removidos: tufo 2D, estrela, cartas, billboards, tufos iso (chato e 3D), atlas `grass_clumps`, `grass_tuft_2d.gdshader`, `gen_grass_card_textures.py`. O corte meio a meio saiu.
- `grass_tuft`: 6 lâminas soltas (nunca coladas: `CYL_GAP`), raio 0,16 m; borda: 3 lâminas, mais baixas, raio 0,12 m. Ponta mais fina (`CYL_TIP` 3,6), fechada num ponto.
- Cor (a do tufo de lâminas chatas): pé (0.4,0.58,0.05) → (0.48,0.66,0.1) → ponta (0.6,0.76,0.2), aquarela 0,1.
- Opacidade igual à do raminho: `sprite_alpha` 0,4–0,5 sorteada por tufo (`SPRITE_ALPHA`), inclusive na borda (`grass_outline` com o mesmo sorteio).
- Campo: `grass_area` 26 m, `grass_spacing` 0,27; flores `area_half_size` 13.
- Correção (2026-10-26): a transparência de verdade piscava claro/escuro andando (o Terrain3D ordena os blocos de grama transparentes por distância e a ordem troca). Agora a grama é OPACA com transparência falsa (`fake_alpha` no `grass_body`): a cor (e a da borda) é misturada com a cor do chão (`ground_color` #91BE01) pela mesma opacidade sorteada por tufo (`sprite_alpha` 0,4–0,5). O raminho continua transparente de verdade (são poucos).
- Raminho só no meio das manchas: `sprig_min_density` 0,7 (antes podia nascer na beirada rala, longe da grama).

### Flores no Terrain3D (2026-10-26)
- O nó `FlowerField` (e `scripts/vegetation/flower_field.gd`) saiu: as flores agora são meshes do pincel do Terrain3D, semeadas pelo `terrain_flat_start.gd` (`_seed_flowers`), então aparecem no editor e dá pra pintar/apagar com a ferramenta Instancer.
- Malhas (`tools/gen_flower_meshes.py`, `assets/models/flowers/`): `flower_head_low` (carta deitada a 3 cm), `flower_head_high` (carta deitada a 0,72), `flower_stems` (2 cartas cruzadas). Materiais em `assets/materials/flowers/` (`head_<tipo>` com `flower_card`, `stem_<tipo>` com `flower_stem`).
- Ids: 3 branca, 4/5 azul (flor/caule), 6/7 rosa, 8/9 vermelha. Cada flor com caule usa o MESMO transform nas duas malhas.
- Regras: montes de um tipo (45 montes, 4–10 flores, raio 0,9 m, pesos branca 3 : 1 : 1 : 1); com caule só onde a densidade da grama ≥ 0,8 (bem dentro); a branca só fora da grama.
- Ajuste (2026-10-26): flor rosa fora do campo (ids 6/7 continuam no pincel); grama sem a opacidade (`fake_alpha` = false); tufo com 5 lâminas mais grossas (meia-largura 0,037–0,06; borda 0,032–0,05); menos tufos (`grass_spacing` 0,34).

### Flores: borda, prioridade e movimento da grama (2026-10-26)
- Borda nas flores (carta das flores): no `flower_card.gdshaderinc`, pixel vazio a até `outline_px` (3) pixels de uma pétala vira contorno `outline_color` (0.3,0.42,0.1). Caule sem borda.
- `render_priority` 1 nos materiais `assets/materials/flowers/*` (só vale entre transparentes: o caule; a carta das flores é recorte opaco e fica por profundidade).
- Movimento igual ao da grama: balanço em oval, dobra com rajada (rigidez e onda próprias por flor, `bend_limit`), jogador abre e achata — tudo pela origem de cada flor, então cada uma balança separada. Pela altura (y): flor e caule (mesmo transform) andam juntos.
- Borda das flores na cor da própria flor (pétala vizinha × `outline_shade` 0,8); a branca do chão sem borda (`outline_px` 0 no `head_white`).
- Topo da borda da grama arredondado: `outline_round` 2,5 (casca engorda pros lados e sobe perto da ponta, fecha em cúpula).
- Pé da grama mais claro (2026-10-26): `base_color` (0.52,0.7,0.1), `mid_color` (0.56,0.74,0.14); ponta igual.
- Correção (2026-10-26): o arredondado era o TOPO DA LÂMINA, não a borda. `outline_round` saiu; lâmina com topo em meia esfera (`CYL_TIP` 1, raio = √(1−t²), normais de esfera). A borda segue o topo redondo.
- Ponta da lâmina voltou a ser fina (`CYL_TIP` 3,6). Onda de luz dourada também nas flores com caule (azul, rosa, vermelha: flor e caule, `shimmer_strength` 0,6, mesma conta e valores da grama); a branca do chão sem.
- Ajuste (2026-10-26): topo mais redondo (`CYL_TIP` 2,6, perfil (1-t^1,8)^0,55), lâminas ~15% mais grossas (0,043-0,069; borda 0,037-0,058), menos tufos (`grass_spacing` 0,39).
