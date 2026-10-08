# Plano 05 — Câmera

Referência: [PROJETO-NOITE.md](../PROJETO-NOITE.md) · Referência de jogo: **Death's Door** (Acid Nerve, 2021) · Interações: [04-interacoes.md](04-interacoes.md)

Objetivo: definir como a câmera se comporta no jogo inteiro: padrão no gameplay, variação por área e **planos de cena** (close no rosto em conversas e momentos especiais), no estilo do Death's Door.

## Princípios

- **Fixa no gameplay**: o jogador nunca gira a câmera. "Cima" no controle é sempre "cima" na tela.
- **Ortogonal**: visual de maquete/diorama (combina com o tilt-shift).
- **Jogador centralizado** no gameplay; a câmera segue com suavidade (sem tremer em movimentos bruscos).
- **Cada lugar escolhe o melhor enquadramento**: lugar aberto → mais de cima; lugar fechado → mais baixo, mostrando paredes e fachadas.
- **Fora do gameplay, a câmera é livre**: em conversas e momentos de história ela pode aproximar, mudar de ângulo e de lado, como um diretor de cinema. Ao terminar, volta suave pro gameplay.
- **Nunca corte seco** no gameplay: toda mudança é uma transição suave (0,5–1 s). Corte seco só dentro de cena (ex.: alternar entre close do jogador e do NPC).

## Ângulos (inclinação)

Medidos em prints do Death's Door: sala dos corvos ~45° (de frente), vila/loja ~50° (girada ~38°).

| Lugar | Inclinação | Giro | Zoom | Por quê |
|---|---|---|---|---|
| **Padrão** | 60° | 0° | normal | Meio-termo entre isométrica e top-down |
| **Área aberta** (Calm Place, praças) | **70°** ✅ no Calm Place | 0° | um pouco aberto | O chão é o destaque: flores, sombra das nuvens, caminhos |
| **Fachadas e entradas** (porta da casa, lojas) | 50–55° | 0° | um pouco fechado | Mostra a frente do prédio e a porta |
| **Interiores e salas** | ~50° | 0° | fechado | Ar de palco, como a sala dos corvos |
| **Combate (dungeon)** | 65° | 0° | travado na sala | Ler ataques e inimigos no chão |
| **Cena / conversa** | livre | livre | close | Ver abaixo |

Evitar: top-down puro (90°: casa vira telhado, personagem vira cabeça) e giro no gameplay.

## 1. Câmera de gameplay — ✅ base feita

`scripts/camera/isometric_camera.gd` no `CameraRig`:

- Segue o jogador (`follow_speed`), centralizado na altura `pivot_height`.
- `pitch_degrees`: inclinação (70° no Calm Place).
- Zoom ortogonal abre perto de um foco (`focus_path`, hoje a casa): `size_near_player` 6 → `size_near_focus` 10.

## 2. Zonas de câmera — a fazer

Como o Death's Door faz por área: uma **`CameraZone`** (`Area3D`) muda o enquadramento quando o jogador entra.

- Parâmetros: `pitch`, `size` (zoom), `mode` (`FOLLOW` segue o jogador · `LOCKED` enquadramento fixo da sala · `BOUNDED` segue mas não passa das bordas da zona), `blend_time`, `priority` (zonas sobrepostas: vence a maior).
- Sem zona: volta pro padrão da cena.
- Substitui o zoom da casa de hoje: no Calm Place, zona aberta a 70° no gramado e zona da casa a 55° perto da porta.
- **Limites do mapa**: zona `BOUNDED` cobrindo o cenário inteiro, pra câmera não mostrar o "fora do mapa".

## 3. Planos de cena (conversa e momentos especiais) — a fazer

No Death's Door, quando um NPC fala ou algo importante acontece, a câmera **sai do gameplay**: aproxima bem, às vezes no rosto, muda de ângulo e até de lado, e alterna entre quem fala. Queremos o mesmo.

**Quando usar:**

| Momento | Plano |
|---|---|
| NPC começa a falar | Câmera aproxima e enquadra os dois (plano de conversa) |
| Fala com emoção / ênfase | **Close no rosto** de quem fala, de um ângulo mais baixo e de lado |
| Alternância de falas | Corte entre o close do jogador e o do NPC |
| Personagem reage (emote, susto, alegria) | Close rápido no personagem + emote |
| Chegada num lugar importante / revelação de chefe | Plano aberto que passeia pela cena e volta pro jogador |
| Fim da cena | Volta suave pro enquadramento de gameplay |

**Como montar (proposta):**

- **`CameraShot`**: um `Marker3D` posicionado à mão no cenário ou no NPC (ex.: `Npc/Shots/CloseUp`, `Npc/Shots/TwoShot`). Guarda posição, rotação (ângulo livre, inclusive giro) e `size` (zoom; close = `size` bem pequeno, ~1,5–2).
- **`CameraDirector`** (autoload): tira a câmera do modo gameplay e anda entre shots: `play_shot(shot, blend)`, `cut_to(shot)`, `return_to_gameplay(blend)`. Pausa o movimento do jogador durante a cena.
- **Close no rosto com ortogonal**: aproximar = diminuir o `size`. Se o close ficar "chapado", a cena pode trocar a câmera pra **perspectiva** com FOV fechado (~20–30°) só durante a conversa; volta pra ortogonal no fim (decidir testando).
- **Enquadramento**: regra dos terços; quem fala um pouco fora do centro, olhando pro lado aberto da tela. Fundo levemente desfocado (aumentar o tilt-shift durante a cena).
- O diálogo (plano 03, item 6) chama o `CameraDirector`: cada fala pode indicar o shot (`shot: "npc_close"`).

## Etapas

1. ✅ Câmera de gameplay com inclinação e zoom de foco.
2. ✅ Calm Place a 70°.
3. `CameraZone` + transição suave; trocar o zoom da casa por zonas.
4. Limites do mapa (`BOUNDED`).
5. `CameraDirector` + `CameraShot` (planos de cena), testado com um NPC de exemplo.
6. Integrar com o sistema de diálogo e emotes.
