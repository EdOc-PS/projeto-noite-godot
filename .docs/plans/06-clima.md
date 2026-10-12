# Dia, noite e clima

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Visual: [10-pos-processamento.md](10-pos-processamento.md)

## Ciclo de dia e noite

**Onde está implementado:** só na cidade (`scenes/city/city.tscn`), no nó `DayNightCycle` (`scripts/environment/day_night_cycle.gd`).

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

### Regra visual: dia vivo (referência: Link's Awakening)

O jogo tem cara de **brinquedo de vinil/plástico** (Link's Awakening do Switch). De dia, isso é: verde vivo, cores de brinquedo limpas, luz quente e clara **sem brilho estourado e sem puxar pra azul**.

- **Nada de azulado de dia.** Ambiente e névoa de dia são neutros/quentes, não azuis.
- **Pouco brilho:** glow quase desligado de dia (0,2) e só volta forte à noite (0,7), onde as lanternas precisam dele.
- **Névoa é coisa da noite.** Dia e tarde têm névoa **zero** (`fog_density` e `fog_height_density` = 0). Ela vai surgindo só no anoitecer (70–90%) e chega no valor da noite (0,008 / 0,45). A névoa existe pra dar vida à noite.
- Saturação global: dia 1,2, tarde 1,3, noite 1,15 (a LUT do `ColorGrade` complementa; ver [11-estilo-visual.md](11-estilo-visual.md)). A tarde é a **hora dourada**: luz quente e forte, ambiente âmbar, contraste 1,15. Viva, mas sem laranja estourado.
- Ambiente vem pouco do céu de dia (`ambient_light_sky_contribution` 0,25), pra o céu pálido não lavar a cena. À noite volta pra 1,0.

### Efeitos de cena na cidade

A cidade segue [10-pos-processamento.md](10-pos-processamento.md) igual ao outside: AgX, SSAO (power 1,3, light affect 0,3), glow em todos os níveis, névoa por altura, tilt-shift, **sombra de contato** (`ContactShadows`, em carros, bancos, hidrantes e postes), **sombra das nuvens** (`CloudShadows`, a cor muda com a hora) e **riscos de vento** (`WindStreaks`).

### Skyboxes

Ficam em `assets/skyboxes/`:

- **Dia:** `basic/skybox-day.png`
- **Tarde (laranja):** `basic/skybox-morning.png`
- **Noite:** `space/skybox-space-nebula.png`

O céu usa o shader `shaders/day_night_sky.gdshader`, que mistura os três panoramas pelos pesos `dusk_weight` e `night_weight`. O `Sky` está em `process_mode` tempo real pra luz ambiente acompanhar a mudança.

**Importante:** o `Environment` precisa de `fog_sky_affect = 0`. Senão a névoa pinta o céu inteiro com a cor dela e a skybox some (vira só azul-marinho).

### Postes da cidade

Os postes da cidade **não usam a luz das lanternas do calm_place** (`lantern_pulse.gd`, chama a fogo tremulando). Na cidade é poste elétrico: `scripts/environment/street_lamp.gd`, luz fixa branco-quente, grupo `street_lamps`, acende/apaga pela `intensity` do ciclo.

### Como ajustar

- Duração: `cycle_duration` no nó `DayNightCycle`.
- Começar em outra hora (pra testar): `start_phase` (0 = dia, 1 = noite).
- Cores e tempos de cada fase: tabela `KEYS` no topo do script.

## Clima

_A definir._ Tipos de clima (chuva, neblina, vento forte...), como e quando trocam.

## Efeito no jogo

_A definir._ Como hora e clima afetam jogador, inimigos, NPCs e visual.
