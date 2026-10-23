# Dia, noite e clima

> **Em refação.** O **vento** é o que vale hoje; paleta, saturação, ciclo dia/noite e chuva serão refeitos para o estilo de [07-estilo-visual.md](07-estilo-visual.md).

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Visual: [06-pos-processamento.md](06-pos-processamento.md)

## Ciclo de dia e noite

**Onde está implementado:** só na cidade (`scenes/levels/city/city.tscn`), no nó `WeatherCycle` (`scripts/weather/weather_cycle.gd`).

### Regras

- **Toda vez que se entra na cidade, é dia claro.** O ciclo recomeça do zero (`start_phase = 0`).
- O ciclo vai de **dia → manhã/meio-dia → tarde (laranja) → noite** em **1 minuto** (`cycle_duration = 60`), valor de teste.
- **Ao chegar na noite, para.** Não volta a amanhecer sozinho (por enquanto).
- Os postes da rua ficam **apagadas de dia**, começam a acender na tarde e ficam no máximo à noite.

### Fases (porcentagem do ciclo)

| Fase | Trecho | Céu | Luz principal | Clima da cena | Lanternas |
|---|---|---|---|---|---|
| Dia | 0–35% | `skybox-day.png` | branca-quente, alta (−60°), 1,0 | verde/cor vivos, **sem névoa** | apagadas |
| Fim de tarde (dourado) | 35–55% | dia → tarde | dourada **forte** (1,05), descendo (−25°) | "hora dourada": quente e vivo, sem névoa | 20% |
| Tarde | 55–70% | `skybox-morning.png` (tom laranja-pêssego) | pêssego, baixa (−12°) | laranja **suave**, sem névoa | 50% |
| Anoitecer | 70–90% | tarde → noite | vira luar azul-lavanda, 0,8 | **névoa vai surgindo** (azul-marinho) | 100% |
| Noite | 90–100% | `skybox-space-nebula.png` (o céu noturno que já existia) | luar | igual à noite do outside | 100% |

Entre as fases, tudo é interpolado suavemente: céu, luz, ambiente, névoa, glow, saturação e sombra das nuvens. A progressão é **sempre gradual** (dia → dourado → pêssego → noite), sem nenhuma fase "pular" pra uma cor bem mais forte que a anterior.

### Árvores: a "parte branca girando" (resolvido)

Causa: o **halo de borda do `PlasticApplier`** (`rim_overlay`) era aplicado nas árvores antes do `WindApplier` trocar o material pelo de vento. O halo ficava **parado** enquanto a árvore **balançava**, e a parte clara parecia girar/alternar de lado. Agora vegetação (tree, bush, grass, flower, foliage, plant, leaf) **não recebe o halo** (já tem a borda clara própria no `wind_sway`, que balança junto). As tentativas anteriores (balanço só vai-e-vem, copa sem receber sombra) foram desfeitas.

### Sol: caminho curto no céu

O ângulo do sol vai de −52° (manhã) a −32° (tarde) e a lua fica no ângulo da cena. Antes ia de −60° a −12° e voltava a −37° na noite: com o ciclo de 60 s, o lado iluminado das árvores (a "parte clara") **parecia girar**. É o sol andando; só ficou mais contido.

### Regra: a tarde é laranja puxando pra roxo

A tarde não é só laranja: é **laranja com roxo**, pra ter cara de fim de tarde.

- **Sol** laranja (dourado 1 / 0,66 / 0,42 → tarde 1 / 0,55 / 0,42).
- **Luz ambiente roxa** (dourado 0,78 / 0,56 / 0,72 → tarde 0,62 / 0,44 / 0,74): as sombras e o lado sem sol ficam arroxeados enquanto o lado do sol fica laranja.
- **Céu**: a skybox laranja ganha um **degradê pro roxo no alto** (`dusk_top_tint` no `day_night_sky.gdshader`; horizonte laranja, topo roxo).
- Sombra das nuvens e névoa do anoitecer puxam pro roxo também.

### Regra: a noite é a noite do outside

**A noite da cidade é idêntica à noite do `home/outside`** (mais azulada): mesmo céu (`skybox-space-nebula`, energia 0,6), mesma lua (cor, força 0,8, ângulo original da cena), ambiente 0,4/0,44/0,65 a 0,45 vindo do céu, névoa 0,008 / altura 0,45, glow 0,7, saturação 1,3, contraste 1,12, **sem LUT**.

**O dia é uma adaptação dessa noite:** mesmo pacote (AgX, SSAO, glow, saturação, tilt-shift), só trocando céu, luz e névoa. **Saturação: dia 1,5 → tarde 1,45/1,4 → noite 1,3** (o dia é mais saturado, pedido do usuário; a noite fica igual ao outside). Contraste 1,12 em todas. A LUT do `ColorGrade` está **desligada** (força 0 em todas as fases), pra não somar saturação além da noite; dá pra religar pela chave `grade` no `KEYS`.

**ReflectionProbe acompanha o ciclo:** ele captura o céu uma vez só por padrão; se fosse capturado de dia, a cidade refletiria o céu claro a noite toda (fica mais clara que o outside). O `WeatherCycle` deixa o probe em `UPDATE_ALWAYS` enquanto a hora muda e volta pra `UPDATE_ONCE` na noite.

**Sem piscar nas transições:** (1) o céu **não troca mais de material** na noite (a troca do shader pelo `PanoramaSkyMaterial` recalculava a luz do céu de uma vez e piscava); o shader na noite já mostra a mesma nebulosa com a mesma energia (0,6) do outside. (2) O `update_mode` do `ReflectionProbe` só é atribuído quando muda (reatribuir todo frame reiniciava a captura).

~~**Céu da noite = o do outside:** a partir de 90% do ciclo o `WeatherCycle` troca o shader de mistura (`day_night_sky.gdshader`) pelo **mesmo `PanoramaSkyMaterial` do outside** (`OutsideNightSkyMaterial`: nebulosa, energia 0,6) e põe o `Sky` no modo automático, igual ao outside. Nesse ponto o shader já mostra só a nebulosa, então a troca não aparece.~~ (removido)

### Regra visual: paleta BotW (`palette = BOTW`)

O estilo do jogo agora é o do **Breath of the Wild** ([07-estilo-visual.md](07-estilo-visual.md)): vivo mas lavado, sombra clara, noite azulada e legível. O `weather_cycle.gd` tem duas paletas: `VINIL` (`KEYS`, antiga, ainda nas cenas não migradas) e `BOTW` (`KEYS_BOTW`, cena nova). Na BotW:

- Saturação 1,5 de dia, 1,4 à tarde, 1,45 à noite; contraste 0,92 o ciclo todo (a noite não "apaga").
- Luz ambiente do céu forte de dia (sombra clara); `shadow_op` (opacidade da sombra) 0,55 / 0,5 / 0,4.
- Glow baixo (0,15 de dia, 0,2 à noite); névoa clara de dia (0,005).
- Noite = a do outside (luar azulado de lado, −37°, névoa azul-escura baixa), um pouco mais clara.
- Vagalumes vão surgindo do fim da tarde até a noite (`firefly_fx`).

### Efeitos de cena na cidade

A cidade segue [06-pos-processamento.md](06-pos-processamento.md) igual ao outside: AgX, SSAO (power 1,3, light affect 0,3), glow em todos os níveis, névoa por altura, tilt-shift, **sombra de contato** (`ContactShadows`, em carros, bancos, hidrantes e postes), **sombra das nuvens** (`CloudShadows`, a cor muda com a hora) e **riscos de vento** (`WindStreaks`).

### Skyboxes

Ficam em `assets/skyboxes/`:

- **Dia:** `basic/skybox-day.png`
- **Tarde (laranja):** `basic/skybox-morning.png`
- **Noite:** `basic/skybox-night.png` (noite azul com nuvens e lua). **Só o outside/calm_place usa a nebulosa espacial** (`space/skybox-space-nebula.png`); o ciclo de dia usa a noite "basic".

O céu usa o shader `shaders/weather/day_night_sky.gdshader`, que mistura os três panoramas pelos pesos `dusk_weight` e `night_weight`. O `Sky` está em `process_mode` tempo real pra luz ambiente acompanhar a mudança.

**Importante:** o `Environment` precisa de `fog_sky_affect = 0`. Senão a névoa pinta o céu inteiro com a cor dela e a skybox some (vira só azul-marinho).

### Postes da cidade

Os postes da cidade **não usam a luz das lanternas do calm_place** (`lantern_pulse.gd`, chama a fogo tremulando). Na cidade é poste elétrico: `scripts/weather/street_lamp.gd`, luz fixa branco-quente, grupo `street_lamps`, acende/apaga pela `intensity` do ciclo.

### Como ajustar

- Duração: `cycle_duration` no nó `WeatherCycle`.
- Começar em outra hora (pra testar): `start_phase` (0 = dia, 1 = noite).
- Cores e tempos de cada fase: tabela `KEYS` no topo do script.

## Regra: o Calm Place não tem ciclo de dia

**O `calm_place` (outside e inside_house) é sempre noite.** Não tem `WeatherCycle`, nem manhã/tarde, nem chuva por enquanto. O ciclo de dia e noite (e tudo desta seção: nuvens, folhas, chuva) é das áreas com sistema de dia (área de teste, cidade e as próximas).

## Efeitos de dia: nuvens, folhas e vento

O contrário dos efeitos noturnos (vagalumes e névoa). Controlados pelo `WeatherCycle._apply_day_fx()` pela hora:

| Efeito | Manhã/tarde | Noite | Chuva | Onde |
|---|---|---|---|---|
| **Nuvens passando** (sombra no chão) | sim | some | continua | `DriftingClouds` (`scripts/weather/drifting_clouds.gd`), grupo `cloud_fx` |
| **Folhas voando** | sim | some | some | `WindLeaves` (`scripts/weather/wind_leaves.gd`), grupo `day_fx` |
| **Riscos de vento** | 100% | **35%** (`night_wind`) | some | `WindStreaks`, grupo `wind_fx` |

- **Nuvens:** **3** nuvens (poucas), **devagar** (0,5 m/s), a 7 m de altura, **posicionadas compensando a inclinação do sol** (com o sol baixo da tarde a sombra cai longe da nuvem; a nuvem fica deslocada pro lado do sol pra sombra cair em volta do jogador), de 12–26 m (**tamanho aleatório**) com **sombra de verdade**: cada uma é um plano **invisível** a 9 m de altura que só projeta sombra, então a sombra é **a mesma sombra do sol que os objetos fazem**. **Posição aleatória em volta do jogador**: nascem perto dele (no começo em qualquer ponto até 30 m; depois do lado de onde vem o vento) e andam com o vento pelo mundo; ao ficar a mais de 30 m dele, renascem em outro ponto perto, com outro tamanho/rotação. **Forma de nuvem**: corpo central + 6–9 **gomos** em volta do contorno, unidos em curvas lisas (contorno com curvas, não um círculo espichado). **Borda lisa**: a forma é **calculada no shader** (`shaders/weather/cloud_shadow.gdshader`, gomos passados como uniform), com precisão de pixel; com textura esticada por 20+ m a borda ficava serrilhada/rugosa. **A nuvem anda pelo chão (ponto da sombra)** e a posição no céu é recalculada pelo sol a cada frame: na troca de período a sombra não pula, não volta nem renasce (antes piscava). No anoitecer **encolhem até sumir** (o recorte nítido não tem transparência; sumir de vez parecia piscada).
- **Folhas e lâminas de grama:** `WindLeaves` (`scripts/weather/wind_leaves.gd` + `shaders/weather/wind_leaf.gdshader`) cria **uma camada de partículas por tipo**, então cada partícula é uma folha só (o atlas juntava as duas imagens): 6 de cada **folha estilizada** gerada por `tools/gen_leaf_textures.py` (`assets/textures/effects/leaves/`: `leaf_round`, `leaf_pointed`, `leaf_maple`: cor chapada em dois tons e nervura, **sem contorno**, no estilo do jogo; as fotos realistas destoavam e saíram do projeto) + 20 **lâminas de grama** (`grass_blade.png`, gerada pelo mesmo script: fina, reta, pontuda, dois tons de verde). Tamanho sorteado (0,25 m × 0,6 a 1,7). **Fade in e fade out**. **Deitadas** (plano horizontal, não em pé), direção sorteada, **não giram no próprio eixo**: **ondulam** no ar (shader) e sobem/descem com a turbulência. Lâminas de grama **finas** (0,1 da largura da folha). **Fade in/out de verdade**: o shader não usa recorte de alpha (o recorte fazia a folha aparecer/sumir de uma vez). **Mesmo visual da grama fina**: o `wind_leaf.gdshader` pinta a folha no degradê da grama estilizada (base 0,35/0,62/0,22 → ponta 0,86/0,98/0,5; o claro/escuro da imagem vira base/ponta), com a mesma borda clara (rim) e a mesma luz (inclusive toon). `grass_style` 0 volta pras cores da imagem. Folhas **moles**: o plano é subdividido e o shader dobra as bordas pra baixo e passa uma onda pela folha, devagar.
- **Vento = riscos que PASSAM** (área de teste): `WindTrails` + `WindTrailsLong` (`wind_streaks.gd`): 20 curtos de 3 a 10 m (rastro 0,8 s, velocidade 3,8–12,5 m/s) + 6 compridos (2,2 s), mais curtos que compridos, numa área de 22 × 16 m em volta do jogador (cobre a tela). Riscos com **ondulação leve** (quase nada: `curl` 0,01, `curl_size` 14; 0,05 e 0,02 pareciam flutuar). Nascem a 0,9 m ou mais: com a onda leve e voo sem subir/descer (`flatness` 1), nunca chegam no chão, bem compridos, **grossura variada mas fina** (0,04 a 0,15), a 0,6–2,4 m de altura, com **fade in/out lento** (~1,8 s pra surgir e ~1,8 s pra sumir; vida = rastro + 4 s). **Sem colisão com o chão**: o risco que encostava no chão sumia na hora, sem fade. O vento **passa**, não flutua. **Testado e removido:** fitas curvas do Vefects (`WindFlow`), riscos que faziam laço e faixas separadas com riscos grossos, lentos e ondulando (voltou ao anterior).
- **Outside:** usa os **mesmos riscos de vento** da área de teste (`WindStreaks` curtos + `WindStreaksLong`, em `outside_environment.tscn`) e a **poeira da noite** (`NightDust`, igual à da área de teste). Sem `WeatherCycle` lá: ficam sempre ligados.
- **Testado e desfeito (por enquanto):** brisa portada do Vefects Wind VFX (Unity): folhas/pétalas com mesh e textura do pacote pousando no chão, poeira e linhas de vento em fita. As texturas e meshes continuam em `assets/vfx/vefects_wind/` pra retomar depois.

### Noite na área de teste

Vagalumes **na área toda** (os copiados do outside cobrem ±15 m do centro; um segundo grupo, `FirefliesGreen`, cobre a área verde) e **poeira da noite** (`NightDust`: o mesmo `light_motes.gd` com `fx_group` = `night_fx`, 50 grãos azulados mais transparentes, seguindo o jogador). Os riscos de vento agora **nascem finos, engrossam e afinam até sumir** (curva de escala): o rastro não herda a transparência do histórico, então só a cor fazia o risco surgir de uma vez.

### Regra: partícula não entra no chão

Toda partícula que anda pelo cenário (folhas, lâminas de grama, poeira, riscos de vento, vagalumes) **colide com o chão**. A cena tem um `GPUParticlesCollisionHeightField3D` (`ParticleGround`, 48 × 12 × 48 m, segue a câmera). Folhas **encostam e ficam** (colisão rígida, sem quicar) até o fade do fim da vida; poeira, riscos e vagalumes **somem ao tocar** o chão.

### Mais efeitos de dia

| Efeito | Quando | Onde | Como |
|---|---|---|---|
| **Raios de sol** | manhã (sutil, 50%) → tarde (forte) | `SunRays` (`scripts/weather/sun_rays.gd` + `shaders/weather/sun_ray.gdshader`), na área verde | 7 faixas de luz aditivas (1,6 × 9 m) alinhadas com a direção do sol e viradas pra câmera, somem nas pontas e bordas, tremulam de leve; **cor do sol na hora** (dourado → laranja). Grupo `ray_fx`. |
| **Poeira no ar** | manhã (some até a tarde) | `LightMotes` (`scripts/weather/light_motes.gd`) | 130 grãos bege claro (0,045 m, **tamanho sorteado** de 0,3× a 2,6×), **sem brilho** (mistura normal, não aditiva), **bem visíveis** (transparência sorteada de 50% a 100%), flutuando e cintilando em volta do jogador. Grupo `morning_fx`. |
| **Ar tremendo de calor** | perto do meio-dia (fase ~0,1–0,5) | `tilt_shift.gdshader` (global `heat_haze`) | Ondulação **bem leve** da imagem (reduzida pela metade), mais no alto da tela. Global = 0 em cenas sem ciclo (o `WeatherCycle` zera ao sair da cena). |
| **Nuvens rosadas no fim de tarde** | tarde | `day_night_sky.gdshader` (`dusk_cloud_tint`, `dusk_cloud_amount` 0,6) | As partes claras (nuvens) da skybox da tarde puxam pro rosa, além do roxo no alto. |

| **Borboletas** | manhã e tarde | `Butterflies` (`scripts/weather/butterflies.gd` + `shaders/weather/butterfly.gdshader`), na área verde | 8 borboletas voando em zigue-zague perto do chão (~0,9 m), asas que dobram no meio batendo rápido (shader), cores sorteadas (branco, amarelo, laranja, azul-claro), projetam sombra, não entram no chão. Grupo `day_fx`. |
| **Pássaros** | manhã e tarde | `Birds` (`scripts/weather/birds.gd`, modelo `bird.gltf` do Pretty Park) | **Bando** de 1–3 a cada 14–26 s, **tamanho sorteado** (0,7× a 1×), cruzando o céu perto do jogador (6 m de altura, formação em V solta) com a **sombra cruzando o chão**; **pousados** (`perch_spots`) bicando e dando pulinhos, que **voam pra longe** quando o jogador chega a 2,5 m e voltam em 12 s. O modelo não tem asas animadas: o bater de asas é um balanço rápido. Grupo `day_fx`. |
| **Orvalho** | a manhã toda (some entre 30% e 45%, na passagem pra tarde) | `MorningDew` (`scripts/weather/morning_dew.gd`), na área verde | 35 estrelinhas brilhantes rentes às pontas da grama, cintilando (acendem e apagam em 1,6 s). Grupo `dew_fx`. |

Todos somem na chuva e à noite. Raios de sol com força máxima **0,3** (era 0,12, quase invisível).

## Clima

_A definir._ Tipos de clima (chuva, neblina, vento forte...), como e quando trocam.

## Efeito no jogo

_A definir._ Como hora e clima afetam jogador, inimigos, NPCs e visual.

## Sistema de clima (`WeatherCycle`)

O antigo `day_night_cycle.gd` virou **`scripts/weather/weather_cycle.gd`** (node `Weather` na área de teste; na cidade guardada o node ainda se chama `DayNightCycle`). Cuida do ciclo de dia/noite **e** da chuva. Tudo de clima fica em `scripts/weather/` (ver ARQUITETURA.md, "Organização por domínio").

## Chuva

**Referência de clima: Stardew Valley.** O dia chuvoso tem **identidade própria**: a cena inteira muda de cor (azulada, mais escura, menos saturada), não só "caem gotas". Dois tipos previstos:

| Tipo | Status | Ideia |
|---|---|---|
| **Chuva normal** | em andamento | gotas finas com **leve inclinação** pelo vento, respingos, chão molhado, tom azulado. **Sem raios, trovões nem vento forte** (isso é da tempestade); **os riscos de vento somem** enquanto chove (grupo `wind_fx`) |
| **Tempestade** | a fazer | mais gotas, mais rápidas e inclinadas, vento forte (grama e árvores balançando muito), céu bem escuro, relâmpagos (clarão na tela + luz) e trovão |

### Referência técnica: NIMBLUX Lite (gennai)

Pacote analisado (`free-rain-vfx-godot-4-lite`, Godot 4.4+). Valores da chuva média (`rain_steady`, `amount` 0,55):

| | NIMBLUX | Nosso `Rain` |
|---|---|---|
| Gotas | 9000 no máximo × `amount` (≈ 5000 na média) | 2700 |
| Área | caixa 24 × 14 × 24 m seguindo a câmera | 24 × 24 m, nascendo a 14 m, seguindo o jogador |
| Velocidade | 13 m/s, variação 20% | 13 m/s, ±20% |
| Gota | risco de 0,055 s de movimento (≈ 0,7 m) × 0,014 m de largura | palito 0,7 × 0,014 m alinhado com a queda |
| Cor | cinza-azulado (0,74; 0,79; 0,86), **55% opaco**, emissão 0,25 (brilha de leve no escuro) | igual, sem luz própria |
| Respingos | **ondas** (anéis no chão, 700, 0,45 m) + **coroas** (500, 0,22 m) num raio de 9 m, cor (0,78; 0,83; 0,9) 40% | a fazer |
| Truques | gotas ancoradas no mundo (a câmera andando não arrasta a chuva); fade perto da câmera e na borda da área; quantidade e comprimento do risco crescem com `amount` | a gota segue o jogador |

Licença do NIMBLUX Lite: uso livre em jogos (inclusive comercial), crédito opcional, **não pode redistribuir** o pacote. Por isso usamos só como **referência de valores**, não copiamos o código pro projeto.

### O que implementar (ordem recomendada)

1. **Tom de dia chuvoso (maior impacto, estilo Stardew):** ao chover, puxar a cena pra azul-acinzentado, escurecer e dessaturar; céu fechado (trocar/escurecer a skybox), sombras quase somem (luz difusa de céu nublado). Já tem: sol −45% e saturação −20%. Falta: tingir de azul (luz ambiente e cor da lua/sol azuladas) e apagar as sombras.
2. **Respingos no chão:** anéis que se expandem (ondas) + coroinhas de gota quicando, num raio em volta do jogador, como o NIMBLUX.
3. **Cenário molhado:** materiais ficam mais escuros e brilhantes (roughness ↓, albedo ↓) aos poucos enquanto chove, e secam devagar depois. Vale pro chão, pedras, madeira e telhados (não pra folhas, que ficariam com cara de plástico molhado).
4. **Poças:** manchas no chão (decal ou máscara de ruído) que refletem o céu e mostram as ondas dos respingos.
5. **Água escorrendo:** faixas de água descendo em paredes e telhados (shader de rolagem de textura) e pingos caindo das bordas dos telhados.
6. **Gotas na "lente" / vinheta de chuva:** opcional e sutil (risco de poluir a tela).
7. **Som:** chuva ambiente em loop, pingos mais perto, trovão (tempestade).
8. **Gameplay** (a definir em conjunto): chuva rega as plantas, NPCs ficam em casa, peixes diferentes, etc. (como no Stardew).
9. **Abrigo:** sem chuva sob telhados/dentro de casa (o NIMBLUX completo tem `NimbluxShelter3D`; aqui seria uma área que bloqueia as partículas).

### Regra: chuva é um clima à parte

**Enquanto chove, a hora não anda** (sem transição manhã → tarde → noite). O dia chuvoso é um estado próprio, com o tom dele, por cima da hora em que começou a chover. Quando a chuva para, o ciclo continua de onde estava. **Também não dá pra trocar a hora na mão**: `set_phase()` e `restart()` são ignorados enquanto chove, e os botões Reiniciar/Manhã/Tarde/Noite do painel ficam desativados. Pra testar a chuva em outra hora: desligar a chuva, trocar a hora, ligar de novo.

### Molhado com o toon

O molhado vale com o toon ligado ou desligado: o global **`weather_wetness`** (0..1, setado pelo `WeatherCycle`) é lido pelo material toon (cor 30% mais escura, brilho de água concentrado e água escorrendo nas paredes) e pelo `rain_streaks.gdshader`. A água escorrendo fica em `shaders/includes/rain_wet.gdshaderinc` (compartilhada). Sem toon, o `WetnessApplier` cuida dos materiais normais.

### Implementado (itens 1 a 5; som fica pra depois)

Tudo na área de teste, controlado pelo `WeatherCycle` (`set_raining()`; botão "Chuva" no painel). A chuva entra/sai em `rain_fade_time` (3 s); o **molhado** (`wetness`) sobe em `wet_time` (8 s) e **seca devagar** em `dry_time` (30 s) depois que para.

| # | O quê | Onde | Como |
|---|---|---|---|
| — | **Gotas** | `Rain` (`scripts/weather/rain.gd`) | Valores do NIMBLUX (tabela acima), seguem o jogador. Palito fino alinhado com a queda (`particle_flag_align_y`), **leve inclinação** pelo vento (`wind_lean` 0,25, ~14°). **Transparência variada por gota** (30% a 100% do alpha, `alpha_range`). **Testado e desfeito** (o usuário preferiu o palito): gota com cabeça redonda (shader), gotas maiores/mais rápidas nascendo a 30 m. |
| 1 | **Tom de dia chuvoso** | `WeatherCycle._apply_rain_tone()` | Por cima da hora atual, proporcional à chuva: luz do sol/lua e ambiente puxam pra **azul-acinzentado** (`rain_tint` 0,55/0,64/0,82, 60%), sol −45%, saturação −20%, **sombras quase somem** (`shadow_opacity` → 0,35, céu nublado), **céu de chuva próprio**: o `day_night_sky.gdshader` transforma a skybox da hora atual num céu **nublado cinza-escuro** (`rain_weight`: tira 85% da cor mantendo o desenho das nuvens, puxa pro cinza levemente azulado `overcast_color` e escurece 35%); funciona de manhã, tarde e noite, névoa leve azulada (0,006, também de dia). |
| 2 | **Respingos** | `RainSplashes` (`scripts/weather/rain_splashes.gd`) | Como o NIMBLUX: **ondas** (700 anéis deitados no chão que crescem até 0,45 m e somem em 0,6 s) + **coroas** (500 gotinhas que pulam ~0,22 m e caem em 0,28 s), raio 9 m em volta do jogador, cor (0,78; 0,83; 0,9) 40%. Grupo `rain_fx`. |
| 3 | **Cenário molhado** | `WetnessApplier` (`scripts/weather/wetness_applier.gd`) | Materiais normais (chão, pedra, madeira, paredes) ficam até 30% mais escuros e com roughness 0,15 (brilho de molhado). **Folhagem fica de fora** (nomes com leaf/tree/bush/grass/flower/plant/foliage). Ao sair da cena, devolve os materiais secos (são compartilhados). Grupo `wet_receivers`. |
| 4 | **Poças** | `Puddles` (`scripts/weather/puddles.gd` + `shaders/weather/puddles.gdshader`) | Plano 24 × 24 m rente ao chão; manchas de ruído que **crescem com o molhado** (até 38% do chão); escuras e lisas (roughness 0,03), refletem o céu pelo `ReflectionProbe`. Só pra chão plano. |
| 5 | **Água escorrendo** | `shaders/weather/rain_streaks.gdshader` (next_pass do `WetnessApplier`) | Só nas faces verticais: faixas finas de água descendo, em coordenadas do mundo (não depende da UV do modelo). Força pelo `wetness`. |

**Ainda a fazer na chuva normal:** pingos caindo da borda dos telhados; abrigo (não chover dentro de casa/sob telhado); som. **Tempestade:** tudo da tabela de tipos.

## Vento (sistema)

Proposta pra substituir o vento atual (`scripts/weather/wind.gd`: brisa + rajada em seno com tempo fixo), que ficou duro: a grama "amassa" (desce e estica) e vai e volta num ritmo fixo, sem transição natural. Mesma ideia do ciclo de dia e noite (acima): estados com transição suave.

### Problemas do atual

- Rajada é um seno de duração fixa: sobe, desce, para. Dá pra "sentir o timer".
- O shader **translada** os vértices pra frente e pra baixo: a lâmina encolhe/amassa em vez de dobrar.
- Grama volta na hora quando a rajada acaba (sem inércia).
- Riscos de vento só aceleram; não aparecem mais quando venta.

### Ideias

#### 1. Estados de vento (como dia/tarde/noite)
`CALMO` → `BRISA` → `VENTANIA`, cada um com força, frequência de balanço, quantidade de riscos de vento, folhas voando e poeira. O vento **escolhe o próximo estado** sorteado e **transita devagar** (10–30 s), nunca troca seco. Dura um tempo sorteado em cada estado (ex.: brisa 20–60 s).

#### 2. Força como ruído suave, não timer
A força instantânea = força do estado + ruído lento (Perlin no tempo). Rajadas viram **picos do ruído** com duração variável (5–10 s, nunca fixa), subindo rápido e caindo devagar (ataque curto, soltura longa), como vento de verdade.

#### 3. Frente de rajada viajando pelo campo
Cada rajada é uma **faixa** que entra por um lado e atravessa o campo na direção do vento (posição = velocidade × tempo). A planta só deita quando a faixa passa por ela: dá o efeito "onda na grama" do BotW, e plantas diferentes reagem em momentos diferentes.

#### 4. Dobrar em vez de amassar (shader)
Rotacionar a lâmina em volta da base (curva quadrática pela altura) mantendo o comprimento, em vez de somar deslocamento. A ponta faz arco; nada encolhe.

#### 5. Inércia/mola
A inclinação segue a força com atraso (amortecimento): demora um pouco pra deitar e **volta balançando** (pequeno overshoot), não estala de volta. Árvores com mais atraso que grama (são "pesadas").

#### 6. Partículas ligadas ao estado
Na ventania: **mais** riscos de vento (amount), mais rápidos e mais longos; folhas e grama voando em quantidade maior; poeira levantando do chão. Na calmaria: quase nada. Cada risco dura 5–10 s sorteado.

#### 7. Direção fixa (decidido)
O vento tem **sempre a mesma direção**: vem do noroeste da tela e vai pro sudeste, que é o sentido em que os riscos de vento já correm hoje (`wind_dir = Vector2(1.0, 0.3)` no mundo, com a câmera em yaw 40,5°). Combina com o enquadramento da câmera. Grama, árvores, partículas e folhas usam essa mesma direção; nada de variar a direção.

#### 8. Ligação com a hora
Manhã e tarde: o vento se comporta igual (mesmos estados e rajadas). Noite: mais calmo (menos força, rajadas raras e fracas).

#### 9. Debug
Botão no painel de clima: `Vento: calmo / brisa / ventania / auto`, como o da chuva.

#### 10. Depois
Áudio de vento seguindo a força; flores e pétalas soltando na ventania; som de folhas nas árvores.

### Ordem sugerida
1. Shader: dobrar + inércia (4, 5) — é o que mais tira o "duro".
2. Estados + força por ruído + duração variável (1, 2).
3. Partículas ligadas ao estado (6).
4. Frente viajando (3), na direção fixa (7).
5. Hora (noite calma) e debug (8, 9).

### Implementado (campo)

Itens 1, 2, 4, 5, 6, 7 e 8 + chuva. O item 3 (frente de rajada) **não** vai: os riscos de vento já fazem esse papel. Variar a direção ficou de fora: os riscos de vento são criados com a direção fixa, e a grama precisa bater com eles.

- **`scripts/weather/wind.gd`** (node `Wind`, grupo `wind_system`):
  - Estados `CALMO` / `BRISA` / `VENTANIA` (dobra, balanço, rajadas, riscos, velocidade). Cada um dura 20–50 s sorteado; a troca leva ~12 s (`transition_time`).
  - Próximo estado sorteado por peso: manhã e tarde iguais (25% calmo, 50% brisa, 25% ventania); noite puxa pro calmo (sem ventania); chuva puxa pra ventania.
  - Força = estado + ruído lento; rajadas são os picos do ruído (sem tempo fixo).
  - ~~Inércia~~: testada e removida (o usuário não gostou); a dobra segue a força direto.
  - Cada planta tem rigidez própria (30%–115%, sorteada pela posição) e um ruído lento: no vento umas deitam muito e outras pouco, nunca todas na mesma altura.
  - Partículas: riscos de vento (`wind_fx`) com quantidade e velocidade pela força (à noite metade, na chuva somem); folhas voando aceleram; poeira (`morning_fx`, `night_fx`) é levada na direção do vento (`dust_push`). Com um `Wind` na cena, o `WeatherCycle` não mexe mais na quantidade de riscos.
- **Shader** (`wind_sway_body.gdshaderinc`): globais `wind_direction` (fixa, `(1, 0.3)` no mundo = noroeste → sudeste na tela), `wind_strength`, `wind_gust` (grama), `wind_gust_slow` (árvores). A planta **dobra** girando em volta da base (`bend_max` 1,1 rad na grama, `tree_bend_max` 0,12 nas árvores), sem amassar. A direção é convertida pro espaço de cada tufo, então todos deitam pro mesmo lado. Sem `Wind` na cena (`wind_direction` = 0) fica como antes.

### Ajuste: balanço do outside + direção na tela

- **Balanço** (vento fraco, sem rajada) é o mesmo do outside em toda cena: direção do material no espaço de cada tufo (cada um balança pra um lado — é o que deixa a grama viva). Só a **dobra** da rajada usa a direção global fixa. No estado calmo o balanço não diminui mais (`sway` 1,0).
- **Direção fixa é na TELA** (noroeste → sudeste), então o vetor no mundo depende do giro da câmera: campo/área de teste (yaw 40,5°) usam `(1, 0.3)`; o **outside** (yaw 0, pitch 30°) usa `(0.39, 0.92)` nos riscos de vento e na sombra das nuvens (a inclinação da câmera também conta: com pitch baixo o movimento em Z aparece achatado na tela). Cena nova: converter pelo yaw e pitch da câmera dela.

## Checklist: noite BotW (vale também pra cena só de noite, como o outside)

Cena sem ciclo usa os mesmos elementos da noite do campo, travados na noite:

- [ ] Luz e ambiente = `KEYS_BOTW` fase 1 (luar `(0.62, 0.71, 1.0)` × 1,0 a −37°, ambiente `(0.42, 0.48, 0.72)` × 0,65, sombra 0,4 e suavidade 1,0, névoa `(0.106, 0.137, 0.251)` 0,006 / altura 0,3, glow 0,2, saturação 1,45, contraste 0,92).
- [ ] `BotwPost` com `fixed_phase` 1 (cor fria da noite, sem translucidez da grama, borda da vegetação baixa).
- [ ] **Vagalumes do campo**: verdes `(0.55, 1, 0.25)` com **aura** (segundo passe, halo aditivo de 0,55 m), 40.
- [ ] Poeira da noite (`NightDust`).
- [ ] **Vento** (`Wind` com `fixed_phase` 1): noite calma (sem ventania, rajadas raras), riscos na metade e azulados, poeira levada pelo vento, direção na tela noroeste → sudeste.
- [ ] Vegetação: checklist de [17-vegetacao.md](17-vegetacao.md).

Outside conferido com esta lista.

## Névoa (estilo BotW: nunca chapada)

Três camadas, cada uma com um papel:

1. **Névoa de distância** (toda cena, sempre): `fog_mode` = profundidade. Começa **depois do jogador** (a câmera fica a ~18 m dele) e esconde a borda do mapa e o cenário longe. Pelas chaves `fog_max` / `fog_begin` / `fog_end` do `KEYS_BOTW`: dia 0,45 / 34 / 80 m (quase invisível, só "lava" o fundo), tarde 0,55–0,6 / 28–30 / 60–68 m, noite 0,7 / **16 / 36 m** (bem perto: à noite a névoa chega quase no personagem), cor `(0.2, 0.26, 0.4)` (um pouco mais clara que a cena, pra névoa se ler como névoa). Cor = `fog` da hora. **Sem névoa por altura** (`fog_height_density` 0: era o que deixava chapada) e **sem placas de névoa** (o `EdgeFog` do outside saiu).
2. **Névoa volumétrica** (só à noite): `volumetric_fog_enabled` com densidade global 0 — só os bolsões têm névoa; luz da lua e das lanternas atravessa. Desliga de dia (pesa).
3. **Bolsões** (`scripts/weather/fog_pockets.gd`, filhos `FogVolume` elipsoides com ruído 3D na densidade): baixos (1,6 m de altura, nunca cobrem o personagem), densidade 0 de dia → 1,0 à noite, `albedo` branco e **brilho próprio** (`emission` `(0.3, 0.36, 0.5)`): sem o brilho a névoa volumétrica só bloqueia a luz e vira uma mancha escura (testado renderizando a cena). Resultado: névoa azul-clara sutil.
   - **Névoa visível (VFX):** cada bolsão também solta nuvens de névoa em sprite (`assets/textures/effects/mist/mist_puff.png`, gerada por `tools/gen_mist_texture.py`): 12 por bolsão, 6 × 3 m, azul-clara com alfa 0,6, viradas pra câmera, somem suave onde encostam no chão (`proximity_fade`), se arrastam com o vento e aparecem/somem com a noite. É o que deixa a névoa **visível** com a câmera de cima; a volumétrica sozinha fica fraca. Conferido renderizando o outside, vão e voltam devagar na direção do vento.
   - **Outside, borda do mapa (`FogPocketsEdge`):** névoa **forte em volta do cenário todo**: 16 bolsões (4 por lado, 9 × 2,6 × 5 m) logo dentro da `MapBounds` (±16 m), densidade 1,2, sprites com alfa 0,85, 10 por bolsão, 7 × 3,5 m, espalhados em altura (`mist_height` 1 m = camadas, dá volume). Mistura de volumétrica + PNG.
   - **Outside:** nas **laterais e atrás da casa, nunca na frente** (`FogPockets` com o mesmo giro da casa; frente = +Z local, onde fica a porta).
   - **Campo:** 6 bolsões nas bordas e clareiras, longe do spawn.
   - **Interiores:** sem névoa.

Regras: névoa não cobre o personagem nem caminho/pontos de interação; a noite continua legível.

### Sombra sem quadriculado

A sombra suave (PCSS) com poucas amostras fazia quadradinhos no personagem ao passar por baixo de uma sombra. `project.godot`: `soft_shadow_filter_quality` = 4 (direcional e posicional) e sol/lua com suavidade menor (`shadow_soft` 0,6–0,8 no `KEYS_BOTW`; `SoftShadows.sun_angular_distance` 0,6 no outside).

## Vento no recomeço (field)

Trazido do field do projeto antigo, com os mesmos valores:

- **`Wind`** (`scripts/weather/wind.gd`, igual ao antigo): direção fixa `(1, -0.02)` no mundo, que na câmera do jogo (yaw 40,5°) passa **de cima-esquerda pra baixo-direita** da tela (mesma `wind_dir` nos riscos, folhas e materiais da grama); estados CALMO / BRISA / VENTANIA sorteados (20–50 s cada, troca lenta de 12 s); força com ruído lento e rajadas nos picos. Escreve os globais `wind_direction`, `wind_strength`, `wind_gust`, que a grama usa (`shaders/nature/grass_body.gdshaderinc`: balanço, dobra nas rajadas com limite de ~35°).
- **Mais suave que o antigo**: força e velocidade dos 3 estados reduzidas (ventania: dobra 0,45 em vez de 0,75, balanço 1,15 em vez de 1,5, velocidade dos riscos/folhas 1,15 em vez de 1,8), troca entre estados em 18 s, e o balanço da grama mais lento (`sway_speed` 1,6; raminho 1,4).
- **Onda de luz na grama** (`shimmer_*` no `grass_tuft.tres`; referência: prints do vídeo de grama com vento): onda larga (22 m) que acende **manchas** da grama em **lugares aleatórios** (cada passada sorteia outro desenho), em ordem na direção do vento, não uma faixa contínua; que atravessa o campo na direção do vento a 18 m/s, com a frente bem torta (nunca uma linha reta), acendendo **manchas irregulares** de grama num amarelo claro quase branco (`shimmer_color` (1, 0,93, 0,66)), mais nas pontas; uma a cada 160 m (`shimmer_spacing`), ou seja, passa rápido (aparece por menos tempo) e espera uns 9 s. `shimmer_strength` 0,6 (0 desliga).
- **`GroundFog`** (`scripts/weather/ground_fog.gd` + `shaders/weather/ground_fog.gdshader`, fog shader): **névoa rasteira (ground fog / low-lying fog) no cenário todo**, branca por enquanto. Um FogVolume caixa de 120 × 0,9 × 120 m que segue o jogador (a névoa volumétrica só é calculada até `volumetric_fog_length` 40 m da câmera). No shader:
  - **Altura**: densa colada no chão, some até `fog_height` **0,35 m no máximo** (bem baixa) (curva exponencial, corte suave no topo).
  - **Volume em gomos**: duas camadas do mesmo NoiseTexture3D 64³ seamless (Perlin FBM 4 oitavas, só o canal vermelho é lido), uma grande (14 m, bancos de névoa) e uma de detalhe (4,5 m, fiapos), com contraste (`noise_low` 0,22 → vazio, cobre quase o campo todo, `noise_high` 0,7 → cheio). Quanto mais alto, mais forte o ruído precisa ser: o topo fica em gomos.
  - A névoa é **parada** (`wind_speed` 0). O ruído é preso ao **mundo** (não anda junto com o jogador; só a caixa se move). Laterais da caixa somem suave (6 m).
  - Brilho próprio leve (`emission_amount` 0,25) pra não escurecer o verde.
  - **Futuro**: deixar clareiras (parecer nuvens) com uma máscara 2D subtraindo `DENSITY`.
  - Substituiu as manchas de poeira (`fog_patches.gd`, apagado). Pesquisa: docs do Godot "Volumetric fog" e "Fog shaders".
- **`WindTrails`** e **`WindTrailsLong`** (`scripts/weather/wind_streaks.gd` + `shaders/weather/wind_streak_particles.gdshader`): riscos curtos (rastro 1 s) e longos (1,5 s, velocidade 0,8–1,05: no máximo uns 8 m), velocidade 5 (0,8–1,25), **espessura variada** (`width` 0,07 × 0,3–1,3), cor branco-esverdeada com **opacidade sorteada por risco entre 0,3 e 0,7** (`alpha_range`; sem shaded). Nascem finos com fade in; no fim **encolhem junto com o fade out** e o nado para (sem tremer). Nado de tubarão: vai e volta pros lados num seno (`swim_amp` 0,7 m/s, `swim_freq` 0,6/s). Altura 2,2–3,4 m (acima do personagem), em 22 × 22 m em volta do jogador; somem perto da câmera (4–9 m). Quantidade por estado (`streaks` no `wind.gd`): calmo 0,03, brisa 0,14, ventania 0,45.
- **`WindLeaves`** (`scripts/weather/wind_leaves.gd`, `shaders/weather/wind_leaf.gdshader`): **só folhas** voando (12 por tipo de folha, tamanho 0,5–1,0 × 25 cm, nunca grandes; a lâmina de grama reta foi tirada, `blade_count` 0), na velocidade do vento. Vão descendo enquanto voam (`gravity` −0,45), pousam no chão (caixa de colisão de partícula que segue o jogador), ficam um tempo e somem devagar (vida 9 s). Folhas: sprites Shaded do Kenney Foliage (`leaf_drop` = 0081, `leaf_maple` = 0086, `leaf_lobed` = 0084, em `assets/textures/effects/leaves/`); cada folha tem **uma** de 4 cores (`leaf_colors`: verde claro da grama, verde do pé da grama, verde amarelado e branco, combinando com os raminhos), opacidade 0,9 (`leaf_alpha`), um emissor por folha × cor (cor certa pelo `tint`, sem depender da cor da partícula); o lado cinza do sprite fica mais escuro (55%, `shade_dark`: o efeito Shaded do Kenney, como na grama). No ar a folha ondula de leve (`flutter` 0,08, `curl` 0,12); pousada no chão fica parada e reta, e nunca entra embaixo da terra. O shader usa a mesma luz suave da grama (a luz toon antiga foi arquivada).
- Sem `WeatherCycle` ainda: o vento roda como dia, sem chuva.

## Referência: shader do vento (código como estava)

Os arquivos `shaders/includes/wind.gdshaderinc`, `shaders/includes/wind_sway_body.gdshaderinc` e `shaders/nature/wind_sway.gdshader` foram apagados no recomeço do projeto. O código fica aqui pra refazer do mesmo jeito. Atenção: o `wind_sway_body` incluía o `toon_light.gdshaderinc` (de terceiros, apagado); ao refazer, trocar essa luz pela do estilo novo.

### `includes/wind.gdshaderinc`

```glsl
// Balanço de vento compartilhado (mesma fórmula do wind_sway.gdshader).
// Balança os vértices mais altos (a base fica parada), com fase pela posição
// da planta no mundo pra cada uma ficar fora de sincronia.

uniform float sway_strength = 0.05;
uniform float sway_speed = 1.5;
uniform float sway_start = 0.0;
uniform float sway_height = 0.4;
uniform vec2 wind_dir = vec2(1.0, 0.3);

vec3 wind_offset(vec3 vertex, vec3 world_origin, float time) {
	float phase = time * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	vec2 wd = normalize(wind_dir);
	float s = 0.35 + 0.5 * sin(phase) + 0.25 * sin(phase * 0.37 + 1.3);
	float side = 0.35 * cos(phase);
	float w = smoothstep(sway_start, sway_start + sway_height, vertex.y);
	vec2 d = (wd * s + vec2(-wd.y, wd.x) * side) * sway_strength * w;
	return vec3(d.x, 0.0, d.y);
}
```

### `includes/wind_sway_body.gdshaderinc`

```glsl
// Corpo do shader de vento (wind_sway), compartilhado entre a versão normal
// e a das árvores (wind_sway_tree, que não recebe sombra).
#include "res://shaders/includes/toon_light.gdshaderinc"
// Vento: balança os vértices mais altos do mesh (a base fica parada).
// Usado na grama/flores/folhagem e nas árvores, substituindo o material do
// glTF (por isso recebe a mesma textura atlas do pack em albedo_tex).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.5;

uniform float sway_strength = 0.05;  // deslocamento máximo (unidades locais)
uniform float sway_speed = 1.5;
uniform float sway_start = 0.0;      // altura local onde começa a balançar
uniform float sway_height = 0.4;     // quanto acima de sway_start atinge força total
uniform vec2 wind_dir = vec2(1.0, 0.3);
// quanto o balanço faz um oval (0 = só vai e vem)
uniform float orbit = 0.35;

// Toque do jogador: a planta achata (e inclina só um pouco pra longe dele).
// `player_pos` é global (project.godot), atualizado pelo player.gd. push_strength 0 = não reage (árvores).
global uniform vec3 player_pos;
// Vento global (scripts/weather/wind.gd, "Vento (sistema)" em 05-clima.md):
//  - wind_direction: direção fixa no mundo; (0,0) = cena sem Wind (usa wind_dir
//    do material, como antes);
//  - wind_strength: multiplica o balanço normal;
//  - wind_gust / wind_gust_slow: quanto a planta DOBRA na direção do vento
//    (grama / árvores). A lâmina gira em volta da base mantendo
//    o comprimento (não amassa).
global uniform vec2 wind_direction;
global uniform float wind_strength;
global uniform float wind_gust;
global uniform float wind_gust_slow;
uniform float bend_max = 1.1;       // ângulo máximo da dobra (rad) na grama
uniform float tree_bend_max = 0.12; // nas árvores (sway_start > 0,5)
uniform float bend_scale = 1.0;      // por tipo (arbusto dobra pouco: wind_applier.bush_bend)
// Translucidez contra o sol (estilo BotW): com o sol atrás da planta, a ponta
// acende amarela. Global, 0 = desligado (só o campo liga; plano 16-estilo-botw.md).
global uniform float veg_backlight;
// Multiplica a borda clara (rim) da vegetação. 1 = normal; o campo baixa
// (à noite a borda azul fazia as árvores brilharem ao balançar).
global uniform float veg_rim_scale;
global uniform vec3 veg_backlight_color;
uniform float push_strength = 0.0;  // quanto se inclina pra longe (metros)
uniform float push_radius = 0.9;    // alcance do toque (metros)
uniform float push_squash = 0.5;    // fração da altura que achata
// Balanço ao tocar (arbusto): sacode quando o jogador ENTRA ou SAI (borda do
// alcance), sem deformar; parado dentro, fica no tamanho original. 0 = desligado.
uniform float touch_shake = 0.0;
uniform float touch_radius = 0.9;

// rim light "vinil" (mesmo efeito do rim_overlay, embutido aqui porque o
// overlay não acompanharia o balanço do vento)
uniform vec4 rim_color : source_color = vec4(0.62, 0.7, 1.0, 1.0);
uniform float rim_power = 3.0;
uniform float rim_strength = 0.35;

// Bioluminescência (flores): pétalas brilham na própria cor, pulsando devagar.
// O caule/folha (pixels onde o verde domina) não brilha. 0 = desligado.
uniform float bio_glow = 0.0;
uniform float bio_pulse_speed = 0.8;
varying float v_phase;

// Grama estilizada (baseado em "Stylized Grass" de StayAtHomeDev, MIT, ver
// stylized_grass_LICENSE.txt): troca a textura por um degradê base → ponta e
// manchas de ruído no mundo. Ligado só na grama densa (GrassField). 0 = textura.
uniform bool stylized = false;
// oclusão na base da grama: o pé do tufo fica escuro e clareia até a ponta
// (sombra "de contato" entre as lâminas). 0 = sem.
uniform float base_ao : hint_range(0.0, 1.0) = 0.0;
uniform vec3 grass_base_color : source_color = vec3(0.35, 0.62, 0.22);
uniform vec3 grass_tip_color : source_color = vec3(0.86, 0.98, 0.5);
uniform sampler2D grass_noise : repeat_enable, filter_linear;
uniform float grass_noise_scale = 20.0;  // metros por repetição das manchas
uniform float grass_height = 0.35;       // altura local onde fica a cor da ponta
varying float v_height;
varying vec3 v_world;

void vertex() {
	// fase pela posição no mundo: cada planta balança um pouco fora de sincronia
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * sway_speed + dot(world_origin.xz, vec2(0.35, 0.21));
	v_phase = dot(world_origin.xz, vec2(1.7, 2.3));
	v_height = VERTEX.y;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// balanço suave: inclina com o vento e faz um oval (nunca para de vez nas
	// pontas, sem aquele "acelera e freia"), com uma rajada lenta por cima
	bool global_wind = length(wind_direction) > 0.5;
	// balanço: igual ao do outside (direção do material no espaço da planta,
	// então cada tufo balança pra um lado: é o que deixa a grama viva parada)
	vec2 wd = normalize(wind_dir);
	float s = 0.35 + 0.5 * sin(phase) + 0.25 * sin(phase * 0.37 + 1.3);
	float side = orbit * cos(phase);
	float w = smoothstep(sway_start, sway_start + sway_height, VERTEX.y);
	VERTEX.xz += (wd * s + vec2(-wd.y, wd.x) * side) * sway_strength * w * wind_strength;
	if (global_wind) {
		// dobra: gira em volta da base, a ponta faz arco (comprimento igual)
		bool is_tree = sway_start > 0.5;
		float amount = (is_tree ? wind_gust_slow * tree_bend_max : wind_gust * bend_max) * bend_scale;
		// cada planta tem sua "rigidez" (umas deitam muito, outras pouco) e
		// um ruído lento próprio, pra não deitarem todas na mesma altura
		float h1 = fract(sin(dot(world_origin.xz, vec2(12.9898, 78.233))) * 43758.5453);
		float stiff = mix(0.3, 1.15, h1 * h1);
		float wobble = 0.75 + 0.25 * sin(TIME * (0.7 + h1) + v_phase);
		float a = amount * stiff * wobble * w;
		float rel = max(VERTEX.y - sway_start, 0.0);
		// dobra na direção fixa do vento: mundo -> espaço local da planta
		vec3 l = inverse(mat3(MODEL_MATRIX)) * vec3(wind_direction.x, 0.0, wind_direction.y);
		vec2 bd = length(l.xz) > 0.0001 ? normalize(l.xz) : normalize(wind_direction);
		VERTEX.xz += bd * sin(a) * rel;
		VERTEX.y += (cos(a) - 1.0) * rel;
	}

	if (touch_shake > 0.0) {
		float dd = length(world_origin.xz - player_pos.xz);
		float edge = smoothstep(touch_radius * 0.45, touch_radius * 0.8, dd) * (1.0 - smoothstep(touch_radius * 0.9, touch_radius * 1.3, dd));
		vec3 shake = vec3(sin(TIME * 17.0 + v_phase), 0.0, cos(TIME * 13.0 + v_phase)) * touch_shake * edge * w;
		VERTEX += inverse(mat3(MODEL_MATRIX)) * shake;
	}
	// toque: calculado pela origem da planta, então ela toda se abre junta
	vec2 away = world_origin.xz - player_pos.xz;
	float dist = length(away);
	float p = (1.0 - smoothstep(push_radius * 0.3, push_radius, dist)) * step(0.001, push_strength);
	if (p > 0.0) {
		vec2 dir = dist > 0.001 ? away / dist : vec2(1.0, 0.0);
		vec3 push = vec3(0.0);
		push.xz = dir * push_strength * p * w;
		push.y = -push_squash * p * w * max(VERTEX.y, 0.0);
		VERTEX += inverse(mat3(MODEL_MATRIX)) * push;  // mundo -> local
	}
}

void fragment() {
	vec3 albedo = texture(albedo_tex, UV).rgb;
	if (stylized) {
		float h = clamp(v_height / grass_height, 0.0, 1.0);
		float n = texture(grass_noise, v_world.xz / grass_noise_scale).r;
		albedo = mix(grass_base_color, grass_tip_color, h) * mix(grass_base_color, grass_tip_color, n);
	}
	if (base_ao > 0.0) {
		float h_ao = clamp(v_height / grass_height, 0.0, 1.0);
		albedo *= mix(1.0 - base_ao, 1.0, smoothstep(0.0, 0.7, h_ao));
	}
	ALBEDO = albedo;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength * veg_rim_scale;
	if (bio_glow > 0.0) {
		float petal = 1.0 - smoothstep(0.0, 0.08, albedo.g - max(albedo.r, albedo.b));
		float pulse = 0.65 + 0.35 * sin(TIME * bio_pulse_speed + v_phase);
		EMISSION += albedo * bio_glow * petal * pulse;
	}
}

// Luz: comum (Lambert) ou toon, pelo global `toon_enabled` (ver toon_light.gdshaderinc).
void light() {
	bool is_main = LIGHT_IS_DIRECTIONAL;
	DIFFUSE_LIGHT += toon_diffuse(NORMAL, LIGHT, ATTENUATION, LIGHT_COLOR, is_main);
	if (is_main && veg_backlight > 0.0) {
		float back = smoothstep(-0.3, 1.0, dot(VIEW, -LIGHT));  // câmera de cima: vale também de lado
		float tip = stylized ? smoothstep(0.2, 1.0, v_height / grass_height) : 0.6;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * veg_backlight_color * back * tip * veg_backlight * ATTENUATION;
	}
	// sem a borda clara do toon aqui: a grama é fina e vista de lado, então a
	// borda pegava quase o tufo todo e a grama ficava branca
}
```

### `nature/wind_sway.gdshader`

```glsl
shader_type spatial;
// Vento: grama, flores, folhagem e arbustos. O código está em
// includes/wind_sway_body.gdshaderinc (o mesmo das árvores).
#include "res://shaders/includes/wind_sway_body.gdshaderinc"
```


## Ideias do Wind VFX da Vefects (`Downloads/Vefects_Wind_VFX_Godot_v1.0.3`, licença: grátis pra usar no jogo)

O pacote não usa rastro de partícula: cada "corrente de vento" é uma **fita curva grande** (malha) com uma textura de risco que **corre e se desfaz** (erosão) por cima, distorcida por ruído. Some de lado (fresnel), perto do chão/objetos (depth fade) e perto da câmera (camera depth fade). Junto vêm poeira (dust specks) e detritos (folhas, pétalas, lâminas).

- **Aplicado**: o sumiço perto da câmera nos nossos riscos.
- **Próximos passos possíveis**: (1) fita curva com risco que corre e se desfaz no lugar do rastro (vento mais "desenhado", menos linha); (2) poeira fininha só na ventania; (3) som de vento em loop (o pacote tem 6 sons) com volume pelo estado.
